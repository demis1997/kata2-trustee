# Attestation-Based Signer Selection for MPC

## 🎯 Overview

This demo shows how to use Trustee's attestation capabilities to automatically select appropriate signers for MPC transactions based on their hardware security guarantees.

## 🏗️ Architecture

```
┌─────────────────┐    Attestation    ┌─────────────────────┐
│   MPC Signer    │ ─────────────────►│  Trustee KBS        │
│  (Docker)       │                   │  (Policy Engine)    │
└─────────────────┘                   └─────────┬───────────┘
                                                │
                                                ▼
┌─────────────────┐    JWT Token      ┌─────────────────────┐
│   MPC Coordinator│ ◄─────────────────│  Attestation Service│
│                 │                   │  (AS)               │
└─────────────────┘                   └─────────────────────┘
```

## 🔐 Signer Groups

### Group A: High Security (Intel TDX)
- **TEE Type**: Intel TDX
- **Use Case**: High-value transactions ($1M+)
- **Resources**: `keys/high_security/*`
- **Threshold**: 2+ signers required

### Group B: Medium Security (Intel SGX)
- **TEE Type**: Intel SGX
- **Use Case**: Medium-value transactions ($100K-$1M)
- **Resources**: `keys/medium_security/*`
- **Threshold**: 2+ signers required

### Group C: Development (Sample)
- **TEE Type**: Sample (development)
- **Use Case**: Low-value transactions (<$100K)
- **Resources**: `keys/development/*`
- **Threshold**: 1+ signer required

## 🔑 Key Management

### Private Keys
- **Stored in**: Trustee KBS (hardware-protected)
- **Access**: Only with valid attestation
- **Distribution**: Automatic based on TEE type

### Public Keys
- **Derived from**: Private keys in KBS
- **Verification**: Attestation-based
- **Sharing**: Secure channel established via attestation

## 🚀 How It Works

### 1. Signer Registration
```bash
# Each signer group registers with KBS
./kbs-client config --auth-private-key kbs_private.key set-resource \
  --path "keys/high_security/coordinator_key" \
  --resource-file coordinator_key.pem
```

### 2. Attestation Process
```bash
# Signer requests attestation
./kbs-client --url http://localhost:8080 attest

# KBS verifies TEE type and issues JWT token
# Token contains: TEE type, measurements, policy results
```

### 3. Resource Access
```bash
# Signer requests specific resources
./kbs-client get-resource --path "keys/high_security/coordinator_key"

# KBS checks:
# - JWT token validity
# - TEE type matches resource requirements
# - Policy allows access
```

### 4. Transaction Routing
```python
# Coordinator selects signers based on:
# - Transaction value
# - Required security level
# - Signer attestation capabilities
# - Available resources
```

## 📋 Transaction Flow

1. **Transaction Request** arrives at coordinator
2. **Value Analysis** determines required security level
3. **Signer Discovery** queries available signers
4. **Attestation Verification** checks each signer's capabilities
5. **Resource Access** verifies signer can access required keys
6. **Signer Selection** chooses minimum required qualified signers
7. **MPC Execution** routes transaction to selected signers

## 🛡️ Security Benefits

- **Hardware Guarantees**: Attestation proves TEE integrity
- **Automatic Selection**: No manual signer configuration
- **Policy Enforcement**: Access control at hardware level
- **Audit Trail**: Complete attestation history
- **Key Protection**: Private keys never leave secure hardware

## 🔧 Integration with Your MPC

### Coordinator Changes
```go
// Add attestation verification
func (c *Coordinator) selectSigners(transactionValue int) []string {
    // 1. Determine required security level
    securityLevel := determineSecurityLevel(transactionValue)
    
    // 2. Query available signers
    availableSigners := c.getAvailableSigners()
    
    // 3. Verify attestation for each signer
    qualifiedSigners := []string{}
    for _, signer := range availableSigners {
        if c.verifyAttestation(signer, securityLevel) {
            qualifiedSigners = append(qualifiedSigners, signer)
        }
    }
    
    // 4. Select minimum required signers
    return selectMinimumSigners(qualifiedSigners, securityLevel)
}
```

### Signer Changes
```go
// Add attestation on startup
func (s *Signer) initialize() error {
    // 1. Request attestation from Trustee
    token, err := s.requestAttestation()
    if err != nil {
        return err
    }
    
    // 2. Register with coordinator using token
    return s.registerWithCoordinator(token)
}
```

## 🎯 Demo Results

The demo shows:
- ✅ Automatic signer selection based on transaction value
- ✅ Hardware-based security verification
- ✅ Policy enforcement at the TEE level
- ✅ Secure key distribution based on attestation
- ✅ Scalable multi-group architecture

## 🚀 Next Steps

1. **Deploy to Azure** with Intel TDX hardware
2. **Integrate with your MPC** coordinator
3. **Add custom policies** for your specific requirements
4. **Monitor attestation** results and signer health
5. **Scale horizontally** with additional signer groups

This provides a robust, scalable, and secure foundation for your MPC implementation with hardware-backed security guarantees.
