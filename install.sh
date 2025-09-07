#!/usr/bin/env bash

# Move Anything Installer
# A comprehensive installer with better UX and error handling

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
HOSTNAME="move.local"
USERNAME="ableton"
INSTALL_DIR="/data/UserData/control_surface_move"
BINARY_DIR="/opt/move"
SHIM_PATH="/usr/lib/control_surface_move_shim.so"
REPO_URL="https://github.com/bobbydigitales/move-anything/raw/main/"
FILENAME="control_surface_move.tar.gz"
VERSION_FILE="VERSION"

# SSH commands
SSH_ABLETON="ssh -o LogLevel=QUIET -o ConnectTimeout=10 -o StrictHostKeyChecking=no"
SSH_ROOT="ssh -o LogLevel=QUIET -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@$HOSTNAME"

# Global variables
INSTALL_PAGES=false
SKIP_SSH=false
FORCE_OVERWRITE=false
DEV_MODE=false
VERBOSE=false

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}$1${NC}"
}

# Show banner
show_banner() {
    clear
    cat << 'EOF'
 __  __                   ____            _             _   ____              __              
|  \/  | _____   _____   / ___|___  _ __ | |_ _ __ ___ | | / ___| _   _ _ __ / _| __ _  ___ ___ 
| |\/| |/ _ \ \ / / _ \ | |   / _ \| '_ \| __| '__/ _ \| | \___ \| | | | '__| |_ / _` |/ __/ _ \
| |  | | (_) \ V /  __/ | |__| (_) | | | | |_| | | (_) | |  ___) | |_| | |  |  _| (_| | (_|  __/
|_|  |_|\___/ \_/ \___|  \____\___/|_| |_|\__|_|  \___/|_| |____/ \__,_|_|  |_|  \__,_|\___\___|

EOF
    echo -e "${CYAN}Move Anything Installer${NC}"
    echo -e "${CYAN}========================${NC}"
    echo ""
}

# Show help
show_help() {
    cat << EOF
Move Anything Installer

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --skip-ssh        Skip SSH setup (if already configured)
    --force           Force overwrite existing installation
    --dev             Development mode (use local package)
    --verbose         Show detailed output
    --help            Show this help message

EXAMPLES:
    $0                    # Full installation with SSH setup
    $0 --skip-ssh         # Install without SSH setup
    $0 --force            # Force overwrite existing installation
    $0 --dev              # Development installation (requires local package)

FEATURES:
    - Automatic SSH setup guidance
    - Network connectivity validation
    - Existing installation detection
    - Version management
    - Comprehensive error handling
    - Progress indicators

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-ssh)
                SKIP_SSH=true
                shift
                ;;
            --force)
                FORCE_OVERWRITE=true
                shift
                ;;
            --dev)
                DEV_MODE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Check if required tools are available
check_dependencies() {
    print_status "Checking dependencies..."
    
    local missing_tools=()
    
    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi
    
    if ! command -v ssh &> /dev/null; then
        missing_tools+=("ssh")
    fi
    
    if ! command -v scp &> /dev/null; then
        missing_tools+=("scp")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_error "Please install the missing tools and try again."
        exit 1
    fi
    
    print_success "All dependencies found"
}

# Check network connectivity to Move
check_network() {
    print_status "Checking network connectivity to Move..."
    
    if ! ping -c 1 -W 3 "$HOSTNAME" &> /dev/null; then
        print_error "Cannot reach $HOSTNAME"
        echo ""
        print_warning "Troubleshooting steps:"
        echo "1. Make sure your Move is powered on"
        echo "2. Check that your Move and computer are on the same network"
        echo "3. Try accessing http://$HOSTNAME in your browser"
        echo "4. Check your network settings"
        echo ""
        read -p "Press Enter to retry or Ctrl+C to exit..."
        check_network
        return
    fi
    
    print_success "Network connectivity confirmed"
}

# Check SSH access
check_ssh_access() {
    print_status "Checking SSH access..."
    
    if $SSH_ABLETON "$USERNAME@$HOSTNAME" "echo 'SSH test successful'" &> /dev/null; then
        print_success "SSH access confirmed"
        return 0
    else
        print_warning "SSH access not available"
        return 1
    fi
}

