#!/bin/bash

# Default SFTP Configuration
HOST="localhost"          # Default host
USER="ubuntu"               # Default username
PORT=22                   # Default port
IDENTITY_FILE="$HOME/.ssh/id_rsa" # Default identity file
LOCAL_PATH=""             # Default local file or directory path
REMOTE_PATH=""            # Default remote file path or directory
FILENAME_PATTERN="*"      # Default filename pattern (matches all files)

# LOGFILE PATH WITH DATE TIME
LOGFILE="sftp_transfer_$(date +'%Y-%m-%d_%H-%M-%S').log"
# Function to display help message
usage() {
    echo "Usage: $0 -h <host> -u <user> -p <port> -i <identity_file> -f <local_file_or_directory> -r <remote_file_path_or_directory> [-t <filename_pattern>]"
    exit 1
}

# Function to check if a file or directory exists
check_path_exists() {
    local path=$1
    if [[ ! -e $path ]]; then
        echo "Error: Path '$path' does not exist."
        exit 1
    fi
}

# Parse command-line arguments
parse_arguments() {
    while getopts "h:u:p:i:f:r:t:" opt; do
        case $opt in
            h) HOST=$OPTARG ;;
            u) USER=$OPTARG ;;
            p) PORT=$OPTARG ;;
            i) IDENTITY_FILE=$OPTARG ;;
            f) LOCAL_PATH=$OPTARG ;;
            r) REMOTE_PATH=$OPTARG ;;
            t) FILENAME_PATTERN=$OPTARG ;;
            *) usage ;;
        esac
    done

    # Ensure required arguments are provided
    if [[ -z $LOCAL_PATH || -z $REMOTE_PATH ]]; then
        echo "Error: Missing required arguments."
        usage
    fi

    # Ensure FILENAME_PATTERN is provided if LOCAL_PATH is a directory
    if [[ -d $LOCAL_PATH && -z $FILENAME_PATTERN ]]; then
        echo "Error: A filename pattern (-t) is required when the local path is a directory."
        usage
    fi
}

transfer_files() {
    sftp -i "$IDENTITY_FILE" -oPort="$PORT" "$USER@$HOST" <<EOF | tee -a "$LOGFILE"
lcd "$LOCAL_PATH"
echo "Files to copy"
!ls $FILENAME_PATTERN
cd "$REMOTE_PATH"
echo "Current Files (Before transfer)"
ls -la $REMOTE_PATH
$(if [[ -d $LOCAL_PATH ]]; then echo "mput $FILENAME_PATTERN"; else echo "put $LOCAL_PATH"; fi)
echo "Current Files (After Transfer)"
ls -la $REMOTE_PATH
EOF
}

# Main script
main() {
    parse_arguments "$@"
    echo "Arguments Validated" | tee -a "$LOGFILE"

    check_path_exists "$LOCAL_PATH"
    echo "Checked Local Path"| tee -a "$LOGFILE"
    echo "Starting file transfer..." | tee -a "$LOGFILE"
    # Transfer the files
    transfer_files "$@"
    if [[ $? -eq 0 ]]; then
        echo "SFTP transfer completed successfully. Logs saved to $LOGFILE." | tee -a "$LOGFILE"
    else
        echo "SFTP transfer failed. Check $LOGFILE for details." | tee -a "$LOGFILE"
    fi

}

# Entry point
main "$@"
