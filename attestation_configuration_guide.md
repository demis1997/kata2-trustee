# Attestation Configuration Guide

## Overview
This guide provides comprehensive examples for configuring attestation with different TEE types, focusing on the specific parameters you mentioned: `instance_identity`, `configuration`, `executables`, `file_system`, `hardware`, `runtime_opaque`, `storage_opaque`, `sourced_data`, and TDX-specific parameters like `mrconfigid`, `mrowner`, `mrownerconfig`.

## 1. Resource Configuration

### High-Security Resources (Intel TDX)
```bash
# Create TDX-specific resources
kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/high_security/mpc_coordinator_tdx" \
  --resource-file coordinator_tdx_key.pem

kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/high_security/mpc_signer_tdx" \
  --resource-file signer_tdx_key.pem

# Create measurement-specific resources
kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/tdx_config_specific/mpc_signer" \
  --resource-file tdx_config_signer.pem

kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/tdx_owner_specific/mpc_coordinator" \
  --resource-file tdx_owner_coordinator.pem

kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/tdx_owner_config_specific/mpc_signer" \
  --resource-file tdx_owner_config_signer.pem
```

### Medium-Security Resources (Intel SGX)
```bash
# Create SGX-specific resources
kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/medium_security/mpc_signer_sgx" \
  --resource-file signer_sgx_key.pem

kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/medium_security/mpc_coordinator_sgx" \
  --resource-file coordinator_sgx_key.pem
```

### Development Resources (Sample)
```bash
# Create development resources
kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/development/mpc_coordinator_dev" \
  --resource-file dev_coordinator_key.pem

kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/development/mpc_signer_dev" \
  --resource-file dev_signer_key.pem
```

### Multi-TEE Resources
```bash
# Create multi-TEE resources
kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/multi_tee/mpc_config" \
  --resource-file multi_tee_config.json

kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/multi_tee/mpc_shared_key" \
  --resource-file shared_key.pem
```

## 2. Policy Configuration

### TDX High-Security Policy
```bash
# Apply TDX high-security policy
kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --path "policy/high_security_tdx" \
  --policy-file tdx_high_security_policy.rego
```

### SGX Medium-Security Policy
```bash
# Apply SGX medium-security policy
kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --path "policy/medium_security_sgx" \
  --policy-file sgx_medium_security_policy.rego
```

### Sample Development Policy
```bash
# Apply sample development policy
kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --path "policy/development_sample" \
  --policy-file sample_development_policy.rego
```

### Multi-TEE Policy
```bash
# Apply multi-TEE policy
kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --path "policy/multi_tee" \
  --policy-file multi_tee_policy.rego
```

## 3. Reference Values Configuration

### Intel TDX Reference Values
```bash
# Register TDX reference values
kbs-client config --auth-private-key kbs_private.key set-reference-value \
  --path "reference_values/intel_tdx" \
  --reference-value-file tdx_reference_values.json
```

### Intel SGX Reference Values
```bash
# Register SGX reference values
kbs-client config --auth-private-key kbs_private.key set-reference-value \
  --path "reference_values/intel_sgx" \
  --reference-value-file sgx_reference_values.json
```

### AMD SEV-SNP Reference Values
```bash
# Register SEV-SNP reference values
kbs-client config --auth-private-key kbs_private.key set-reference-value \
  --path "reference_values/amd_sev_snp" \
  --reference-value-file sev_snp_reference_values.json
```

### ARM CCA Reference Values
```bash
# Register ARM CCA reference values
kbs-client config --auth-private-key kbs_private.key set-reference-value \
  --path "reference_values/arm_cca" \
  --reference-value-file arm_cca_reference_values.json
```

## 4. Trustworthiness Vector Configuration

### TDX Trustworthiness Thresholds
```json
{
  "trustworthiness_thresholds": {
    "hardware": 95,
    "configuration": 90,
    "executables": 90,
    "file_system": 85,
    "runtime_opaque": 80,
    "storage_opaque": 80,
    "sourced_data": 75
  }
}
```

### SGX Trustworthiness Thresholds
```json
{
  "trustworthiness_thresholds": {
    "hardware": 85,
    "configuration": 80,
    "executables": 80,
    "file_system": 75,
    "runtime_opaque": 70,
    "storage_opaque": 70,
    "sourced_data": 65
  }
}
```

## 5. TDX-Specific Parameters

### MRCONFIG_ID Configuration
```bash
# Resource that requires specific MRCONFIG_ID
kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/tdx_config_specific/mpc_signer" \
  --resource-file tdx_config_signer.pem

# Policy that validates MRCONFIG_ID
kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --path "policy/tdx_config_specific" \
  --policy-file tdx_config_specific_policy.rego
```

