#!/bin/bash

VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_ADDR

# Check if a token is provided as an argument
if [ $# -eq 1 ]; then
    VAULT_TOKEN="$1"
else
    # Hard-coded token -replace with new token in argument
    VAULT_TOKEN="HARDCODED_TOKEN"
fi

# Export VAULT_TOKEN
export VAULT_TOKEN

# Attempt to log in and verify the token
if ! vault token lookup >/dev/null 2>&1; then
    echo "Failed to authenticate with Vault. Please check your token."
    exit 1
fi

echo "Successfully authenticated with Vault."

# Create backups directory
BACKUP_DIR="backups/vault_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Export enabled secrets engines
echo "Exporting enabled secrets engines..."
vault secrets list -format=json > "$BACKUP_DIR/secrets_engines.json"

# Export authentication methods
echo "Exporting enabled auth methods..."
vault auth list -format=json > "$BACKUP_DIR/auth_methods.json"

# Export policies
echo "Exporting policies..."
vault policy list | while read -r policy; do
  vault policy read -format=json "$policy" > "$BACKUP_DIR/policy_$policy.json"
done

# Export secrets from all secret engines
echo "Exporting secrets from all secret engines..."
# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install jq to continue."
    echo "On most systems, you can install it using your package manager."
    echo "For example: sudo apt-get install jq (for Ubuntu/Debian)"
    echo "or: brew install jq (for macOS with Homebrew)"
    exit 1
fi

# Export secrets from all secret engines
vault secrets list -format=json | jq -r 'to_entries[] | select(.value.type != "system") | .key' | while read -r path; do
  echo "Exporting secrets from path: $path"
  mkdir -p "$BACKUP_DIR/${path%/}"
  if [[ "$path" == kv/* ]]; then
    vault kv list -format=json "$path" 2>/dev/null | jq -r '.[]' | while read -r secret; do
      vault kv get -format=json "$path$secret" > "$BACKUP_DIR/${path%/}/${secret}.json"
    done
  else
    vault list -format=json "$path" 2>/dev/null | jq -r '.[]' | while read -r secret; do
      vault read -format=json "$path$secret" > "$BACKUP_DIR/${path%/}/${secret}.json"
    done
  fi
done

# Check if audit devices can be accessed
if ! vault audit list &> /dev/null; then
    echo "Warning: Unable to access audit devices. Your policy may not have the necessary permissions."
    echo "Please ensure your token has the 'read' capability on the 'sys/audit' path."
else
    echo "Exporting audit devices..."
    vault audit list -format=json > "$BACKUP_DIR/audit_devices.json"
fi

# Export audit devices
echo "Exporting audit devices..."
vault audit list -format=json > "$BACKUP_DIR/audit_devices.json"

# Export Vault server configuration
echo "Exporting Vault server configuration..."
vault read -format=json sys/config/state > "$BACKUP_DIR/vault_config.json"

echo "All configurations and secrets exported to $BACKUP_DIR directory."
