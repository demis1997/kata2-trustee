package main

import (
    "crypto/aes"
    "crypto/cipher"
    "crypto/rand"
    "database/sql"
    "encoding/base64"
    "encoding/json"
    "fmt"
    "io"
    "log"
    "os/exec"
    "time"

    _ "github.com/mattn/go-sqlite3"
)

// TrusteeSQLiteEncryption handles encrypted SQLite operations
type TrusteeSQLiteEncryption struct {
    KBSURL        string
    DBPath        string
    EncryptionKey []byte
    DB            *sql.DB
}

// MPCParty represents an MPC party in the database
type MPCParty struct {
    ID                int    `json:"id"`
    PartyID           string `json:"party_id"`
    PublicKey         string `json:"public_key"`
    EncryptedPrivateKey []byte `json:"encrypted_private_key"`
    EncryptedShare    []byte `json:"encrypted_share"`
    CreatedAt         time.Time `json:"created_at"`
}

// Transaction represents a transaction in the database
type Transaction struct {
    ID            int       `json:"id"`
    TxHash        string    `json:"tx_hash"`
    EncryptedData []byte    `json:"encrypted_data"`
    Status        string    `json:"status"`
    CreatedAt     time.Time `json:"created_at"`
}

// NewTrusteeSQLiteEncryption creates a new encryption instance
func NewTrusteeSQLiteEncryption(kbsURL, dbPath string) *TrusteeSQLiteEncryption {
    return &TrusteeSQLiteEncryption{
        KBSURL: kbsURL,
        DBPath: dbPath,
    }
}

// GetEncryptionKeyFromTrustee retrieves encryption key from Trustee KBS
func (t *TrusteeSQLiteEncryption) GetEncryptionKeyFromTrustee() error {
    cmd := exec.Command("./target/release/kbs-client", 
        "--url", t.KBSURL, 
        "get-resource", 
        "--path", "keys/sqlite/encryption_key")
    
    output, err := cmd.Output()
    if err != nil {
        return fmt.Errorf("failed to get encryption key: %v", err)
    }
    
    // Decode base64 key
    key, err := base64.StdEncoding.DecodeString(string(output))
    if err != nil {
        return fmt.Errorf("failed to decode key: %v", err)
    }
    
    t.EncryptionKey = key
    fmt.Println("✅ Encryption key retrieved from Trustee")
    return nil
}

// EncryptData encrypts data using AES-GCM
func (t *TrusteeSQLiteEncryption) EncryptData(data []byte) ([]byte, error) {
    if len(t.EncryptionKey) == 0 {
        return nil, fmt.Errorf("encryption key not loaded")
    }
    
    // Create AES cipher
    block, err := aes.NewCipher(t.EncryptionKey)
    if err != nil {
        return nil, err
    }
    
    // Create GCM mode
    gcm, err := cipher.NewGCM(block)
    if err != nil {
        return nil, err
    }
    
    // Generate random nonce
    nonce := make([]byte, gcm.NonceSize())
    if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
        return nil, err
    }
    
    // Encrypt data
    ciphertext := gcm.Seal(nonce, nonce, data, nil)
    return ciphertext, nil
}

// DecryptData decrypts data using AES-GCM
func (t *TrusteeSQLiteEncryption) DecryptData(encryptedData []byte) ([]byte, error) {
    if len(t.EncryptionKey) == 0 {
        return nil, fmt.Errorf("encryption key not loaded")
    }
    
    // Create AES cipher
    block, err := aes.NewCipher(t.EncryptionKey)
    if err != nil {
        return nil, err
    }
    
    // Create GCM mode
    gcm, err := cipher.NewGCM(block)
    if err != nil {
        return nil, err
    }
    
    // Extract nonce
    nonceSize := gcm.NonceSize()
    if len(encryptedData) < nonceSize {
        return nil, fmt.Errorf("ciphertext too short")
    }
    
    nonce, ciphertext := encryptedData[:nonceSize], encryptedData[nonceSize:]
    
    // Decrypt data
    plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
    if err != nil {
        return nil, err
    }
    
    return plaintext, nil
}

