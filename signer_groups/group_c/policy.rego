package policy
default allow = false

# Allow if sample attestation is present (development)
allow {
    input.attestation_results.tee_type == "sample"
    input.attestation_results.measurements.sample.launch_digest == "abcde"
}

# Allow access to development resources
allow {
    input.resource_path = "keys/development/*"
    input.attestation_results.tee_type == "sample"
}
