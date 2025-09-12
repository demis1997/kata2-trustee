package policy

# Policy for TDX resources that require specific MROWNER_CONFIG
# This demonstrates how to validate TDX owner configuration measurements

default allow = false

# Allow access if MROWNER_CONFIG matches required value
allow {
    input.resource_path = "keys/tdx_owner_config_specific/*"
    input.attestation_results.tee_type == "intel_tdx"
    input.attestation_results.status == "pass"
    
    # Validate TDX measurements
    tdx_measurements := input.attestation_results.runtime_data_claims.tdx_measurements
    tdx_measurements.mrowner_config == "REQUIRED_MROWNER_CONFIG_VALUE"
    
    # Additional TDX validations
    tdx_measurements.mrtd != ""
    tdx_measurements.tcb_svn != ""
    tdx_measurements.td_attributes != ""
    
    # Validate RTMRs
    tdx_measurements.rtmr0 != ""
    tdx_measurements.rtmr1 != ""
    tdx_measurements.rtmr2 != ""
    tdx_measurements.rtmr3 != ""
    
    # Validate trustworthiness
    input.attestation_results.trustworthiness_vector.hardware >= 95
    input.attestation_results.trustworthiness_vector.configuration >= 90
    input.attestation_results.trustworthiness_vector.executables >= 90
}

# Deny access if MROWNER_CONFIG doesn't match
deny {
    input.resource_path = "keys/tdx_owner_config_specific/*"
    input.attestation_results.tee_type == "intel_tdx"
    input.attestation_results.status == "pass"
    
    tdx_measurements := input.attestation_results.runtime_data_claims.tdx_measurements
    tdx_measurements.mrowner_config != "REQUIRED_MROWNER_CONFIG_VALUE"
}

# Deny access if not TDX
deny {
    input.resource_path = "keys/tdx_owner_specific/*"
    input.attestation_results.tee_type != "intel_tdx"
}

# Deny access if status is not pass
deny {
    input.resource_path = "keys/tdx_owner_config_specific/*"
    input.attestation_results.status != "pass"
}

# Deny access if trustworthiness is too low
deny {
    input.resource_path = "keys/tdx_owner_config_specific/*"
    input.attestation_results.trustworthiness_vector.hardware < 95
}
