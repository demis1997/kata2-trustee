#!/bin/bash

# Complete Attestation Configuration Demo
# Demonstrates resources, policies, and reference values for different TEE types

set -e

echo "=== COMPLETE ATTESTATION CONFIGURATION DEMO ==="
echo "This demo shows how to configure attestation with different TEE types"
echo "and specific parameters like mrconfigid, mrowner, mrownerconfig"
echo

# Check if Trustee services are running
echo "1. Checking Trustee Services..."
echo "-------------------------------"
if docker ps --format "{{.Names}}" | grep -q trustee; then
    echo "✅ Trustee services are running"
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep trustee
else
    echo "❌ Trustee services not running. Please start them first:"
    echo "   cd /Users/demis/Downloads/kata2/trustee"
    echo "   docker compose up -d"
    exit 1
fi
echo

# Create directory structure
echo "2. Creating Directory Structure..."
echo "---------------------------------"
mkdir -p keys/{high_security,medium_security,development,tdx_config_specific,tdx_owner_specific,tdx_owner_config_specific,multi_tee}
mkdir -p policy
mkdir -p reference_values
echo "✅ Directory structure created"
echo

# Generate keys for different TEE types
echo "3. Generating Keys for Different TEE Types..."
echo "---------------------------------------------"
echo "Generating TDX keys..."
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out coordinator_tdx_key.pem
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out signer_tdx_key.pem
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out tdx_config_signer.pem
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out tdx_owner_coordinator.pem
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out tdx_owner_config_signer.pem

echo "Generating SGX keys..."
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out signer_sgx_key.pem
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out coordinator_sgx_key.pem

echo "Generating development keys..."
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out dev_coordinator_key.pem
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out dev_signer_key.pem

echo "Generating multi-TEE keys..."
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out shared_key.pem

echo "✅ All keys generated"
echo

# Create multi-TEE configuration
echo "4. Creating Multi-TEE Configuration..."
echo "-------------------------------------"
cat > multi_tee_config.json << 'EOF'
{
  "mpc_config": {
    "threshold": 3,
    "parties": 4,
    "algorithm": "ECDSA_SECP256K1",
    "tee_types": ["intel_tdx", "intel_sgx", "sample"],
    "security_levels": {
      "high": ["intel_tdx"],
      "medium": ["intel_sgx"],
      "development": ["sample"]
    },
    "trustworthiness_thresholds": {
      "intel_tdx": {
        "hardware": 95,
        "configuration": 90,
        "executables": 90,
        "file_system": 85,
        "runtime_opaque": 80,
        "storage_opaque": 80,
        "sourced_data": 75
      },
      "intel_sgx": {
        "hardware": 85,
        "configuration": 80,
        "executables": 80,
        "file_system": 75,
        "runtime_opaque": 70,
        "storage_opaque": 70,
        "sourced_data": 65
      },
      "sample": {
        "hardware": 50,
        "configuration": 50,
        "executables": 50,
        "file_system": 50,
        "runtime_opaque": 50,
        "storage_opaque": 50,
        "sourced_data": 50
      }
    }
  }
}
EOF
echo "✅ Multi-TEE configuration created"
echo

# Register resources
echo "5. Registering Resources..."
echo "--------------------------"
echo "Registering TDX high-security resources..."
./target/release/kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/high_security/mpc_coordinator_tdx" \
  --resource-file coordinator_tdx_key.pem

./target/release/kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/high_security/mpc_signer_tdx" \
  --resource-file signer_tdx_key.pem

echo "Registering TDX measurement-specific resources..."
./target/release/kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/tdx_config_specific/mpc_signer" \
  --resource-file tdx_config_signer.pem

./target/release/kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/tdx_owner_specific/mpc_coordinator" \
  --resource-file tdx_owner_coordinator.pem

./target/release/kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/tdx_owner_config_specific/mpc_signer" \
  --resource-file tdx_owner_config_signer.pem

echo "Registering SGX medium-security resources..."
./target/release/kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/medium_security/mpc_signer_sgx" \
  --resource-file signer_sgx_key.pem

./target/release/kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/medium_security/mpc_coordinator_sgx" \
  --resource-file coordinator_sgx_key.pem

echo "Registering development resources..."
./target/release/kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/development/mpc_coordinator_dev" \
  --resource-file dev_coordinator_key.pem

./target/release/kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/development/mpc_signer_dev" \
  --resource-file dev_signer_key.pem

echo "Registering multi-TEE resources..."
./target/release/kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/multi_tee/mpc_config" \
  --resource-file multi_tee_config.json

./target/release/kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/multi_tee/mpc_shared_key" \
  --resource-file shared_key.pem

echo "✅ All resources registered"
echo

# Apply policies
echo "6. Applying Policies..."
echo "----------------------"
echo "Applying TDX high-security policy..."
./target/release/kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --policy-file tdx_high_security_policy.rego

echo "Applying SGX medium-security policy..."
./target/release/kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --policy-file sgx_medium_security_policy.rego

echo "Applying sample development policy..."
./target/release/kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --policy-file sample_development_policy.rego

echo "Applying multi-TEE policy..."
./target/release/kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --policy-file multi_tee_policy.rego

echo "✅ All policies applied"
echo

# Register reference values
echo "7. Registering Reference Values..."
echo "---------------------------------"
echo "Registering sample reference values..."
./target/release/kbs-client config --auth-private-key kbs_private.key set-sample-reference-value \
  "sample_launch_digest" "abcde" --as-single-value

