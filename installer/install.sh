#!/usr/bin/env bash

# Move Anything Installer

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

# SSH commands
SSH_ABLETON_NO_CHECK="ssh -o LogLevel=QUIET -o ConnectTimeout=10 -o StrictHostKeyChecking=no"
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

check_dependencies() {
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

check_network() {
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

check_ssh_access() {
    if $SSH_ABLETON_NO_CHECK "$USERNAME@$HOSTNAME" "echo 'SSH test successful'" &> /dev/null; then
        print_success "SSH access confirmed"
        return 0
    else
        print_warning "SSH access not available"
        return 1
    fi
}

# Generate SSH key if needed
generate_ssh_key() {
    local key_path="$HOME/.ssh/id_ed25519"
    
    if [ -f "$key_path" ]; then
        print_status "SSH key already exists: $key_path"
        return 0
    fi
    
    print_status "Generating SSH key..."
    if ssh-keygen -t ed25519 -f "$key_path" -N "" -C "ableton-move-$(date +%Y%m%d)"; then
        print_success "SSH key generated successfully"
        return 0
    else
        print_error "Failed to generate SSH key"
        return 1
    fi
}

# Get SSH public key
get_ssh_public_key() {
    local key_path="$HOME/.ssh/id_ed25519.pub"
    
    if [ -f "$key_path" ]; then
        cat "$key_path"
        return 0
    fi
    
    # Try RSA key as fallback
    key_path="$HOME/.ssh/id_rsa.pub"
    if [ -f "$key_path" ]; then
        cat "$key_path"
        return 0
    fi
    
    return 1
}

# Setup SSH access
setup_ssh() {
    print_header "SSH Setup Required"
    echo ""
    print_status "SSH access is required to install Move Anything."
    echo ""
    
    # Generate SSH key if needed
    if ! generate_ssh_key; then
        print_error "Could not generate SSH key automatically"
        echo ""
        print_warning "Please generate an SSH key manually:"
        echo "   ssh-keygen -t ed25519 -C \"your_email@example.com\""
        echo ""
        read -p "Press Enter when you've generated your SSH key, or Ctrl+C to exit..."
    fi
    
    # Get the public key
    local public_key
    if ! public_key=$(get_ssh_public_key); then
        print_error "Could not find SSH public key"
        print_warning "Please check that your SSH key exists at:"
        echo "   ~/.ssh/id_ed25519.pub (or ~/.ssh/id_rsa.pub)"
        exit 1
    fi
    
    echo ""
    print_status "Your SSH public key:"
    echo "----------------------------------------"
    echo "$public_key"
    echo "----------------------------------------"
    echo ""
    
    print_warning "To complete SSH setup:"
    echo "1. Open your web browser"
    echo "2. Go to: http://$HOSTNAME/development/ssh"
    echo "3. Copy and paste the public key above"
    echo "4. Click 'Add Key'"
    echo ""
    
    # Try to open the browser automatically
    if command -v open &> /dev/null; then
        print_status "Attempting to open SSH setup page in your browser..."
        if open "http://$HOSTNAME/development/ssh" 2>/dev/null; then
            print_success "SSH setup page opened in browser"
        fi
    elif command -v xdg-open &> /dev/null; then
        print_status "Attempting to open SSH setup page in your browser..."
        if xdg-open "http://$HOSTNAME/development/ssh" 2>/dev/null; then
            print_success "SSH setup page opened in browser"
        fi
    fi
    
    echo ""
    read -p "Press Enter when you've added your SSH key, or Ctrl+C to exit..."
    
    if $SSH_ABLETON_NO_CHECK "$USERNAME@$HOSTNAME" "echo 'SSH test successful'" &> /dev/null; then
        print_success "SSH setup completed successfully!"
    else
        print_error "SSH setup failed. Please check your configuration."
        echo ""
        print_warning "Common SSH issues and solutions:"
        echo ""
        print_status "1. Host key verification failed:"
        echo "   - Run: ssh-keygen -R $HOSTNAME"
        echo "   - Or edit ~/.ssh/known_hosts and remove the line for $HOSTNAME"
        echo ""
        print_status "2. Permission denied (publickey):"
        echo "   - Make sure you copied the entire public key"
        echo "   - Check that the key doesn't have extra spaces or newlines"
        echo "   - Verify the key was added correctly at http://$HOSTNAME/development/ssh"
        echo ""
        print_status "3. Connection refused:"
        echo "   - Make sure SSH is enabled on your Move"
        echo "   - Check that your Move and computer are on the same network"
        echo "   - Try accessing http://$HOSTNAME in your browser"
        echo ""
        print_status "4. Other issues:"
        echo "   - Try running: ssh $USERNAME@$HOSTNAME"
        echo "   - Check Move's network settings"
        echo "   - Restart your Move if needed"
        echo ""
        exit 1
    fi
}

check_existing_installation() {
    if $SSH_ABLETON_NO_CHECK "$USERNAME@$HOSTNAME" "test -f $SHIM_PATH" &> /dev/null; then
        print_warning "Move Anything appears to be already installed"
        
        if [ "$FORCE_OVERWRITE" = true ]; then
            print_status "Force overwrite enabled - proceeding with installation"
            return 0
        fi
        
        echo ""
        while true; do
            read -p "Continue with installation? [y/N]: " yn
            case $yn in
                [Yy]*)
                    return 0
                    ;;
                [Nn]*|"")
                    print_status "Installation cancelled"
                    exit 0
                    ;;
                *)
                    print_error "Please answer yes or no."
                    ;;
            esac
        done
    fi
}