### MROWNER Configuration
```bash
# Resource that requires specific MROWNER
kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/tdx_owner_specific/mpc_coordinator" \
  --resource-file tdx_owner_coordinator.pem

# Policy that validates MROWNER
kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --path "policy/tdx_owner_specific" \
  --policy-file tdx_owner_specific_policy.rego
```

### MROWNER_CONFIG Configuration
```bash
# Resource that requires specific MROWNER_CONFIG
kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/tdx_owner_config_specific/mpc_signer" \
  --resource-file tdx_owner_config_signer.pem

# Policy that validates MROWNER_CONFIG
kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --path "policy/tdx_owner_config_specific" \
  --policy-file tdx_owner_config_specific_policy.rego
```

## 6. Complete Setup Script

```bash
#!/bin/bash
# Complete attestation configuration setup

echo "=== Setting up Attestation Configuration ==="

# 1. Create resource directories
mkdir -p keys/{high_security,medium_security,development,tdx_config_specific,tdx_owner_specific,tdx_owner_config_specific,multi_tee}
mkdir -p policy
mkdir -p reference_values

# 2. Generate keys
echo "Generating keys..."
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out coordinator_tdx_key.pem
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out signer_tdx_key.pem
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out signer_sgx_key.pem
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out dev_coordinator_key.pem

# 3. Register resources
echo "Registering resources..."
kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/high_security/mpc_coordinator_tdx" \
  --resource-file coordinator_tdx_key.pem

kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/high_security/mpc_signer_tdx" \
  --resource-file signer_tdx_key.pem

kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/medium_security/mpc_signer_sgx" \
  --resource-file signer_sgx_key.pem

kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/development/mpc_coordinator_dev" \
  --resource-file dev_coordinator_key.pem

# 4. Apply policies
echo "Applying policies..."
kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --path "policy/high_security_tdx" \
  --policy-file tdx_high_security_policy.rego

kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --path "policy/medium_security_sgx" \
  --policy-file sgx_medium_security_policy.rego

kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --path "policy/development_sample" \
  --policy-file sample_development_policy.rego

# 5. Register reference values
echo "Registering reference values..."
kbs-client config --auth-private-key kbs_private.key set-reference-value \
  --path "reference_values/intel_tdx" \
  --reference-value-file reference_values_examples.json

echo "=== Attestation Configuration Complete ==="
```

## 7. Testing the Configuration

### Test TDX Resources
```bash
# Test TDX high-security resource access
kbs-client get-resource --path "keys/high_security/mpc_coordinator_tdx"

# Test TDX config-specific resource access
kbs-client get-resource --path "keys/tdx_config_specific/mpc_signer"

# Test TDX owner-specific resource access
kbs-client get-resource --path "keys/tdx_owner_specific/mpc_coordinator"

# Test TDX owner-config-specific resource access
kbs-client get-resource --path "keys/tdx_owner_config_specific/mpc_signer"
```

### Test SGX Resources
```bash
# Test SGX medium-security resource access
kbs-client get-resource --path "keys/medium_security/mpc_signer_sgx"
```

### Test Development Resources
```bash
# Test development resource access
kbs-client get-resource --path "keys/development/mpc_coordinator_dev"
```

### Test Multi-TEE Resources
```bash
# Test multi-TEE resource access
kbs-client get-resource --path "keys/multi_tee/mpc_config"
```

## 8. Monitoring and Debugging

### Check Resource Status
```bash
# List all resources
kbs-client list-resources

# Check specific resource
kbs-client get-resource --path "keys/high_security/mpc_coordinator_tdx"
```

### Check Policy Status
```bash
# List all policies
kbs-client list-policies

# Check specific policy
kbs-client get-policy --path "policy/high_security_tdx"
```

### Check Reference Values
```bash
# List all reference values
kbs-client list-reference-values

# Check specific reference values
kbs-client get-reference-value --path "reference_values/intel_tdx"
```

## 9. Production Deployment

### Azure Intel TDX Configuration
```bash
# Configure for Azure Intel TDX
kbs-client config --auth-private-key kbs_private.key set-config \
  --config-file kbs-config-intel-tdx.toml

# Apply TDX-specific policies
kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --path "policy/azure_tdx_production" \
  --policy-file azure_tdx_production_policy.rego
```

### Azure Intel SGX Configuration
```bash
# Configure for Azure Intel SGX
kbs-client config --auth-private-key kbs_private.key set-config \
  --config-file kbs-config-intel-sgx.toml

# Apply SGX-specific policies
kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --path "policy/azure_sgx_production" \
  --policy-file azure_sgx_production_policy.rego
```

This configuration provides a complete attestation system that supports multiple TEE types with specific measurement validation and trustworthiness thresholds.
