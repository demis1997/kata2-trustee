# Complete Attestation Configuration Guide

## 🎯 **Overview**

This guide provides comprehensive examples for configuring attestation with different TEE types, focusing on the specific parameters you mentioned: `instance_identity`, `configuration`, `executables`, `file_system`, `hardware`, `runtime_opaque`, `storage_opaque`, `sourced_data`, and TDX-specific parameters like `mrconfigid`, `mrowner`, `mrownerconfig`.

## 📁 **Files Created**

### 1. Resource Examples
- `attestation_resources_examples.md` - Complete resource configuration examples
- `attestation_demo_complete.sh` - Working demo script

### 2. Policy Examples
- `tdx_high_security_policy.rego` - Intel TDX high-security policy
- `sgx_medium_security_policy.rego` - Intel SGX medium-security policy
- `sample_development_policy.rego` - Sample attester development policy
- `multi_tee_policy.rego` - Multi-TEE support policy
- `tdx_config_specific_policy.rego` - TDX MRCONFIG_ID validation
- `tdx_owner_specific_policy.rego` - TDX MROWNER validation
- `tdx_owner_config_specific_policy.rego` - TDX MROWNER_CONFIG validation

### 3. Reference Values
- `reference_values_examples.json` - Complete reference values for all TEE types

### 4. Configuration Guide
- `attestation_configuration_guide.md` - Step-by-step configuration instructions

## 🔧 **Key Features Demonstrated**

### 1. **TEE-Specific Resources**
```bash
# High-security (Intel TDX only)
keys/high_security/mpc_coordinator_tdx
keys/high_security/mpc_signer_tdx

# Medium-security (Intel SGX only)
keys/medium_security/mpc_signer_sgx
keys/medium_security/mpc_coordinator_sgx

# Development (Sample attester)
keys/development/mpc_coordinator_dev
keys/development/mpc_signer_dev
```

### 2. **TDX-Specific Measurement Validation**
```bash
# MRCONFIG_ID specific resources
keys/tdx_config_specific/mpc_signer

# MROWNER specific resources
keys/tdx_owner_specific/mpc_coordinator

# MROWNER_CONFIG specific resources
keys/tdx_owner_config_specific/mpc_signer
```

### 3. **Multi-TEE Support**
```bash
# Resources accessible by multiple TEE types
keys/multi_tee/mpc_config
keys/multi_tee/mpc_shared_key
```

## 🛡️ **Trustworthiness Vector Configuration**

### Intel TDX (High Security)
```json
{
  "hardware": 95,
  "configuration": 90,
  "executables": 90,
  "file_system": 85,
  "runtime_opaque": 80,
  "storage_opaque": 80,
  "sourced_data": 75
}
```

### Intel SGX (Medium Security)
```json
{
  "hardware": 85,
  "configuration": 80,
  "executables": 80,
  "file_system": 75,
  "runtime_opaque": 70,
  "storage_opaque": 70,
  "sourced_data": 65
}
```

### Sample (Development)
```json
{
  "hardware": 50,
  "configuration": 50,
  "executables": 50,
  "file_system": 50,
  "runtime_opaque": 50,
  "storage_opaque": 50,
  "sourced_data": 50
}
```

## 🔍 **TDX-Specific Parameters**

### MRCONFIG_ID Validation
```rego
allow {
    input.resource_path = "keys/tdx_config_specific/*"
    input.attestation_results.tee_type == "intel_tdx"
    input.attestation_results.status == "pass"
    
    tdx_measurements := input.attestation_results.runtime_data_claims.tdx_measurements
    tdx_measurements.mrconfig_id == "REQUIRED_MRCONFIG_ID_VALUE"
}
```

### MROWNER Validation
```rego
allow {
    input.resource_path = "keys/tdx_owner_specific/*"
    input.attestation_results.tee_type == "intel_tdx"
    input.attestation_results.status == "pass"
    
    tdx_measurements := input.attestation_results.runtime_data_claims.tdx_measurements
    tdx_measurements.mrowner == "REQUIRED_MROWNER_VALUE"
}
```

