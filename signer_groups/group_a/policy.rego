package policy
default allow = false

# Only allow if Intel TDX attestation is present
allow {
    input.attestation_results.tee_type == "intel_tdx"
    input.attestation_results.measurements.platform_version.major >= 1
    input.attestation_results.measurements.platform_version.minor >= 4
}

# Allow access to high-security resources
allow {
    input.resource_path = "keys/high_security/*"
    input.attestation_results.tee_type == "intel_tdx"
}
