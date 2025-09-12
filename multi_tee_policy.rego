package policy

# Multi-TEE policy that supports multiple TEE types
# Allows access from Intel TDX, Intel SGX, and Sample attesters

default allow = false

# Allow access from Intel TDX
allow {
    input.resource_path = "keys/multi_tee/*"
    input.attestation_results.tee_type == "intel_tdx"
    input.attestation_results.status == "pass"
    input.attestation_results.trustworthiness_vector.hardware >= 90
}

# Allow access from Intel SGX
allow {
    input.resource_path = "keys/multi_tee/*"
    input.attestation_results.tee_type == "intel_sgx"
    input.attestation_results.status == "pass"
    input.attestation_results.trustworthiness_vector.hardware >= 80
}

# Allow access from Sample attester (development)
allow {
    input.resource_path = "keys/multi_tee/*"
    input.attestation_results.tee_type == "sample"
    input.attestation_results.status == "contraindicated"
}

# Allow access from AMD SEV-SNP
allow {
    input.resource_path = "keys/multi_tee/*"
    input.attestation_results.tee_type == "amd_sev_snp"
    input.attestation_results.status == "pass"
    input.attestation_results.trustworthiness_vector.hardware >= 85
}

# Allow access from ARM CCA
allow {
    input.resource_path = "keys/multi_tee/*"
    input.attestation_results.tee_type == "arm_cca"
    input.attestation_results.status == "pass"
    input.attestation_results.trustworthiness_vector.hardware >= 85
}

# Deny access if no valid TEE type
deny {
    input.resource_path = "keys/multi_tee/*"
    input.attestation_results.tee_type == ""
}

# Deny access if status is invalid
deny {
    input.resource_path = "keys/multi_tee/*"
    input.attestation_results.status == ""
}

# Deny access if trustworthiness is too low for hardware TEEs
deny {
    input.resource_path = "keys/multi_tee/*"
    input.attestation_results.tee_type == "intel_tdx"
    input.attestation_results.trustworthiness_vector.hardware < 90
}

deny {
    input.resource_path = "keys/multi_tee/*"
    input.attestation_results.tee_type == "intel_sgx"
    input.attestation_results.trustworthiness_vector.hardware < 80
}

deny {
    input.resource_path = "keys/multi_tee/*"
    input.attestation_results.tee_type == "amd_sev_snp"
    input.attestation_results.trustworthiness_vector.hardware < 85
}

deny {
    input.resource_path = "keys/multi_tee/*"
    input.attestation_results.tee_type == "arm_cca"
    input.attestation_results.trustworthiness_vector.hardware < 85
}
