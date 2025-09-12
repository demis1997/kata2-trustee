# Attestation Resources Examples

## Overview
This document provides real working examples of KBS resources that can be used with different attestation parameters and TEE types.

## Resource Categories

### 1. High-Security Resources (Intel TDX Required)
These resources require Intel TDX attestation with specific measurements.

#### TDX-Specific MPC Keys
```bash
# High-security MPC coordinator key (requires TDX)
kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/high_security/mpc_coordinator_tdx" \
  --resource-file coordinator_tdx_key.pem

# TDX-specific policy for this resource
kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --path "policy/high_security_tdx" \
  --policy-file tdx_high_security_policy.rego
```

#### TDX Measurement-Specific Resources
```bash
# Resource that requires specific MRCONFIG_ID
kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/tdx_config_specific/mpc_signer" \
  --resource-file tdx_config_signer.pem

# Resource that requires specific MROWNER
kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/tdx_owner_specific/mpc_coordinator" \
  --resource-file tdx_owner_coordinator.pem

# Resource that requires specific MROWNER_CONFIG
kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/tdx_owner_config_specific/mpc_signer" \
  --resource-file tdx_owner_config_signer.pem
```

### 2. Medium-Security Resources (Intel SGX Required)
These resources require Intel SGX attestation.

```bash
# SGX-specific MPC signer keys
kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/medium_security/mpc_signer_sgx" \
  --resource-file signer_sgx_key.pem

# SGX policy
kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --path "policy/medium_security_sgx" \
  --policy-file sgx_medium_security_policy.rego
```

### 3. Development Resources (Sample Attester)
These resources work with the sample attester for development.

```bash
# Development MPC keys
kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/development/mpc_coordinator_dev" \
  --resource-file dev_coordinator_key.pem

# Development policy
kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --path "policy/development_sample" \
  --policy-file sample_development_policy.rego
```

### 4. Multi-TEE Resources
Resources that can be accessed by multiple TEE types.

```bash
# Multi-TEE MPC configuration
kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/multi_tee/mpc_config" \
  --resource-file multi_tee_config.json

# Multi-TEE policy
kbs-client config --auth-private-key kbs_private.key set-resource-policy \
  --path "policy/multi_tee" \
  --policy-file multi_tee_policy.rego
```

## Resource File Examples

### TDX-Specific Key Files
```bash
# Generate TDX-specific keys
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out coordinator_tdx_key.pem
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out tdx_config_signer.pem
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out tdx_owner_coordinator.pem
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out tdx_owner_config_signer.pem
```

### SGX-Specific Key Files
```bash
# Generate SGX-specific keys
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out signer_sgx_key.pem
```

### Development Key Files
```bash
# Generate development keys
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out dev_coordinator_key.pem
```

### Multi-TEE Configuration
```json
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
    }
  }
}
```

## Resource Access Patterns

### 1. TEE-Specific Access
```bash
# Access TDX-specific resource
kbs-client get-resource --path "keys/high_security/mpc_coordinator_tdx"

# Access SGX-specific resource  
kbs-client get-resource --path "keys/medium_security/mpc_signer_sgx"

# Access development resource
kbs-client get-resource --path "keys/development/mpc_coordinator_dev"
```

### 2. Measurement-Specific Access
```bash
# Access based on specific TDX measurements
kbs-client get-resource --path "keys/tdx_config_specific/mpc_signer"
kbs-client get-resource --path "keys/tdx_owner_specific/mpc_coordinator"
kbs-client get-resource --path "keys/tdx_owner_config_specific/mpc_signer"
```

### 3. Multi-TEE Access
```bash
# Access multi-TEE resource (works with any supported TEE)
kbs-client get-resource --path "keys/multi_tee/mpc_config"
```

## Resource Organization

```
keys/
├── high_security/           # Intel TDX only
│   ├── mpc_coordinator_tdx/
│   └── mpc_signer_tdx/
├── medium_security/         # Intel SGX only
│   ├── mpc_signer_sgx/
│   └── mpc_coordinator_sgx/
├── development/             # Sample attester
│   ├── mpc_coordinator_dev/
│   └── mpc_signer_dev/
├── tdx_config_specific/     # Specific MRCONFIG_ID
│   └── mpc_signer/
├── tdx_owner_specific/      # Specific MROWNER
│   └── mpc_coordinator/
├── tdx_owner_config_specific/ # Specific MROWNER_CONFIG
│   └── mpc_signer/
└── multi_tee/              # Multiple TEE types
    └── mpc_config/
```
