#!/bin/bash

# Upload script for external repositories to send packages to the APT repository
# Usage: ./upload-to-apt-repo.sh <package.deb> [distribution] [component]

set -e

PACKAGE_FILE="$1"
DISTRIBUTION="${2:-stable}"
COMPONENT="${3:-main}"
REPO_OWNER="AdamBirds"
REPO_NAME="adb-apt-repo"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <package.deb> [distribution] [component]"
    echo "  distribution: stable (default) or testing"
    echo "  component: main (default) or contrib"
    echo ""
    echo "Required environment variables:"
    echo "  GITHUB_TOKEN - GitHub personal access token with repo access"
    exit 1
fi

if [ ! -f "$PACKAGE_FILE" ]; then
    echo "Error: Package file '$PACKAGE_FILE' not found"
    exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable is required"
    exit 1
fi

# Check if package file is a .deb
if [[ "$PACKAGE_FILE" != *.deb ]]; then
    echo "Error: File must be a .deb package"
    exit 1
fi

echo "Uploading package: $PACKAGE_FILE"
echo "Distribution: $DISTRIBUTION"
echo "Component: $COMPONENT"
echo "Package size: $(ls -lh "$PACKAGE_FILE" | awk '{print $5}')"

# Get the basename of the package file
PACKAGE_NAME=$(basename "$PACKAGE_FILE")

# URL encode the package name for GitHub API (handle special characters like +)
ENCODED_PACKAGE_NAME=$(echo "$PACKAGE_NAME" | sed 's/+/%2B/g; s/ /%20/g; s/&/%26/g')

# Create a temporary upload URL (using GitHub releases as temporary storage)
UPLOAD_URL="https://uploads.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/assets"

# Create a release for temporary storage
RELEASE_DATA=$(cat <<EOF
{
  "tag_name": "temp-$(date +%s)",
  "name": "Temporary Package Upload",
  "body": "Temporary release for package upload",
  "draft": true,
  "prerelease": true
}
EOF
)

RELEASE_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$RELEASE_DATA" \
  "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases")

RELEASE_ID=$(echo "$RELEASE_RESPONSE" | grep -o '"id": [0-9]*' | head -1 | cut -d' ' -f2)

if [ -z "$RELEASE_ID" ]; then
    echo "Error: Failed to create temporary release"
    echo "Response: $RELEASE_RESPONSE"
    exit 1
fi

echo "Created temporary release ID: $RELEASE_ID"

# Upload the package as a release asset
ASSET_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @"$PACKAGE_FILE" \
  "https://uploads.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/$RELEASE_ID/assets?name=$ENCODED_PACKAGE_NAME")

# More robust URL extraction - try multiple patterns
ASSET_URL=$(echo "$ASSET_RESPONSE" | grep -o '"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)

# Fallback: try a simpler pattern
if [ -z "$ASSET_URL" ]; then
    ASSET_URL=$(echo "$ASSET_RESPONSE" | sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

# Another fallback: construct URL manually if we can find the asset ID
if [ -z "$ASSET_URL" ]; then
    ASSET_ID=$(echo "$ASSET_RESPONSE" | grep -o '"id"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | grep -o '[0-9]*')
    if [ -n "$ASSET_ID" ]; then
        ASSET_URL="https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/temp-$(date +%s)/$PACKAGE_NAME"
        echo "Warning: Constructed download URL from asset ID: $ASSET_ID"
    fi
fi

if [ -z "$ASSET_URL" ]; then
    echo "Error: Failed to extract download URL from upload response"
    echo "Response (first 500 chars): $(echo "$ASSET_RESPONSE" | head -c 500)..."
    echo "Trying alternative approach..."
    
    # Alternative: Get the download URL from the releases API
    ASSET_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/$RELEASE_ID/assets"
    DOWNLOAD_URL=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$ASSET_URL" | \
        grep -o '"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]*"' | \
        grep "$PACKAGE_NAME" | cut -d'"' -f4 | head -1)
    
    if [ -n "$DOWNLOAD_URL" ]; then
        ASSET_URL="$DOWNLOAD_URL"
        echo "Successfully retrieved download URL via releases API"
    else
        echo "Failed to get download URL via releases API as well"
        exit 1
    fi
fi

echo "Package uploaded to: $ASSET_URL"

# Trigger the repository dispatch event
DISPATCH_DATA=$(cat <<EOF
{
  "event_type": "upload-package",
  "client_payload": {
    "package_url": "$ASSET_URL",
    "package_name": "$PACKAGE_NAME",
    "distribution": "$DISTRIBUTION",
    "component": "$COMPONENT",
    "sender": "$GITHUB_ACTOR"
  }
}
EOF
)

DISPATCH_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Content-Type: application/json" \
  -d "$DISPATCH_DATA" \
  "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/dispatches")

# Check if dispatch was successful
HTTP_CODE=$(echo "$DISPATCH_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
DISPATCH_BODY=$(echo "$DISPATCH_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$HTTP_CODE" = "204" ]; then
    echo "✅ Package upload initiated successfully!"
    echo "The package will be processed and added to the repository automatically."
    echo ""
    echo "You can monitor the progress at:"
    echo "https://github.com/$REPO_OWNER/$REPO_NAME/actions"
else
    echo "⚠️  Repository dispatch may have failed (HTTP $HTTP_CODE)"
    if [ -n "$DISPATCH_BODY" ]; then
        echo "Response: $DISPATCH_BODY"
    fi
    echo "Check the Actions tab to see if the workflow was triggered:"
    echo "https://github.com/$REPO_OWNER/$REPO_NAME/actions"
fi

# Clean up the temporary release after a delay (in background)
(
  sleep 300  # Wait 5 minutes
  curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -X DELETE \
    "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/$RELEASE_ID" > /dev/null
) &
