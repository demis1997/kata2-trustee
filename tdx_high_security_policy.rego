package policy

# High-security policy for Intel TDX
# Requires Intel TDX attestation with specific measurements

default allow = false

# Allow access to high-security resources only with Intel TDX
allow {
    input.resource_path = "keys/high_security/*"
    input.attestation_results.tee_type == "intel_tdx"
    input.attestation_results.status == "pass"
    input.attestation_results.trustworthiness_vector.hardware >= 95
    input.attestation_results.trustworthiness_vector.configuration >= 90
    input.attestation_results.trustworthiness_vector.executables >= 90
}

# TDX-specific measurements validation
allow {
    input.resource_path = "keys/high_security/*"
    input.attestation_results.tee_type == "intel_tdx"
    input.attestation_results.status == "pass"
    
    # Validate TDX measurements
    tdx_measurements := input.attestation_results.runtime_data_claims.tdx_measurements
    tdx_measurements.mrtd != ""
    tdx_measurements.tcb_svn != ""
    tdx_measurements.td_attributes != ""
    
    # Validate RTMRs (Runtime Measurement Registers)
    tdx_measurements.rtmr0 != ""
    tdx_measurements.rtmr1 != ""
    tdx_measurements.rtmr2 != ""
    tdx_measurements.rtmr3 != ""
}

# Specific MRCONFIG_ID validation
allow {
    input.resource_path = "keys/tdx_config_specific/*"
    input.attestation_results.tee_type == "intel_tdx"
    input.attestation_results.status == "pass"
    
    # Check for specific MRCONFIG_ID
    tdx_measurements := input.attestation_results.runtime_data_claims.tdx_measurements
    tdx_measurements.mrconfig_id == "REQUIRED_MRCONFIG_ID_VALUE"
}

# Specific MROWNER validation
allow {
    input.resource_path = "keys/tdx_owner_specific/*"
    input.attestation_results.tee_type == "intel_tdx"
    input.attestation_results.status == "pass"
    
    # Check for specific MROWNER
    tdx_measurements := input.attestation_results.runtime_data_claims.tdx_measurements
    tdx_measurements.mrowner == "REQUIRED_MROWNER_VALUE"
}

# Specific MROWNER_CONFIG validation
allow {
    input.resource_path = "keys/tdx_owner_config_specific/*"
    input.attestation_results.tee_type == "intel_tdx"
    input.attestation_results.status == "pass"
    
    # Check for specific MROWNER_CONFIG
    tdx_measurements := input.attestation_results.runtime_data_claims.tdx_measurements
    tdx_measurements.mrowner_config == "REQUIRED_MROWNER_CONFIG_VALUE"
}

# Deny access if TEE type is not TDX
deny {
    input.resource_path = "keys/high_security/*"
    input.attestation_results.tee_type != "intel_tdx"
}

# Deny access if status is not pass
deny {
    input.resource_path = "keys/high_security/*"
    input.attestation_results.status != "pass"
}

# Deny access if trustworthiness is too low
deny {
    input.resource_path = "keys/high_security/*"
    input.attestation_results.trustworthiness_vector.hardware < 95
}

# Deny access if required TDX measurements are missing
deny {
    input.resource_path = "keys/high_security/*"
    input.attestation_results.tee_type == "intel_tdx"
    tdx_measurements := input.attestation_results.runtime_data_claims.tdx_measurements
    tdx_measurements.mrtd == ""
}
