package policy

# Development policy for Sample attester
# Allows access for development and testing purposes

default allow = false

# Allow access to development resources with sample attester
allow {
    input.resource_path = "keys/development/*"
    input.attestation_results.tee_type == "sample"
    input.attestation_results.status == "contraindicated"
}

# Allow access to development resources with any TEE type (for testing)
allow {
    input.resource_path = "keys/development/*"
    input.attestation_results.tee_type != ""
    input.attestation_results.status != ""
}

# Sample-specific measurements validation (for demonstration)
allow {
    input.resource_path = "keys/development/*"
    input.attestation_results.tee_type == "sample"
    input.attestation_results.status == "contraindicated"
    
    # Validate sample measurements
    sample_measurements := input.attestation_results.runtime_data_claims.sample
    sample_measurements.launch_digest != ""
    sample_measurements.svn != ""
    sample_measurements.platform_version != ""
}

# Allow access to multi-TEE resources from development
allow {
    input.resource_path = "keys/multi_tee/*"
    input.attestation_results.tee_type == "sample"
    input.attestation_results.status == "contraindicated"
}

# Deny access to high-security resources from sample attester
deny {
    input.resource_path = "keys/high_security/*"
    input.attestation_results.tee_type == "sample"
}

# Deny access to medium-security resources from sample attester
deny {
    input.resource_path = "keys/medium_security/*"
    input.attestation_results.tee_type == "sample"
}
