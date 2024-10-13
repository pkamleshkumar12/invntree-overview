#!/bin/bash

# List of repositories to clone
REPOS=(
    "https://github.com/pkamleshkumar12/invntree-dashboard"
    "https://github.com/pkamleshkumar12/invntree-api-gateway"
    "https://github.com/pkamleshkumar12/invntree-service-registry"
    "https://github.com/pkamleshkumar12/invntree-config-server"
    "https://github.com/pkamleshkumar12/invntree-user-service"
    "https://github.com/pkamleshkumar12/invntree-product-service"
    "https://github.com/pkamleshkumar12/invntree-inventory-service"
    "https://github.com/pkamleshkumar12/invntree-order-service"
    "https://github.com/pkamleshkumar12/invntree-sales-service"
    "https://github.com/pkamleshkumar12/invntree-purchase-service"
    "https://github.com/pkamleshkumar12/invntree-auth-service"
    "https://github.com/pkamleshkumar12/invntree-notification-service"
    "https://github.com/pkamleshkumar12/invntree-reporting-service"
    "https://github.com/pkamleshkumar12/invntree-overview"
)

# Directory to clone repositories into
CLONE_DIR="invntree-projects"

# Create the directory if it doesn't exist
mkdir -p $CLONE_DIR

# Clone each repository
for REPO in "${REPOS[@]}"; do
    REPO_NAME=$(basename $REPO .git)
    if [ -d "$CLONE_DIR/$REPO_NAME" ]; then
        echo "Repository $REPO_NAME already exists. Pulling latest changes..."
        cd "$CLONE_DIR/$REPO_NAME"
        git pull
        cd -
    else
        echo "Cloning $REPO_NAME..."
        git clone $REPO "$CLONE_DIR/$REPO_NAME"
    fi
done

echo "All repositories have been cloned or updated in $CLONE_DIR."