# Setup SSH access
setup_ssh() {
    print_header "SSH Setup Required"
    echo ""
    print_status "SSH access is required to install Move Anything."
    echo ""
    print_warning "To set up SSH access:"
    echo "1. Open your web browser"
    echo "2. Go to: http://$HOSTNAME/development/ssh"
    echo "3. Add your SSH public key"
    echo ""
    echo "If you don't have an SSH key, you can generate one with:"
    echo "   ssh-keygen -t ed25519 -C \"your_email@example.com\""
    echo ""
    echo "Your public key is usually located at:"
    echo "   ~/.ssh/id_ed25519.pub (or ~/.ssh/id_rsa.pub)"
    echo ""
    
    read -p "Press Enter when you've added your SSH key, or Ctrl+C to exit..."
    
    if check_ssh_access; then
        print_success "SSH setup completed successfully!"
    else
        print_error "SSH setup failed. Please check your configuration."
        echo ""
        print_warning "Common issues:"
        echo "- Make sure you copied the entire public key"
        echo "- Check that the key doesn't have extra spaces or newlines"
        echo "- Try regenerating the key if needed"
        echo ""
        exit 1
    fi
}

# Check for existing installation
check_existing_installation() {
    print_status "Checking for existing installation..."
    
    if $SSH_ABLETON "$USERNAME@$HOSTNAME" "test -f $SHIM_PATH" &> /dev/null; then
        print_warning "Move Anything appears to be already installed"
        
        if [ "$FORCE_OVERWRITE" = true ]; then
            print_status "Force overwrite enabled - proceeding with installation"
            return 0
        fi
        
        echo ""
        print_status "Existing installation detected. What would you like to do?"
        echo "1) Update existing installation"
        echo "2) Overwrite existing installation"
        echo "3) Cancel installation"
        echo ""
        
        while true; do
            read -p "Choose an option (1-3): " choice
            case $choice in
                1)
                    print_status "Updating existing installation..."
                    return 0
                    ;;
                2)
                    print_status "Overwriting existing installation..."
                    return 0
                    ;;
                3)
                    print_status "Installation cancelled"
                    exit 0
                    ;;
                *)
                    print_error "Invalid choice. Please enter 1, 2, or 3."
                    ;;
            esac
        done
    else
        print_status "No existing installation found - proceeding with fresh install"
    fi
}

# Download the installation package
download_package() {
    print_status "Downloading Move Anything package..."
    
    local url="$REPO_URL$FILENAME"
    
    if [ "$DEV_MODE" = true ]; then
        print_status "Development mode: using local package"
        if [ ! -f "$FILENAME" ]; then
            print_error "Development mode requires $FILENAME to be present in current directory"
            print_status "Run './package.sh' first to create the package"
            exit 1
        fi
    else
        # Check if package already exists locally first
        if [ -f "$FILENAME" ]; then
            print_status "Using existing local package: $FILENAME"
        else
            print_status "Downloading from: $url"
            if ! curl -L -o "$FILENAME" "$url"; then
                print_warning "Failed to download from new repository, trying original..."
                local fallback_url="https://github.com/bobbydigitales/control_surface_move/raw/main/$FILENAME"
                print_status "Trying fallback URL: $fallback_url"
                if ! curl -L -o "$FILENAME" "$fallback_url"; then
                    print_error "Failed to download package from both repositories"
                    print_warning "This might be because:"
                    echo "1. The package hasn't been uploaded to GitHub yet"
                    echo "2. You're not connected to the internet"
                    echo "3. The repository URLs have changed"
                    echo ""
                    print_status "You can try:"
                    echo "1. Run './package.sh' to build the package locally"
                    echo "2. Use '--dev' flag to use local development mode"
                    echo "3. Check the repository for the latest release"
                    exit 1
                else
                    print_success "Downloaded from fallback repository"
                fi
            fi
        fi
    fi
    
    # Verify package
    if [ ! -f "$FILENAME" ]; then
        print_error "Package not found"
        exit 1
    fi
    
    # Test if the package is valid
    if ! tar -tzf "$FILENAME" &> /dev/null; then
        print_error "Package appears to be corrupted or invalid"
        print_warning "Try downloading again or building locally with './package.sh'"
        exit 1
    fi
    
    local file_size=$(du -h "$FILENAME" | cut -f1)
    print_success "Package ready ($file_size)"
    
    if [ "$VERBOSE" = true ]; then
        print_status "Package MD5: $(md5sum "$FILENAME" | cut -d' ' -f1)"
    fi
}