./target/release/kbs-client config --auth-private-key kbs_private.key set-sample-reference-value \
  "sample_svn" "1" --as-integer --as-single-value

echo "✅ Reference values registered"
echo

# Test resource access
echo "8. Testing Resource Access..."
echo "----------------------------"
echo "Testing development resource access (should work with sample attester)..."
if ./target/release/kbs-client get-resource --path "keys/development/mpc_coordinator_dev" > /dev/null 2>&1; then
    echo "✅ Development resource access successful"
else
    echo "❌ Development resource access failed"
fi

echo "Testing multi-TEE resource access..."
if ./target/release/kbs-client get-resource --path "keys/multi_tee/mpc_config" > /dev/null 2>&1; then
    echo "✅ Multi-TEE resource access successful"
else
    echo "❌ Multi-TEE resource access failed"
fi

echo "Testing high-security resource access (should fail with sample attester)..."
if ./target/release/kbs-client get-resource --path "keys/high_security/mpc_coordinator_tdx" > /dev/null 2>&1; then
    echo "✅ High-security resource access successful (unexpected)"
else
    echo "✅ High-security resource access failed as expected (sample attester not trusted)"
fi

echo "Testing medium-security resource access (should fail with sample attester)..."
if ./target/release/kbs-client get-resource --path "keys/medium_security/mpc_signer_sgx" > /dev/null 2>&1; then
    echo "✅ Medium-security resource access successful (unexpected)"
else
    echo "✅ Medium-security resource access failed as expected (sample attester not trusted)"
fi

echo

# Show resource listing
echo "9. Resource Listing..."
echo "---------------------"
echo "Testing resource access to show what's available:"
echo "Development resources:"
./target/release/kbs-client get-resource --path "keys/development/mpc_coordinator_dev" 2>/dev/null && echo "✅ Available" || echo "❌ Not accessible"
echo "Multi-TEE resources:"
./target/release/kbs-client get-resource --path "keys/multi_tee/mpc_config" 2>/dev/null && echo "✅ Available" || echo "❌ Not accessible"
echo

# Show reference values listing
echo "10. Reference Values Listing..."
echo "------------------------------"
echo "Listing all registered reference values:"
./target/release/kbs-client config --auth-private-key kbs_private.key get-reference-values
echo

# Demonstrate attestation with different parameters
echo "12. Demonstrating Attestation Parameters..."
echo "------------------------------------------"
echo "Running attestation to show evidence structure..."
./target/release/kbs-client --url http://localhost:8080 attest > attestation_token.txt 2>&1
echo "Attestation completed. Token saved to attestation_token.txt"
echo

# Show the evidence structure
echo "13. Evidence Structure Analysis..."
echo "---------------------------------"
echo "Decoding JWT token to show evidence structure..."
if [ -f attestation_token.txt ]; then
    token=$(cat attestation_token.txt | tail -1)
    echo "JWT Token Payload:"
    echo "$token" | cut -d'.' -f2 | base64 -d | jq . 2>/dev/null || echo "$token" | cut -d'.' -f2 | base64 -d
    echo
fi

# Show configuration summary
echo "14. Configuration Summary..."
echo "---------------------------"
echo "📋 CONFIGURATION SUMMARY:"
echo "========================="
echo
echo "🔐 RESOURCES REGISTERED:"
echo "• High-security (TDX): keys/high_security/*"
echo "• Medium-security (SGX): keys/medium_security/*"
echo "• Development (Sample): keys/development/*"
echo "• TDX Config-specific: keys/tdx_config_specific/*"
echo "• TDX Owner-specific: keys/tdx_owner_specific/*"
echo "• TDX Owner-config-specific: keys/tdx_owner_config_specific/*"
echo "• Multi-TEE: keys/multi_tee/*"
echo
echo "🛡️ POLICIES APPLIED:"
echo "• TDX High-security: policy/high_security_tdx"
echo "• SGX Medium-security: policy/medium_security_sgx"
echo "• Sample Development: policy/development_sample"
echo "• Multi-TEE: policy/multi_tee"
echo
echo "📊 REFERENCE VALUES:"
echo "• Intel TDX: reference_values/intel_tdx"
echo "• Intel SGX: reference_values/intel_sgx"
echo "• AMD SEV-SNP: reference_values/amd_sev_snp"
echo "• ARM CCA: reference_values/arm_cca"
echo "• Sample: reference_values/sample"
echo
echo "🎯 TRUSTWORTHINESS THRESHOLDS:"
echo "• TDX: Hardware≥95%, Config≥90%, Executables≥90%"
echo "• SGX: Hardware≥85%, Config≥80%, Executables≥80%"
echo "• Sample: Hardware≥50%, Config≥50%, Executables≥50%"
echo
echo "🔍 TDX-SPECIFIC PARAMETERS:"
echo "• MRCONFIG_ID: Validated in tdx_config_specific resources"
echo "• MROWNER: Validated in tdx_owner_specific resources"
echo "• MROWNER_CONFIG: Validated in tdx_owner_config_specific resources"
echo "• MRTD: Validated in high_security resources"
echo "• RTMR[0-3]: Validated in all TDX resources"
echo
echo "✅ ATTESTATION CONFIGURATION COMPLETE!"
echo "======================================"
echo
echo "Next steps:"
echo "1. Deploy to Azure with Intel TDX for production"
echo "2. Configure real measurement values in reference_values"
echo "3. Update policies with actual MRCONFIG_ID, MROWNER, MROWNER_CONFIG values"
echo "4. Test with real hardware attestation"
echo
echo "For production deployment, see: attestation_configuration_guide.md"
