package policy

# Policy for TDX resources that require specific MRCONFIG_ID
# This demonstrates how to validate TDX-specific measurements

default allow = false

# Allow access if MRCONFIG_ID matches required value
allow {
    input.resource_path = "keys/tdx_config_specific/*"
    input.attestation_results.tee_type == "intel_tdx"
    input.attestation_results.status == "pass"
    
    # Validate TDX measurements
    tdx_measurements := input.attestation_results.runtime_data_claims.tdx_measurements
    tdx_measurements.mrconfig_id == "REQUIRED_MRCONFIG_ID_VALUE"
    
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

# Deny access if MRCONFIG_ID doesn't match
deny {
    input.resource_path = "keys/tdx_config_specific/*"
    input.attestation_results.tee_type == "intel_tdx"
    input.attestation_results.status == "pass"
    
    tdx_measurements := input.attestation_results.runtime_data_claims.tdx_measurements
    tdx_measurements.mrconfig_id != "REQUIRED_MRCONFIG_ID_VALUE"
}

# Deny access if not TDX
deny {
    input.resource_path = "keys/tdx_config_specific/*"
    input.attestation_results.tee_type != "intel_tdx"
}

# Deny access if status is not pass
deny {
    input.resource_path = "keys/tdx_config_specific/*"
    input.attestation_results.status != "pass"
}

# Deny access if trustworthiness is too low
deny {
    input.resource_path = "keys/tdx_config_specific/*"
    input.attestation_results.trustworthiness_vector.hardware < 95
}