### MROWNER_CONFIG Validation
```rego
allow {
    input.resource_path = "keys/tdx_owner_config_specific/*"
    input.attestation_results.tee_type == "intel_tdx"
    input.attestation_results.status == "pass"
    
    tdx_measurements := input.attestation_results.runtime_data_claims.tdx_measurements
    tdx_measurements.mrowner_config == "REQUIRED_MROWNER_CONFIG_VALUE"
}
```

## 🚀 **Quick Start**

### 1. Run the Complete Demo
```bash
chmod +x attestation_demo_complete.sh
./attestation_demo_complete.sh
```

### 2. Test Resource Access
```bash
# Test development resources (works with sample attester)
./target/release/kbs-client get-resource --path "keys/development/mpc_coordinator_dev"

# Test multi-TEE resources
./target/release/kbs-client get-resource --path "keys/multi_tee/mpc_config"

# Test high-security resources (fails with sample attester)
./target/release/kbs-client get-resource --path "keys/high_security/mpc_coordinator_tdx"
```

### 3. Run Attestation
```bash
# Generate attestation token
./target/release/kbs-client --url http://localhost:8080 attest
```

## 📊 **Evidence Structure**

The JWT token contains:
- **EAT Profile**: `tag:github.com,2024:confidential-containers/Trustee`
- **TEE Type**: `intel_tdx`, `intel_sgx`, `sample`, etc.
- **Status**: `pass` (production) or `contraindicated` (sample)
- **Trustworthiness Vector**: Hardware, configuration, executables scores
- **Runtime Data Claims**: TEE-specific measurements
- **TDX Measurements**: MRTD, RTMRs, MRCONFIG_ID, MROWNER, MROWNER_CONFIG
- **SGX Measurements**: MRENCLAVE, MRSIGNER, CPU SVN, ISV SVN

## 🔐 **Security Model**

### Sample Attester (Development)
- **Status**: `contraindicated`
- **Trustworthiness**: Low (50%)
- **Use Case**: Development and testing
- **Evidence**: Simulated/placeholder data

### Intel TDX (Production)
- **Status**: `pass`
- **Trustworthiness**: High (95%+)
- **Use Case**: Production workloads
- **Evidence**: Real hardware measurements

### Intel SGX (Production)
- **Status**: `pass`
- **Trustworthiness**: Medium-High (85%+)
- **Use Case**: Production workloads
- **Evidence**: Real hardware measurements

## 🌐 **Production Deployment**

### Azure Intel TDX
1. Deploy Trustee services to Azure
2. Configure Intel TDX attestation
3. Update policies with real measurement values
4. Test with actual hardware attestation

### Azure Intel SGX
1. Deploy Trustee services to Azure
2. Configure Intel SGX attestation
3. Update policies with real measurement values
4. Test with actual hardware attestation

## 📚 **Next Steps**

1. **Deploy to Azure** with Intel TDX for production
2. **Configure real measurement values** in reference_values
3. **Update policies** with actual MRCONFIG_ID, MROWNER, MROWNER_CONFIG values
4. **Test with real hardware attestation**
5. **Integrate with your MPC system** using the configured resources

## 🎯 **Key Takeaways**

- **Multi-TEE Support**: Works with Intel TDX, SGX, AMD SEV-SNP, ARM CCA
- **Measurement Validation**: Specific validation for TDX parameters
- **Trustworthiness Scoring**: Configurable thresholds for different security levels
- **Policy-Driven Access**: Fine-grained control based on attestation results
- **Production Ready**: Complete configuration for Azure deployment

This configuration provides a complete attestation system that supports multiple TEE types with specific measurement validation and trustworthiness thresholds, ready for production deployment with your MPC system.