# Upload and extract package
install_package() {
    print_status "Uploading package to Move..."
    
    if ! scp -o ConnectTimeout=10 "$FILENAME" "$USERNAME@$HOSTNAME:."; then
        print_error "Failed to upload package"
        exit 1
    fi
    
    print_success "Package uploaded successfully"
    
    # Verify the uploaded file
    print_status "Verifying uploaded package..."
    if ! $SSH_ABLETON "$USERNAME@$HOSTNAME" "file ./$FILENAME"; then
        print_error "Failed to verify uploaded package"
        exit 1
    fi
    
    print_status "Extracting package..."
    # Try different extraction methods for compatibility
    if ! $SSH_ABLETON "$USERNAME@$HOSTNAME" "tar -xzf ./$FILENAME"; then
        print_warning "Standard tar extraction failed, trying alternative method..."
        if ! $SSH_ABLETON "$USERNAME@$HOSTNAME" "gunzip -c ./$FILENAME | tar -xf -"; then
            print_error "Failed to extract package with all methods"
            print_status "Debugging: checking file on Move..."
            $SSH_ABLETON "$USERNAME@$HOSTNAME" "ls -la ./$FILENAME"
            $SSH_ABLETON "$USERNAME@$HOSTNAME" "file ./$FILENAME"
            exit 1
        fi
    fi
    
    print_success "Package extracted successfully"
}

# Install the shim and binaries
install_binaries() {
    print_status "Installing Move Anything components..."
    
    # Stop existing Move processes
    print_status "Stopping existing Move processes..."
    $SSH_ABLETON "$USERNAME@$HOSTNAME" "killall MoveLauncher Move MoveOriginal 2>/dev/null || true"
    
    # Install shim
    print_status "Installing control surface shim..."
    $SSH_ROOT "cp -f $INSTALL_DIR/control_surface_move_shim.so $SHIM_PATH"
    $SSH_ROOT "chmod u+s $SHIM_PATH"
    
    # Backup original Move binary if needed
    print_status "Backing up original Move binary..."
    if ! $SSH_ROOT "test -f $BINARY_DIR/MoveOriginal"; then
        $SSH_ROOT "mv $BINARY_DIR/Move $BINARY_DIR/MoveOriginal"
        $SSH_ABLETON "$USERNAME@$HOSTNAME" "cp $BINARY_DIR/MoveOriginal ~/"
        print_success "Original Move binary backed up"
    else
        print_status "Original Move binary already backed up"
    fi
    
    # Install new Move binary
    print_status "Installing new Move binary..."
    $SSH_ROOT "chmod +x $INSTALL_DIR/Move.sh"
    $SSH_ROOT "cp $INSTALL_DIR/Move.sh $BINARY_DIR/Move"
    
    print_success "Binary installation completed"
}