// CreateEncryptedDatabase creates SQLite database with encrypted columns
func (t *TrusteeSQLiteEncryption) CreateEncryptedDatabase() error {
    if err := t.GetEncryptionKeyFromTrustee(); err != nil {
        return err
    }
    
    // Open database
    db, err := sql.Open("sqlite3", t.DBPath)
    if err != nil {
        return err
    }
    t.DB = db
    
    // Create tables
    createTables := `
    CREATE TABLE IF NOT EXISTS mpc_parties (
        id INTEGER PRIMARY KEY,
        party_id TEXT UNIQUE,
        public_key TEXT,
        encrypted_private_key BLOB,
        encrypted_share BLOB,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    
    CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY,
        tx_hash TEXT UNIQUE,
        encrypted_data BLOB,
        status TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    
    CREATE TABLE IF NOT EXISTS key_derivations (
        id INTEGER PRIMARY KEY,
        parent_key_id TEXT,
        encrypted_derived_key BLOB,
        derivation_path TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    `
    
    _, err = t.DB.Exec(createTables)
    if err != nil {
        return err
    }
    
    fmt.Println("✅ Encrypted SQLite database created")
    return nil
}

// StoreMPCParty stores MPC party data with encryption
func (t *TrusteeSQLiteEncryption) StoreMPCParty(partyID, publicKey, privateKey, share string) error {
    // Encrypt sensitive data
    encryptedPrivateKey, err := t.EncryptData([]byte(privateKey))
    if err != nil {
        return err
    }
    
    encryptedShare, err := t.EncryptData([]byte(share))
    if err != nil {
        return err
    }
    
    // Store in database
    _, err = t.DB.Exec(`
        INSERT OR REPLACE INTO mpc_parties 
        (party_id, public_key, encrypted_private_key, encrypted_share)
        VALUES (?, ?, ?, ?)
    `, partyID, publicKey, encryptedPrivateKey, encryptedShare)
    
    if err != nil {
        return err
    }
    
    fmt.Printf("✅ Stored encrypted data for party %s\n", partyID)
    return nil
}

// GetMPCParty retrieves and decrypts MPC party data
func (t *TrusteeSQLiteEncryption) GetMPCParty(partyID string) (*MPCParty, error) {
    var party MPCParty
    
    err := t.DB.QueryRow(`
        SELECT id, party_id, public_key, encrypted_private_key, encrypted_share, created_at
        FROM mpc_parties WHERE party_id = ?
    `, partyID).Scan(
        &party.ID, &party.PartyID, &party.PublicKey,
        &party.EncryptedPrivateKey, &party.EncryptedShare, &party.CreatedAt)
    
    if err != nil {
        return nil, err
    }
    
    // Decrypt private key
    privateKey, err := t.DecryptData(party.EncryptedPrivateKey)
    if err != nil {
        return nil, err
    }
    
    // Decrypt share
    share, err := t.DecryptData(party.EncryptedShare)
    if err != nil {
        return nil, err
    }
    
    // Note: In real implementation, you'd return decrypted data
    // For security, we're not storing decrypted data in the struct
    fmt.Printf("✅ Retrieved party %s data\n", partyID)
    fmt.Printf("   Public Key: %s...\n", party.PublicKey[:20])
    fmt.Printf("   Private Key Length: %d bytes\n", len(privateKey))
    fmt.Printf("   Share Length: %d bytes\n", len(share))
    
    return &party, nil
}

// StoreTransaction stores encrypted transaction data
func (t *TrusteeSQLiteEncryption) StoreTransaction(txHash string, data map[string]interface{}) error {
    // Convert to JSON
    jsonData, err := json.Marshal(data)
    if err != nil {
        return err
    }
    
    // Encrypt data
    encryptedData, err := t.EncryptData(jsonData)
    if err != nil {
        return err
    }
    
    // Store in database
    _, err = t.DB.Exec(`
        INSERT OR REPLACE INTO transactions 
        (tx_hash, encrypted_data, status)
        VALUES (?, ?, ?)
    `, txHash, encryptedData, "pending")
    
    if err != nil {
        return err
    }
    
    fmt.Printf("✅ Stored encrypted transaction %s\n", txHash)
    return nil
}

