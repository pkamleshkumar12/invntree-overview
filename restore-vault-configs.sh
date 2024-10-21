#!/bin/bash

VAULT_ADDR="http://127.0.0.1:8200"

# Check if a token is provided as an argument
if [ $# -eq 1 ]; then
    VAULT_TOKEN="$1"
else
    # Hard-coded token (replace with your actual token if not using argument)
    VAULT_TOKEN="HARDCODED_TOKEN"
fi

# Check if backup directory is provided as an argument
if [ $# -eq 2 ]; then
    BACKUP_DIR="$2"
else
    echo "Please provide the backup directory as the second argument."
    exit 1
fi

# Import enabled secrets engines
echo "Importing secrets engines..."
jq -r 'to_entries[] | "\(.key) \(.value.type)"' "$BACKUP_DIR/secrets_engines.json" | while read -r path type; do
  vault secrets enable -path="$path" "$type"
done

# Import authentication methods
echo "Importing auth methods..."
jq -r 'to_entries[] | "\(.key) \(.value.type)"' "$BACKUP_DIR/auth_methods.json" | while read -r path type; do
  vault auth enable -path="$path" "$type"
done

# Import policies
echo "Importing policies..."
for policy_file in "$BACKUP_DIR"/policy_*.json; do
  policy_name=$(basename "$policy_file" | sed 's/policy_\(.*\)\.json/\1/')
  vault policy write "$policy_name" "$policy_file"
done

# Import secrets from all secret engines
echo "Importing secrets from all secret engines..."
find "$BACKUP_DIR" -type f -name "*.json" | while read -r file; do
  relative_path=${file#"$BACKUP_DIR/"}
  path=$(dirname "$relative_path")
  secret=$(basename "$file" .json)
  if [ "$path" != "." ]; then
    echo "Importing secret: $path/$secret"
    vault kv put "$path/$secret" @"$file"
  fi
done

# Import audit devices
echo "Importing audit devices..."
jq -r 'to_entries[] | "\(.key) \(.value.type)"' "$BACKUP_DIR/audit_devices.json" | while read -r path type; do
  vault audit enable -path="$path" "$type"
done

# Import Vault server configuration (Note: This may not be directly applicable and might require manual intervention)
echo "Importing Vault server configuration..."
echo "Note: Server configuration may require manual review and application."
cat "$BACKUP_DIR/vault_config.json"

echo "All configurations and secrets imported from $BACKUP_DIR directory."