download_package() {
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

install_package() {
    if ! scp -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$FILENAME" "$USERNAME@$HOSTNAME:."; then
        print_error "Failed to upload package"
        print_warning "This might be due to SSH host key verification issues."
        echo ""
        print_status "If you see a 'REMOTE HOST IDENTIFICATION HAS CHANGED' error:"
        echo "1. The Move's SSH host key has changed (common after firmware updates)"
        echo "2. Remove the old host key: ssh-keygen -R $HOSTNAME"
        echo "3. Or remove the specific line from ~/.ssh/known_hosts"
        echo "4. Then run this installer again"
        echo ""
        print_status "If you see other SSH errors:"
        echo "1. Make sure SSH is enabled on your Move"
        echo "2. Check that your SSH key is properly configured"
        echo "3. Try running: ssh $USERNAME@$HOSTNAME"
        echo ""
        exit 1
    fi
    
    print_success "Package uploaded successfully"
    
    if ! $SSH_ABLETON_NO_CHECK "$USERNAME@$HOSTNAME" "tar -xvf ./$FILENAME"; then
        print_error "Failed to extract package"
        exit 1
    fi
    
    print_success "Package extracted successfully"
}

install_binaries() {
    $SSH_ABLETON_NO_CHECK "$USERNAME@$HOSTNAME" "killall MoveLauncher Move MoveOriginal 2>/dev/null || true"
    
    $SSH_ROOT "cp -f $INSTALL_DIR/control_surface_move_shim.so $SHIM_PATH"
    $SSH_ROOT "chmod u+s $SHIM_PATH"
    
    if ! $SSH_ROOT "test -f $BINARY_DIR/MoveOriginal"; then
        $SSH_ROOT "mv $BINARY_DIR/Move $BINARY_DIR/MoveOriginal"
        $SSH_ABLETON_NO_CHECK "$USERNAME@$HOSTNAME" "cp $BINARY_DIR/MoveOriginal ~/"
        print_success "Original Move binary backed up"
    fi
    
    $SSH_ROOT "chmod +x $INSTALL_DIR/Move.sh"
    $SSH_ROOT "cp $INSTALL_DIR/Move.sh $BINARY_DIR/Move"
    
    print_success "Binary installation completed"
}

install_pages_of_sets() {
    if $SSH_ABLETON_NO_CHECK "$USERNAME@$HOSTNAME" "test -L ~/UserLibrary"; then
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
        $SSH_ABLETON_NO_CHECK "$USERNAME@$HOSTNAME" "mv ~/UserLibrary ~/UserLibrary_base"
        $SSH_ABLETON_NO_CHECK "$USERNAME@$HOSTNAME" "$INSTALL_DIR/changePage.sh 0 skipLaunch"
        $SSH_ABLETON_NO_CHECK "$USERNAME@$HOSTNAME" "cp -a ~/UserLibrary_base/Sets/* ~/UserLibrary_0/Sets/"
        
        print_success "Pages of Sets installed successfully"
    else
        print_status "Skipping Pages of Sets installation"
    fi
}

verify_installation() {
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

start_move() {
    $SSH_ABLETON_NO_CHECK "$USERNAME@$HOSTNAME" "nohup $BINARY_DIR/MoveLauncher 2>/dev/null 1>/dev/null &" &
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
    echo "- GitHub: https://github.com/bobbydigitales/move-anything"
    echo ""
    print_warning "Remember: After Move firmware updates, re-run this installer!"
    echo ""
}

cleanup() {
    if [ -f "$FILENAME" ] && [ "$DEV_MODE" = false ]; then
        rm -f "$FILENAME"
    fi
}

main() {
    trap cleanup EXIT
    
    parse_args "$@"
    show_banner
    check_dependencies
    check_network
    
    if [ "$SKIP_SSH" = false ]; then
        if ! check_ssh_access; then
            setup_ssh
        fi
    fi
    
    check_existing_installation
    download_package
    install_package
    install_binaries
    install_pages_of_sets
    verify_installation
    start_move
    show_completion
}

main "$@"
