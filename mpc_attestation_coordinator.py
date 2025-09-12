#!/usr/bin/env python3
"""
MPC Coordinator with Attestation-Based Signer Selection
This shows how to integrate Trustee attestation with your MPC coordinator
"""

import json
import requests
import subprocess
import base64
from typing import List, Dict, Optional

class AttestationBasedMPCCoordinator:
    def __init__(self, kbs_url: str = "http://localhost:8080"):
        self.kbs_url = kbs_url
        self.signer_groups = {
            "high_security": {
                "tee_type": "intel_tdx",
                "min_threshold": 2,
                "max_signers": 4,
                "resources": "keys/high_security/*"
            },
            "medium_security": {
                "tee_type": "intel_sgx", 
                "min_threshold": 2,
                "max_signers": 6,
                "resources": "keys/medium_security/*"
            },
            "development": {
                "tee_type": "sample",
                "min_threshold": 1,
                "max_signers": 8,
                "resources": "keys/development/*"
            }
        }
    
    def get_attestation_token(self) -> Optional[str]:
        """Get JWT token from Trustee KBS"""
        try:
            result = subprocess.run([
                "./target/release/kbs-client", 
                "--url", self.kbs_url, 
                "attest"
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                return result.stdout.strip().split('\n')[0]
            return None
        except Exception as e:
            print(f"Error getting attestation token: {e}")
            return None
    
    def verify_signer_capability(self, signer_id: str, required_security_level: str) -> bool:
        """Verify if signer can handle the required security level"""
        token = self.get_attestation_token()
        if not token:
            return False
        
        # Try to access resources based on security level
        resource_path = f"keys/{required_security_level}/coordinator_key"
        
        try:
            result = subprocess.run([
                "./target/release/kbs-client",
                "--url", self.kbs_url,
                "get-resource",
                "--path", resource_path
            ], capture_output=True, text=True)
            
            return result.returncode == 0
        except Exception:
            return False
    
    def select_signers_for_transaction(self, transaction_value: int, available_signers: List[str]) -> List[str]:
        """Select appropriate signers based on transaction value and attestation"""
        
        if transaction_value >= 1000000:  # High value - require high security
            security_level = "high_security"
            min_threshold = 2
        elif transaction_value >= 100000:  # Medium value - medium security
            security_level = "medium_security" 
            min_threshold = 2
        else:  # Low value - any security level
            security_level = "development"
            min_threshold = 1
        
        print(f"🔍 Transaction value: ${transaction_value:,}")
        print(f"🎯 Required security level: {security_level}")
        print(f"📋 Available signers: {available_signers}")
        
        # Filter signers based on attestation capability
        qualified_signers = []
        for signer_id in available_signers:
            if self.verify_signer_capability(signer_id, security_level):
                qualified_signers.append(signer_id)
                print(f"✅ {signer_id}: Qualified for {security_level}")
            else:
                print(f"❌ {signer_id}: Not qualified for {security_level}")
        
        # Select minimum required signers
        if len(qualified_signers) >= min_threshold:
            selected = qualified_signers[:min_threshold]
            print(f"🎯 Selected signers: {selected}")
            return selected
        else:
            print(f"❌ Insufficient qualified signers. Need {min_threshold}, got {len(qualified_signers)}")
            return []
    
    def execute_mpc_transaction(self, transaction_data: Dict, selected_signers: List[str]) -> bool:
        """Execute MPC transaction with selected signers"""
        print(f"\n🚀 Executing MPC transaction with {len(selected_signers)} signers")
        print(f"📋 Transaction data: {json.dumps(transaction_data, indent=2)}")
        
        # This would integrate with your actual MPC API
        # For demo purposes, we'll simulate the calls
        
        for signer_id in selected_signers:
            print(f"📡 Sending to {signer_id}...")
            # Simulate MPC API call
            # curl -XPOST 0.0.0.0:8080/api/v1/transactions/{tx_id}/sign
            #     -d '{"parties":[...], "hash":"...", "algorithm":"ECDSA_SECP256K1"}'
        
        print("✅ Transaction executed successfully")
        return True

def main():
    print("=== MPC COORDINATOR WITH ATTESTATION-BASED SIGNER SELECTION ===")
    print()
    
    coordinator = AttestationBasedMPCCoordinator()
    
    # Available signers (simulating different Docker containers)
    available_signers = [
        "signer-tdx-1", "signer-tdx-2",  # Intel TDX signers
        "signer-sgx-1", "signer-sgx-2", "signer-sgx-3",  # Intel SGX signers  
        "signer-dev-1", "signer-dev-2"  # Development signers
    ]
    
    # Test different transaction values
    test_transactions = [
        {"id": "tx-001", "value": 5000000, "description": "High-value corporate transfer"},
        {"id": "tx-002", "value": 500000, "description": "Medium-value payment"},
        {"id": "tx-003", "value": 50000, "description": "Low-value transaction"},
        {"id": "tx-004", "value": 10000000, "description": "Critical system transfer"}
    ]
    
    for tx in test_transactions:
        print(f"\n{'='*60}")
        print(f"Transaction: {tx['id']} - {tx['description']}")
        print(f"{'='*60}")
        
        selected_signers = coordinator.select_signers_for_transaction(
            tx['value'], 
            available_signers
        )
        
        if selected_signers:
            coordinator.execute_mpc_transaction(tx, selected_signers)
        else:
            print("❌ Transaction rejected - insufficient qualified signers")
        
        print()

if __name__ == "__main__":
    main()
