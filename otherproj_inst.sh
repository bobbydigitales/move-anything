#!/usr/bin/env bash

# Simple wrapper script for the new install-move.sh
# This provides backward compatibility and better guidance

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "  extending-move Installation Script"
echo "=========================================="
echo ""
echo "This script will install extending-move on your Ableton Move."
echo ""
echo "Features:"
echo "  - Automatically detects existing installations"
echo "  - Prompts for overwrite/update/cancel when found"
echo "  - Shows version information of existing installations"
echo ""
echo "Options:"
echo "  --skip-ssh        Skip SSH setup (if already configured)"
echo "  --skip-autostart  Skip autostart setup"
echo "  --dev             Development mode (skip pip install, tail logs)"
echo "  --overwrite       Force overwrite existing installation"
echo "  --help            Show detailed help"
echo ""
echo "Examples:"
echo "  $0                    # Full installation with SSH setup"
echo "  $0 --skip-ssh         # Install without SSH setup"
echo "  $0 --dev              # Development installation"
echo "  $0 --overwrite        # Force overwrite existing installation"
echo ""

# Check if the new script exists
if [ ! -f "${SCRIPT_DIR}/install-move.sh" ]; then
    echo "Error: install-move.sh not found!"
    exit 1
fi

# Pass all arguments to the new script
exec "${SCRIPT_DIR}/install-move.sh" "$@"
