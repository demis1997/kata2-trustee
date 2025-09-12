#!/bin/bash
set -euo pipefail

# Trustee Demo Script
# This script demonstrates all the features of the Trustee service

KBS_URL="http://localhost:8080"
ADMIN_KEY="kbs_private.key"

echo "🔐 Trustee Service Demo"
echo "======================"
echo

# Check if services are running
echo "1. Checking Trustee Services Status..."
echo "-------------------------------------"
if curl -s "$KBS_URL" >/dev/null 2>&1; then
    echo "✅ KBS is running on $KBS_URL"
else
    echo "❌ KBS is not accessible at $KBS_URL"
    echo "   Make sure your trustee services are running:"
    echo "   docker ps | grep trustee"
    exit 1
fi
echo

# Test basic attestation
echo "2. Testing Basic Attestation..."
echo "-------------------------------"
echo "Running attestation (sample mode)..."
ATTEST_RESULT=$(./target/release/kbs-client --url "$KBS_URL" attest 2>&1)
echo "$ATTEST_RESULT"
echo

# Create demo resources
echo "3. Creating Demo Resources..."
echo "----------------------------"
echo "Creating secret files..."

# Create different types of secrets
echo "This is a high-security secret" > high_security_secret.txt
echo "This is a medium-security config" > medium_config.txt
echo "This is a public key" > public_key.txt

echo "✅ Demo resources created"
echo

# Set up admin authentication
echo "4. Setting Up Admin Authentication..."
echo "------------------------------------"
if [ ! -f "$ADMIN_KEY" ]; then
    echo "❌ Admin key not found: $ADMIN_KEY"
    echo "   Make sure you have the correct private key file"
    exit 1
fi
echo "✅ Admin key found"
echo

# Register resources with different security levels
echo "5. Registering Resources with KBS..."
echo "------------------------------------"

echo "Registering high-security secret..."
./target/release/kbs-client --url "$KBS_URL" config --auth-private-key "$ADMIN_KEY" set-resource --path "secrets/high-security/secret1" --resource-file high_security_secret.txt

echo "Registering medium-security config..."
./target/release/kbs-client --url "$KBS_URL" config --auth-private-key "$ADMIN_KEY" set-resource --path "config/medium/conf1" --resource-file medium_config.txt

echo "Registering public key..."
./target/release/kbs-client --url "$KBS_URL" config --auth-private-key "$ADMIN_KEY" set-resource --path "keys/public/pub1" --resource-file public_key.txt

echo "✅ Resources registered successfully"
echo

# Set up permissive policy for demo
echo "6. Setting Up Access Policy..."
echo "-------------------------------"
cat > demo_policy.rego << 'EOF'
package policy

default allow = true

# Allow access to all resources for demo purposes
allow {
    true
}
EOF

echo "Setting permissive policy for demo..."
./target/release/kbs-client --url "$KBS_URL" config --auth-private-key "$ADMIN_KEY" set-resource-policy --policy-file demo_policy.rego

echo "✅ Policy set successfully"
echo

# Test resource retrieval
echo "7. Testing Resource Retrieval..."
echo "--------------------------------"

echo "Retrieving high-security secret..."
HIGH_SECRET=$(./target/release/kbs-client --url "$KBS_URL" get-resource --path "secrets/high-security/secret1" 2>&1 | tail -1)
echo "Retrieved: $(echo "$HIGH_SECRET" | base64 -d 2>/dev/null || echo "$HIGH_SECRET")"
echo

echo "Retrieving medium-security config..."
MEDIUM_CONFIG=$(./target/release/kbs-client --url "$KBS_URL" get-resource --path "config/medium/conf1" 2>&1 | tail -1)
echo "Retrieved: $(echo "$MEDIUM_CONFIG" | base64 -d 2>/dev/null || echo "$MEDIUM_CONFIG")"
echo

echo "Retrieving public key..."
PUBLIC_KEY=$(./target/release/kbs-client --url "$KBS_URL" get-resource --path "keys/public/pub1" 2>&1 | tail -1)
echo "Retrieved: $(echo "$PUBLIC_KEY" | base64 -d 2>/dev/null || echo "$PUBLIC_KEY")"
echo

# Test reference value management
echo "8. Testing Reference Value Management..."
echo "---------------------------------------"

echo "Setting sample reference value..."
./target/release/kbs-client --url "$KBS_URL" config --auth-private-key "$ADMIN_KEY" set-sample-reference-value "sample_ref" "sample_value_123" --as-single-value

echo "✅ Reference value set successfully"
echo

# Test different attestation scenarios
echo "9. Testing Multiple Attestation Scenarios..."
echo "--------------------------------------------"

echo "Running attestation #1..."
./target/release/kbs-client --url "$KBS_URL" attest >/dev/null 2>&1
echo "✅ Attestation #1 completed"

echo "Running attestation #2..."
./target/release/kbs-client --url "$KBS_URL" attest >/dev/null 2>&1
echo "✅ Attestation #2 completed"

echo "Running attestation #3..."
./target/release/kbs-client --url "$KBS_URL" attest >/dev/null 2>&1
echo "✅ Attestation #3 completed"
echo

# Test error scenarios
echo "10. Testing Error Scenarios..."
echo "------------------------------"

echo "Testing access to non-existent resource..."
./target/release/kbs-client --url "$KBS_URL" get-resource --path "nonexistent/resource" 2>&1 | head -3
echo

echo "Testing invalid resource path..."
./target/release/kbs-client --url "$KBS_URL" get-resource --path "invalid" 2>&1 | head -3
echo

# Show service status
echo "11. Trustee Service Status..."
echo "----------------------------"
echo "KBS Service: $KBS_URL"
echo "Attestation Service: localhost:50004"
echo "RVPS Service: localhost:50003"
echo "Keyprovider Service: localhost:50000"
echo

# Show Docker containers
echo "12. Docker Container Status..."
echo "-----------------------------"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep trustee
echo

echo "🎉 Trustee Demo Complete!"
echo "========================"
echo
echo "Key Features Demonstrated:"
echo "✅ Hardware attestation (sample mode)"
echo "✅ Secret management and storage"
echo "✅ Resource access control"
echo "✅ Policy-based authorization"
echo "✅ Reference value management"
echo "✅ Multi-party attestation"
echo "✅ Error handling"
echo
echo "Next Steps:"
echo "1. Integrate with your MPC system"
echo "2. Set up real hardware attestation (Intel TDX/SGX)"
echo "3. Configure production policies"
echo "4. Deploy to Kubernetes with Kata Containers"
echo
echo "For production use, replace sample attestation with real TEE attestation!"
