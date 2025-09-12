package policy

# Medium-security policy for Intel SGX
# Requires Intel SGX attestation with specific measurements

default allow = false

# Allow access to medium-security resources with Intel SGX
allow {
    input.resource_path = "keys/medium_security/*"
    input.attestation_results.tee_type == "intel_sgx"
    input.attestation_results.status == "pass"
    input.attestation_results.trustworthiness_vector.hardware >= 85
    input.attestation_results.trustworthiness_vector.configuration >= 80
    input.attestation_results.trustworthiness_vector.executables >= 80
}

# SGX-specific measurements validation
allow {
    input.resource_path = "keys/medium_security/*"
    input.attestation_results.tee_type == "intel_sgx"
    input.attestation_results.status == "pass"
    
    # Validate SGX measurements
    sgx_measurements := input.attestation_results.runtime_data_claims.sgx_measurements
    sgx_measurements.mrenclave != ""
    sgx_measurements.mrsigner != ""
    sgx_measurements.cpu_svn != ""
    sgx_measurements.isv_svn != ""
    sgx_measurements.attributes != ""
}

# Specific MRENCLAVE validation
allow {
    input.resource_path = "keys/medium_security/mpc_signer_sgx"
    input.attestation_results.tee_type == "intel_sgx"
    input.attestation_results.status == "pass"
    
    # Check for specific MRENCLAVE
    sgx_measurements := input.attestation_results.runtime_data_claims.sgx_measurements
    sgx_measurements.mrenclave == "REQUIRED_MRENCLAVE_VALUE"
}

# Specific MRSIGNER validation
allow {
    input.resource_path = "keys/medium_security/mpc_coordinator_sgx"
    input.attestation_results.tee_type == "intel_sgx"
    input.attestation_results.status == "pass"
    
    # Check for specific MRSIGNER
    sgx_measurements := input.attestation_results.runtime_data_claims.sgx_measurements
    sgx_measurements.mrsigner == "REQUIRED_MRSIGNER_VALUE"
}

# Deny access if TEE type is not SGX
deny {
    input.resource_path = "keys/medium_security/*"
    input.attestation_results.tee_type != "intel_sgx"
}

# Deny access if status is not pass
deny {
    input.resource_path = "keys/medium_security/*"
    input.attestation_results.status != "pass"
}

# Deny access if trustworthiness is too low
deny {
    input.resource_path = "keys/medium_security/*"
    input.attestation_results.trustworthiness_vector.hardware < 85
}

# Deny access if required SGX measurements are missing
deny {
    input.resource_path = "keys/medium_security/*"
    input.attestation_results.tee_type == "intel_sgx"
    sgx_measurements := input.attestation_results.runtime_data_claims.sgx_measurements
    sgx_measurements.mrenclave == ""
}