# Install Pages of Sets feature
install_pages_of_sets() {
    print_status "Checking Pages of Sets installation..."
    
    if $SSH_ABLETON "$USERNAME@$HOSTNAME" "test -L ~/UserLibrary"; then
        print_status "Pages of Sets already installed"
        return 0
    fi
    
    echo ""
    print_header "Pages of Sets Feature"
    echo ""
    print_status "Pages of Sets allows unlimited pages of sets on your Move."
    print_warning "IMPORTANT: This will rearrange your sets and change their colors!"
    echo ""
    print_status "Features:"
    echo "- Hold Shift + Left/Right arrows to change pages"
    echo "- Each page has its own set of Live Sets"
    echo "- Samples, Track presets, Recordings and Effects presets are shared"
    echo "- http://move.local will show Sets from the current page"
    echo ""
    
    while true; do
        read -p "Install Pages of Sets? [y/N]: " yn
        case $yn in
            [Yy]*)
                INSTALL_PAGES=true
                break
                ;;
            [Nn]*|"")
                INSTALL_PAGES=false
                break
                ;;
            *)
                print_error "Please answer yes or no."
                ;;
        esac
    done
    
    if [ "$INSTALL_PAGES" = true ]; then
        print_status "Installing Pages of Sets..."
        
        $SSH_ABLETON "$USERNAME@$HOSTNAME" "mv ~/UserLibrary ~/UserLibrary_base"
        $SSH_ABLETON "$USERNAME@$HOSTNAME" "$INSTALL_DIR/changePage.sh 0 skipLaunch"
        $SSH_ABLETON "$USERNAME@$HOSTNAME" "cp -a ~/UserLibrary_base/Sets/* ~/UserLibrary_0/Sets/"
        
        print_success "Pages of Sets installed successfully"
    else
        print_status "Skipping Pages of Sets installation"
    fi
}

# Verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    # Check shim
    if ! $SSH_ROOT "test -f $SHIM_PATH"; then
        print_error "Shim installation failed"
        return 1
    fi
    
    # Check Move binary
    if ! $SSH_ROOT "test -f $BINARY_DIR/Move"; then
        print_error "Move binary installation failed"
        return 1
    fi
    
    # Check original backup
    if ! $SSH_ROOT "test -f $BINARY_DIR/MoveOriginal"; then
        print_error "Original Move binary backup failed"
        return 1
    fi
    
    print_success "Installation verification completed"
    
    if [ "$VERBOSE" = true ]; then
        print_status "File checksums:"
        $SSH_ROOT "md5sum $SHIM_PATH $BINARY_DIR/Move $BINARY_DIR/MoveOriginal"
    fi
}

# Start Move with new installation
start_move() {
    print_status "Starting Move with Move Anything..."
    
    $SSH_ABLETON "$USERNAME@$HOSTNAME" "nohup $BINARY_DIR/MoveLauncher 2>/dev/null 1>/dev/null &" &
    
    print_success "Move started successfully"
}

# Show completion message
show_completion() {
    echo ""
    print_header "Installation Complete!"
    echo ""
    print_success "Move Anything has been successfully installed on your Move!"
    echo ""
    print_status "What's next:"
    echo "1. Your Move should restart automatically"
    echo "2. To launch Move Anything, hold Shift + touch Volume knob + Jog wheel"
    echo "3. To return to regular Move software, hold Shift + click Jog wheel"
    echo ""
    
    if [ "$INSTALL_PAGES" = true ]; then
        print_status "Pages of Sets:"
        echo "- Hold Shift + Left/Right arrows to change pages"
        echo "- Visit http://move.local to see Sets from current page"
        echo ""
    fi
    
    print_status "For help and community:"
    echo "- Discord: https://discord.gg/Zn33eRvTyK"
    echo "- GitHub: https://github.com/bobbydigitales/control_surface_move"
    echo ""
    print_warning "Remember: After Move firmware updates, re-run this installer!"
    echo ""
}

# Cleanup function
cleanup() {
    if [ -f "$FILENAME" ] && [ "$DEV_MODE" = false ]; then
        print_status "Cleaning up downloaded package..."
        rm -f "$FILENAME"
    fi
}

# Main installation function
main() {
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Parse arguments
    parse_args "$@"
    
    # Show banner
    show_banner
    
    # Check dependencies
    check_dependencies
    
    # Check network connectivity
    check_network
    
    # Setup SSH if needed
    if [ "$SKIP_SSH" = false ]; then
        if ! check_ssh_access; then
            setup_ssh
        fi
    fi
    
    # Check for existing installation
    check_existing_installation
    
    # Download package
    download_package
    
    # Install package
    install_package
    
    # Install binaries
    install_binaries
    
    # Install Pages of Sets if requested
    install_pages_of_sets
    
    # Verify installation
    verify_installation
    
    # Start Move
    start_move
    
    # Show completion message
    show_completion
}

# Run main function with all arguments
main "$@"
