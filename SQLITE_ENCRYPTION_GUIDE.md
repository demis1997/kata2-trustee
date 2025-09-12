# SQLite Database Encryption with Trustee Key Management

## 🔐 Overview

This guide shows how to integrate Trustee's key management with SQLite database encryption for your MPC signers. The encryption key is securely stored in Trustee KBS and retrieved using attestation.

## 🏗️ Architecture

```
┌─────────────────┐    Attestation    ┌─────────────────────┐
│   MPC Signer    │ ─────────────────►│  Trustee KBS        │
│  (SQLite DB)    │                   │  (Encryption Key)   │
└─────────────────┘                   └─────────┬───────────┘
                                                │
                                                ▼
┌─────────────────┐    Encrypted      ┌─────────────────────┐
│   SQLite DB     │ ◄─────────────────│  AES-256 Encryption │
│  (Sensitive)    │                   │  (GCM Mode)         │
└─────────────────┘                   └─────────────────────┘
```

## 🔑 Key Management

### 1. Encryption Key Storage
```bash
# Key stored in Trustee KBS
Path: keys/sqlite/encryption_key
Type: AES-256 (32 bytes)
Format: Base64 encoded
```

### 2. Key Retrieval Process
```bash
# 1. Signer requests attestation
./kbs-client --url http://localhost:8080 attest

# 2. KBS verifies attestation and returns key
./kbs-client get-resource --path "keys/sqlite/encryption_key"

# 3. Key used for database encryption/decryption
```

## 🗄️ Database Schema

### Encrypted Tables
```sql
-- MPC Parties Table
CREATE TABLE mpc_parties (
    id INTEGER PRIMARY KEY,
    party_id TEXT UNIQUE,
    public_key TEXT,                    -- Unencrypted
    encrypted_private_key BLOB,         -- Encrypted with Trustee key
    encrypted_share BLOB,               -- Encrypted with Trustee key
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Transactions Table
CREATE TABLE transactions (
    id INTEGER PRIMARY KEY,
    tx_hash TEXT UNIQUE,
    encrypted_data BLOB,                -- Encrypted transaction data
    status TEXT,                        -- Unencrypted
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Key Derivations Table
CREATE TABLE key_derivations (
    id INTEGER PRIMARY KEY,
    parent_key_id TEXT,
    encrypted_derived_key BLOB,         -- Encrypted derived key
    derivation_path TEXT,               -- Unencrypted
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## 🐍 Python Integration

### Basic Usage
```python
from sqlite_encryption import TrusteeSQLiteEncryption

# Initialize
db_enc = TrusteeSQLiteEncryption(
    kbs_url="http://localhost:8080",
    db_path="mpc_data.db"
)

# Create encrypted database
db_enc.create_encrypted_database()

# Store MPC party data
db_enc.store_mpc_party(
    party_id="party_0",
    public_key="04a1b2c3d4e5f6...",
    private_key="PRIVATE_KEY_DATA",
    share="MPC_SHARE_DATA"
)

# Retrieve and decrypt data
party_data = db_enc.get_mpc_party("party_0")
print(f"Private Key: {party_data['private_key']}")
```

### Advanced Features
```python
# Store encrypted transaction
transaction = {
    "amount": 1000000,
    "recipient": "0x742d35Cc6634C0532925a3b8D",
    "signers": ["party_0", "party_1", "party_2"]
}
db_enc.store_transaction("0xabc123...", transaction)

# Retrieve transaction
tx_data = db_enc.get_transaction("0xabc123...")
print(f"Amount: {tx_data['data']['amount']}")
```

## 🚀 Go Integration

### Basic Usage
```go
package main

import (
    "fmt"
    "log"
)

func main() {
    // Initialize encryption system
    dbEnc := NewTrusteeSQLiteEncryption("http://localhost:8080", "mpc_data.db")
    
    // Create encrypted database
    if err := dbEnc.CreateEncryptedDatabase(); err != nil {
        log.Fatal(err)
    }
    defer dbEnc.DB.Close()
    
    // Store MPC party data
    err := dbEnc.StoreMPCParty(
        "party_0",
        "04a1b2c3d4e5f6...",
        "PRIVATE_KEY_DATA",
        "MPC_SHARE_DATA",
    )
    if err != nil {
        log.Fatal(err)
    }
    
    // Retrieve data
    party, err := dbEnc.GetMPCParty("party_0")
    if err != nil {
        log.Fatal(err)
    }
    fmt.Printf("Retrieved party: %s\n", party.PartyID)
}
```

## 🔐 Security Features

### 1. Encryption at Rest
- **Algorithm**: AES-256-GCM
- **Key Source**: Trustee KBS (attestation-protected)
- **Nonce**: Random per encryption operation
- **Authentication**: Built-in GCM authentication

### 2. Access Control
- **Attestation Required**: Key retrieval requires valid attestation
- **Policy Enforcement**: Trustee policies control access
- **Hardware Protection**: Intel TDX/SGX in production

### 3. Key Management
- **Centralized**: Single key managed by Trustee
- **Rotatable**: Key can be rotated via Trustee
- **Auditable**: All key access logged

## 🛠️ Integration with MPC Signers

### 1. Signer Initialization
```go
func (s *Signer) Initialize() error {
    // Get encryption key from Trustee
    dbEnc := NewTrusteeSQLiteEncryption(s.kbsURL, s.dbPath)
    if err := dbEnc.CreateEncryptedDatabase(); err != nil {
        return err
    }
    s.dbEnc = dbEnc
    return nil
}
```

### 2. Storing MPC Shares
```go
func (s *Signer) StoreShare(share []byte) error {
    return s.dbEnc.StoreMPCParty(
        s.partyID,
        s.publicKey,
        s.privateKey,
        string(share),
    )
}
```

### 3. Retrieving Shares
```go
func (s *Signer) GetShare() ([]byte, error) {
    party, err := s.dbEnc.GetMPCParty(s.partyID)
    if err != nil {
        return nil, err
    }
    return []byte(party.Share), nil
}
```

## 📋 Deployment Checklist

### Development
- [ ] Trustee KBS running
- [ ] Encryption key registered
- [ ] Python/Go dependencies installed
- [ ] Database schema created
- [ ] Basic encryption/decryption working

### Production
- [ ] Intel TDX/SGX hardware available
- [ ] Trustee configured for hardware attestation
- [ ] HTTPS enabled for KBS communication
- [ ] Key rotation policy implemented
- [ ] Backup and recovery procedures
- [ ] Monitoring and alerting setup

## 🔧 Troubleshooting

### Common Issues
1. **Key Retrieval Fails**: Check attestation and KBS connectivity
2. **Decryption Errors**: Verify key hasn't changed in Trustee
3. **Database Locked**: Ensure proper connection management
4. **Performance Issues**: Consider connection pooling

### Debug Commands
```bash
# Check Trustee KBS status
docker ps | grep trustee

# Test key retrieval
./kbs-client get-resource --path "keys/sqlite/encryption_key"

# Verify database
sqlite3 mpc_data.db ".tables"
```

## 🎯 Benefits

1. **Security**: Hardware-backed key protection
2. **Compliance**: Meets regulatory requirements
3. **Scalability**: Centralized key management
4. **Auditability**: Complete access logging
5. **Flexibility**: Easy key rotation and policy changes

This integration provides enterprise-grade security for your MPC signer databases while maintaining the flexibility and performance of SQLite.
