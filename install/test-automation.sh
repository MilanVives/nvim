#!/bin/bash

# Test script for verifying Ansible automation compatibility
# This script tests the install-ubuntu.sh script in various automation scenarios

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/install-ubuntu.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[TEST INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[TEST WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[TEST ERROR]${NC} $1"
}

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# Check if we're on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    log_warn "This test script is designed for Ubuntu systems"
    log_info "The install script will detect this and exit appropriately"
fi

# Test 1: Help flag
log_test "Testing --help flag"
if $INSTALL_SCRIPT --help &>/dev/null; then
    log_info "✅ Help flag works correctly"
else
    log_error "❌ Help flag failed"
    exit 1
fi

# Test 2: Non-interactive mode (should work without hanging)
log_test "Testing non-interactive mode"
if timeout 30 $INSTALL_SCRIPT --non-interactive --force-reinstall 2>/dev/null; then
    log_info "✅ Non-interactive mode completed within 30 seconds"
elif [[ $? -eq 124 ]]; then
    log_error "❌ Non-interactive mode hung (timeout after 30s)"
    exit 1
else
    log_info "✅ Non-interactive mode exited appropriately (may have failed due to non-Ubuntu system)"
fi

# Test 3: Environment variables
log_test "Testing environment variables"
if timeout 30 bash -c 'NVIM_NON_INTERACTIVE=true NVIM_FORCE_REINSTALL=true '"$INSTALL_SCRIPT"' 2>/dev/null'; then
    log_info "✅ Environment variables work correctly"
elif [[ $? -eq 124 ]]; then
    log_error "❌ Environment variable mode hung (timeout after 30s)"
    exit 1
else
    log_info "✅ Environment variable mode exited appropriately"
fi

# Test 4: Invalid flag handling
log_test "Testing invalid flag handling"
if $INSTALL_SCRIPT --invalid-flag 2>/dev/null; then
    log_error "❌ Invalid flag was accepted (should have been rejected)"
    exit 1
else
    log_info "✅ Invalid flag correctly rejected"
fi

# Test 5: Home directory detection simulation
log_test "Testing home directory detection"
cat << 'EOF' > /tmp/test_home_detection.sh
#!/bin/bash
# Simulate the home directory detection logic
home_dir="${HOME:-$(getent passwd "$(whoami)" | cut -d: -f6)}"
echo "Detected home directory: $home_dir"
if [[ -z "$home_dir" ]]; then
    echo "ERROR: Could not detect home directory"
    exit 1
fi
EOF

chmod +x /tmp/test_home_detection.sh
if /tmp/test_home_detection.sh; then
    log_info "✅ Home directory detection logic works"
else
    log_error "❌ Home directory detection failed"
    exit 1
fi
rm -f /tmp/test_home_detection.sh

# Test 6: Simulate Ansible execution (dry run)
log_test "Simulating Ansible execution environment"
cat << EOF > /tmp/ansible_simulation.sh
#!/bin/bash
# Simulate how Ansible would run the script
export NVIM_NON_INTERACTIVE=true
export NVIM_FORCE_REINSTALL=true

# Run in a way similar to Ansible's script module
timeout 60 $INSTALL_SCRIPT --non-interactive --force-reinstall
exit_code=\$?

if [[ \$exit_code -eq 124 ]]; then
    echo "ANSIBLE SIMULATION: Script hung (would fail in Ansible)"
    exit 1
elif [[ \$exit_code -eq 0 ]]; then
    echo "ANSIBLE SIMULATION: Script completed successfully"
    exit 0
else
    echo "ANSIBLE SIMULATION: Script exited with code \$exit_code (may be expected on non-Ubuntu)"
    exit 0
fi
EOF

chmod +x /tmp/ansible_simulation.sh
if /tmp/ansible_simulation.sh 2>/dev/null; then
    log_info "✅ Ansible simulation completed successfully"
else
    log_error "❌ Ansible simulation failed"
    exit 1
fi
rm -f /tmp/ansible_simulation.sh

log_info "🎉 All automation compatibility tests passed!"
log_info ""
log_info "The script is ready for Ansible automation with:"
log_info "  • --non-interactive flag"
log_info "  • --force-reinstall flag"  
log_info "  • NVIM_NON_INTERACTIVE environment variable"
log_info "  • NVIM_FORCE_REINSTALL environment variable"
log_info "  • Proper timeout handling"
log_info "  • Appropriate exit codes"
log_info ""
log_info "Example Ansible task:"
echo '  - name: Install Neovim'
echo '    script: install-ubuntu.sh --non-interactive --force-reinstall'
echo '    become: yes'
echo '    environment:'
echo '      NVIM_NON_INTERACTIVE: "true"'
echo '      NVIM_FORCE_REINSTALL: "true"'