#!/bin/bash

echo "=== ATTESTATION-BASED SIGNER SELECTION DEMO ==="
echo "This demo shows how to select signers based on their attestation results"
echo

# Function to simulate different signer types
simulate_signer() {
    local signer_id=$1
    local tee_type=$2
    local group=$3
    
    echo "🔍 Testing Signer $signer_id (Group $group, TEE: $tee_type)"
    
    # Simulate attestation request
    echo "   Requesting attestation..."
    
    # Get JWT token from KBS
    local token=$(./target/release/kbs-client --url http://localhost:8080 attest 2>/dev/null | head -1)
    
    if [ -n "$token" ]; then
        echo "   ✅ Attestation successful"
        echo "   📋 JWT Token: ${token:0:50}..."
        
        # Try to access group-specific resources
        case $group in
            "A")
                echo "   🔐 Attempting to access high-security resources..."
                ./target/release/kbs-client --url http://localhost:8080 get-resource --path "keys/high_security/coordinator_key" >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    echo "   ✅ Access granted to high-security resources"
                    echo "   🎯 Signer $signer_id can participate in high-value transactions"
                else
                    echo "   ❌ Access denied to high-security resources"
                fi
                ;;
            "B")
                echo "   🔐 Attempting to access medium-security resources..."
                ./target/release/kbs-client --url http://localhost:8080 get-resource --path "keys/medium_security/coordinator_key" >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    echo "   ✅ Access granted to medium-security resources"
                    echo "   🎯 Signer $signer_id can participate in medium-value transactions"
                else
                    echo "   ❌ Access denied to medium-security resources"
                fi
                ;;
            "C")
                echo "   🔐 Attempting to access development resources..."
                ./target/release/kbs-client --url http://localhost:8080 get-resource --path "keys/development/coordinator_key" >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    echo "   ✅ Access granted to development resources"
                    echo "   🎯 Signer $signer_id can participate in development transactions"
                else
                    echo "   ❌ Access denied to development resources"
                fi
                ;;
        esac
    else
        echo "   ❌ Attestation failed"
    fi
    echo
}

# Demo different signer groups
echo "=== TESTING DIFFERENT SIGNER GROUPS ==="
echo

echo "1. High Security Signers (Intel TDX)"
echo "   - Required for: High-value transactions, critical operations"
echo "   - Attestation: Intel TDX hardware verification"
echo "   - Resources: keys/high_security/*"
echo
simulate_signer "A1" "intel_tdx" "A"
simulate_signer "A2" "intel_tdx" "A"

echo "2. Medium Security Signers (Intel SGX)"
echo "   - Required for: Medium-value transactions, standard operations"
echo "   - Attestation: Intel SGX hardware verification"
echo "   - Resources: keys/medium_security/*"
echo
simulate_signer "B1" "intel_sgx" "B"
simulate_signer "B2" "intel_sgx" "B"

echo "3. Development Signers (Sample)"
echo "   - Required for: Development, testing, low-value transactions"
echo "   - Attestation: Sample attestation (development only)"
echo "   - Resources: keys/development/*"
echo
simulate_signer "C1" "sample" "C"
simulate_signer "C2" "sample" "C"

echo "=== TRANSACTION ROUTING LOGIC ==="
echo
echo "Based on attestation results, the coordinator can now:"
echo "1. Route high-value transactions to Group A signers only"
echo "2. Route medium-value transactions to Group A or B signers"
echo "3. Route development transactions to any group"
echo "4. Ensure minimum threshold requirements per group"
echo
echo "This provides:"
echo "✅ Hardware-based security guarantees"
echo "✅ Automatic signer selection based on capabilities"
echo "✅ Policy enforcement at the hardware level"
echo "✅ Secure key distribution based on attestation"