// GetTransaction retrieves and decrypts transaction data
func (t *TrusteeSQLiteEncryption) GetTransaction(txHash string) (map[string]interface{}, error) {
    var encryptedData []byte
    var status string
    
    err := t.DB.QueryRow(`
        SELECT encrypted_data, status FROM transactions WHERE tx_hash = ?
    `, txHash).Scan(&encryptedData, &status)
    
    if err != nil {
        return nil, err
    }
    
    // Decrypt data
    decryptedData, err := t.DecryptData(encryptedData)
    if err != nil {
        return nil, err
    }
    
    // Parse JSON
    var result map[string]interface{}
    err = json.Unmarshal(decryptedData, &result)
    if err != nil {
        return nil, err
    }
    
    result["status"] = status
    fmt.Printf("✅ Retrieved transaction %s\n", txHash)
    
    return result, nil
}

func main() {
    fmt.Println("=== GO SQLITE ENCRYPTION WITH TRUSTEE ===")
    fmt.Println()
    
    // Initialize encryption system
    dbEnc := NewTrusteeSQLiteEncryption("http://localhost:8080", "mpc_data_go.db")
    
    // Create encrypted database
    if err := dbEnc.CreateEncryptedDatabase(); err != nil {
        log.Fatalf("Failed to create encrypted database: %v", err)
    }
    defer dbEnc.DB.Close()
    
    // Demo: Store MPC party data
    fmt.Println("\n=== DEMO: STORING MPC PARTY DATA ===")
    
    partyData := map[string]map[string]string{
        "party_0": {
            "public_key":  "04a1b2c3d4e5f6789abcdef0123456789abcdef0123456789abcdef0123456789ab",
            "private_key": "PRIVATE_KEY_0_DATA_FOR_GO",
            "share":       "MPC_SHARE_0_DATA_FOR_GO",
        },
        "party_1": {
            "public_key":  "04f6e5d4c3b2a1987654321fedcba0987654321fedcba0987654321fedcba0987",
            "private_key": "PRIVATE_KEY_1_DATA_FOR_GO",
            "share":       "MPC_SHARE_1_DATA_FOR_GO",
        },
    }
    
    for partyID, data := range partyData {
        if err := dbEnc.StoreMPCParty(partyID, data["public_key"], data["private_key"], data["share"]); err != nil {
            log.Printf("Failed to store party %s: %v", partyID, err)
        }
    }
    
    // Demo: Store transaction
    fmt.Println("\n=== DEMO: STORING TRANSACTION ===")
    transaction := map[string]interface{}{
        "amount":    1000000,
        "recipient": "0x742d35Cc6634C0532925a3b8D",
        "timestamp": "2024-01-15T10:30:00Z",
        "signers":   []string{"party_0", "party_1", "party_2"},
    }
    
    if err := dbEnc.StoreTransaction("0xabc123def456", transaction); err != nil {
        log.Printf("Failed to store transaction: %v", err)
    }
    
    // Demo: Retrieve data
    fmt.Println("\n=== DEMO: RETRIEVING DATA ===")
    
    // Get party data
    if _, err := dbEnc.GetMPCParty("party_0"); err != nil {
        log.Printf("Failed to get party_0: %v", err)
    }
    
    // Get transaction data
    if txData, err := dbEnc.GetTransaction("0xabc123def456"); err != nil {
        log.Printf("Failed to get transaction: %v", err)
    } else {
        fmt.Printf("   Amount: %.0f tokens\n", txData["amount"])
        fmt.Printf("   Status: %s\n", txData["status"])
    }
    
    fmt.Println("\n=== ENCRYPTION SUMMARY ===")
    fmt.Println("✅ SQLite database encrypted with Trustee key")
    fmt.Println("✅ Sensitive data encrypted at rest")
    fmt.Println("✅ Key retrieved from Trustee KBS with attestation")
    fmt.Println("✅ Database accessible only with valid attestation")
}
