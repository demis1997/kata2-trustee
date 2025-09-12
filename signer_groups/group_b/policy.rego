package policy
default allow = false

# Allow if SGX attestation is present
allow {
    input.attestation_results.tee_type == "intel_sgx"
    input.attestation_results.measurements.sgx.mrsigner != ""
}

# Allow access to medium-security resources
allow {
    input.resource_path = "keys/medium_security/*"
    input.attestation_results.tee_type == "intel_sgx"
}
