#!/usr/bin/env fish

# Prompt user for GitHub Personal Access Token
echo "Enter your GitHub Personal Access Token: "
read -s GH_PAT

# Prompt user for GitHub Username
echo "Enter your GitHub Username: "
read GH_USERNAME

# Encode credentials in base64
set ENCODED_PAT (echo -n "$GH_USERNAME:$GH_PAT" | base64)

# Construct auth JSON string
set AUTH_JSON (echo "{\"auths\":{\"ghcr.io\":{\"username\":\"$GH_USERNAME\",\"password\":\"$GH_PAT\",\"auth\":\"$ENCODED_PAT\"}}}")

# Encode the entire JSON string in base64
set ENCODED_SECRET (echo -n $AUTH_JSON | base64)

# Update the Kubernetes secret
kubectl patch secret ghcr -p="{\"data\":{\".dockerconfigjson\":\"$ENCODED_SECRET\"}}"

echo "Kubernetes secret 'ghcr' has been updated successfully!"
