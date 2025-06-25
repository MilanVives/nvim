#!/bin/bash

# Installation Menu Script
# This script provides a menu interface to run various installation scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_menu() {
    clear
    echo "========================================="
    echo "        Installation Menu"
    echo "========================================="
    echo "1) Install Neovim (Ubuntu)"
    echo "2) Install Docker (Ubuntu)"
    echo "3) Install Neovim (Mac ARM)"
    echo "4) Install Neovim (Mac x86)"
    echo "5) Install Neovim (Mac Brew)"
    echo "6) Deploy SSH Keys from keys.txt"
    echo "7) Exit"
    echo "========================================="
    echo -n "Please select an option [1-7]: "
}

deploy_ssh_keys() {
    local keys_file="$SCRIPT_DIR/keys.txt"
    
    if [[ ! -f "$keys_file" ]]; then
        echo "Error: keys.txt file not found in $SCRIPT_DIR"
        echo "Please create a keys.txt file with SSH public keys (one per line)"
        return 1
    fi
    
    echo "Deploying SSH keys from $keys_file..."
    
    # Create .ssh directory if it doesn't exist
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # Backup existing authorized_keys if it exists
    if [[ -f ~/.ssh/authorized_keys ]]; then
        cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.backup.$(date +%Y%m%d_%H%M%S)
        echo "Backed up existing authorized_keys file"
    fi
    
    # Read the file and process keys with their comments
    local count=0
    local last_comment=""
    local line_num=0
    
    while IFS= read -r line; do
        ((line_num++))
        
        # Check if line is a comment
        if [[ "$line" =~ ^[[:space:]]*#.*$ ]]; then
            last_comment="$line"
            continue
        fi
        
        # Skip empty lines
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*$ ]]; then
            last_comment=""
            continue
        fi
        
        # This line should be a key
        local key="$line"
        
        # Check if key is already in authorized_keys (check the actual key part, not the comment)
        if ! grep -Fq "$key" ~/.ssh/authorized_keys 2>/dev/null; then
            # Add comment if we have one
            if [[ -n "$last_comment" ]]; then
                echo "$last_comment" >> ~/.ssh/authorized_keys
                echo "Added comment: $last_comment"
            fi
            
            # Add the key
            echo "$key" >> ~/.ssh/authorized_keys
            ((count++))
            echo "Added key: ${key:0:50}..."
        else
            echo "Key already exists (skipping): ${key:0:50}..."
        fi
        
        # Reset comment for next iteration
        last_comment=""
        
    done < "$keys_file"
    
    # Set correct permissions
    chmod 600 ~/.ssh/authorized_keys
    
    echo "Deployment complete! Added $count new SSH keys."
    echo "Total lines in authorized_keys: $(wc -l < ~/.ssh/authorized_keys)"
}

run_script() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/$script_name"
    
    if [[ ! -f "$script_path" ]]; then
        echo "Error: Script $script_name not found in $SCRIPT_DIR"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        echo "Making script executable..."
        chmod +x "$script_path"
    fi
    
    echo "Running $script_name..."
    echo "========================================="
    bash "$script_path"
    local exit_code=$?
    echo "========================================="
    
    if [[ $exit_code -eq 0 ]]; then
        echo "Script completed successfully!"
    else
        echo "Script failed with exit code: $exit_code"
    fi
    
    return $exit_code
}

main() {
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1)
                echo
                run_script "install-ubuntu.sh"
                ;;
            2)
                echo
                run_script "docker-ubuntu.sh"
                ;;
            3)
                echo
                run_script "install-mac-arm.sh"
                ;;
            4)
                echo
                run_script "install-mac-x86.sh"
                ;;
            5)
                echo
                run_script "install-mac-brew.sh"
                ;;
            6)
                echo
                deploy_ssh_keys
                ;;
            7)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid option. Please try again."
                ;;
        esac
        
        echo
        echo "Press Enter to continue..."
        read -r
    done
}

# Run the main function
main "$@"
