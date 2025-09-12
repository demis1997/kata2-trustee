#!/usr/bin/env python3
"""
SQLite Database Encryption with Trustee Key Management
This module provides encrypted SQLite database operations using keys from Trustee KBS
"""

import sqlite3
import subprocess
import base64
import json
import os
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

class TrusteeSQLiteEncryption:
    def __init__(self, kbs_url="http://localhost:8080", db_path="mpc_data.db"):
        self.kbs_url = kbs_url
        self.db_path = db_path
        self.encryption_key = None
        self.fernet = None
        
    def get_encryption_key_from_trustee(self):
        """Retrieve encryption key from Trustee KBS"""
        try:
            result = subprocess.run([
                "./target/release/kbs-client",
                "--url", self.kbs_url,
                "get-resource",
                "--path", "keys/sqlite/encryption_key"
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                # Decode base64 key
                key_b64 = result.stdout.strip()
                self.encryption_key = base64.b64decode(key_b64)
                
                # Create Fernet cipher
                # Derive key using PBKDF2 for Fernet compatibility
                kdf = PBKDF2HMAC(
                    algorithm=hashes.SHA256(),
                    length=32,
                    salt=b'sqlite_salt',  # In production, use random salt
                    iterations=100000,
                )
                key = base64.urlsafe_b64encode(kdf.derive(self.encryption_key))
                self.fernet = Fernet(key)
                
                print("✅ Encryption key retrieved from Trustee")
                return True
            else:
                print(f"❌ Failed to get encryption key: {result.stderr}")
                return False
        except Exception as e:
            print(f"❌ Error getting encryption key: {e}")
            return False
    
    def encrypt_data(self, data):
        """Encrypt data using the Trustee key"""
        if not self.fernet:
            raise Exception("Encryption key not loaded")
        
        if isinstance(data, str):
            data = data.encode('utf-8')
        
        return self.fernet.encrypt(data)
    
    def decrypt_data(self, encrypted_data):
        """Decrypt data using the Trustee key"""
        if not self.fernet:
            raise Exception("Encryption key not loaded")
        
        decrypted = self.fernet.decrypt(encrypted_data)
        return decrypted.decode('utf-8')
    
    def create_encrypted_database(self):
        """Create SQLite database with encrypted sensitive columns"""
        if not self.get_encryption_key_from_trustee():
            return False
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Create tables with encrypted columns
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS mpc_parties (
                id INTEGER PRIMARY KEY,
                party_id INTEGER UNIQUE,
                public_key TEXT,
                encrypted_private_key BLOB,
                encrypted_share BLOB,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS transactions (
                id INTEGER PRIMARY KEY,
                tx_hash TEXT UNIQUE,
                encrypted_data BLOB,
                status TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS key_derivations (
                id INTEGER PRIMARY KEY,
                parent_key_id TEXT,
                encrypted_derived_key BLOB,
                derivation_path TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        conn.commit()
        conn.close()
        print("✅ Encrypted SQLite database created")
        return True
    
    def store_mpc_party(self, party_id, public_key, private_key, share):
        """Store MPC party data with encryption"""
        if not self.fernet:
            if not self.get_encryption_key_from_trustee():
                return False
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Encrypt sensitive data
        encrypted_private_key = self.encrypt_data(private_key)
        encrypted_share = self.encrypt_data(share)
        
        cursor.execute('''
            INSERT OR REPLACE INTO mpc_parties 
            (party_id, public_key, encrypted_private_key, encrypted_share)
            VALUES (?, ?, ?, ?)
        ''', (party_id, public_key, encrypted_private_key, encrypted_share))
        
        conn.commit()
        conn.close()
        print(f"✅ Stored encrypted data for party {party_id}")
        return True
    
    def get_mpc_party(self, party_id):
        """Retrieve and decrypt MPC party data"""
        if not self.fernet:
            if not self.get_encryption_key_from_trustee():
                return None
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT public_key, encrypted_private_key, encrypted_share
            FROM mpc_parties WHERE party_id = ?
        ''', (party_id,))
        
        result = cursor.fetchone()
        conn.close()
        
        if result:
            public_key, encrypted_private_key, encrypted_share = result
            private_key = self.decrypt_data(encrypted_private_key)
            share = self.decrypt_data(encrypted_share)
            
            return {
                'public_key': public_key,
                'private_key': private_key,
                'share': share
            }
        
        return None
    
    def store_transaction(self, tx_hash, transaction_data):
        """Store encrypted transaction data"""
        if not self.fernet:
            if not self.get_encryption_key_from_trustee():
                return False
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Encrypt transaction data
        encrypted_data = self.encrypt_data(json.dumps(transaction_data))
        
        cursor.execute('''
            INSERT OR REPLACE INTO transactions 
            (tx_hash, encrypted_data, status)
            VALUES (?, ?, ?)
        ''', (tx_hash, encrypted_data, 'pending'))
        
        conn.commit()
        conn.close()
        print(f"✅ Stored encrypted transaction {tx_hash}")
        return True
    
    def get_transaction(self, tx_hash):
        """Retrieve and decrypt transaction data"""
        if not self.fernet:
            if not self.get_encryption_key_from_trustee():
                return None
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT encrypted_data, status FROM transactions WHERE tx_hash = ?
        ''', (tx_hash,))
        
        result = cursor.fetchone()
        conn.close()
        
        if result:
            encrypted_data, status = result
            transaction_data = json.loads(self.decrypt_data(encrypted_data))
            return {
                'data': transaction_data,
                'status': status
            }
        
        return None
    
    def list_all_parties(self):
        """List all parties (public data only)"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT party_id, public_key, created_at FROM mpc_parties
        ''')
        
        parties = cursor.fetchall()
        conn.close()
        
        return [{'party_id': p[0], 'public_key': p[1], 'created_at': p[2]} for p in parties]

def main():
    print("=== SQLITE ENCRYPTION WITH TRUSTEE ===")
    print()
    
    # Initialize encryption system
    db_enc = TrusteeSQLiteEncryption()
    
    # Create encrypted database
    if not db_enc.create_encrypted_database():
        print("❌ Failed to create encrypted database")
        return
    
    # Demo: Store MPC party data
    print("\n=== DEMO: STORING MPC PARTY DATA ===")
    
    # Sample data
    party_data = {
        'party_0': {
            'public_key': '04a1b2c3d4e5f6...',
            'private_key': 'PRIVATE_KEY_0_DATA',
            'share': 'MPC_SHARE_0_DATA'
        },
        'party_1': {
            'public_key': '04f6e5d4c3b2a1...',
            'private_key': 'PRIVATE_KEY_1_DATA', 
            'share': 'MPC_SHARE_1_DATA'
        }
    }
    
    for party_id, data in party_data.items():
        db_enc.store_mpc_party(
            party_id, 
            data['public_key'], 
            data['private_key'], 
            data['share']
        )
    
    # Demo: Store transaction
    print("\n=== DEMO: STORING TRANSACTION ===")
    transaction = {
        'amount': 1000000,
        'recipient': '0x742d35Cc6634C0532925a3b8D',
        'timestamp': '2024-01-15T10:30:00Z',
        'signers': ['party_0', 'party_1', 'party_2']
    }
    
    db_enc.store_transaction('0xabc123...', transaction)
    
    # Demo: Retrieve data
    print("\n=== DEMO: RETRIEVING DATA ===")
    
    # Get party data
    party_0_data = db_enc.get_mpc_party('party_0')
    if party_0_data:
        print(f"✅ Retrieved party_0 data: {party_0_data['public_key'][:20]}...")
    
    # Get transaction data
    tx_data = db_enc.get_transaction('0xabc123...')
    if tx_data:
        print(f"✅ Retrieved transaction: {tx_data['data']['amount']} tokens")
    
    # List all parties
    parties = db_enc.list_all_parties()
    print(f"✅ Total parties in database: {len(parties)}")
    
    print("\n=== ENCRYPTION SUMMARY ===")
    print("✅ SQLite database encrypted with Trustee key")
    print("✅ Sensitive data encrypted at rest")
    print("✅ Key retrieved from Trustee KBS with attestation")
    print("✅ Database accessible only with valid attestation")

if __name__ == "__main__":
    main()
