#!/bin/bash

# Test script to validate APT repository setup
# Usage: ./test-setup.sh

set -e

echo "=== ADB APT Repository Setup Test ==="
echo

# Check if we're in the right directory
if [ ! -f "conf/distributions" ]; then
    echo "❌ Error: Not in repository root directory"
    echo "   Run this script from the repository root"
    exit 1
fi

echo "✅ Repository structure check passed"

# Check reprepro installation
if ! command -v reprepro &> /dev/null; then
    echo "❌ Error: reprepro is not installed"
    echo "   Install with: sudo apt-get install reprepro"
    exit 1
fi

echo "✅ reprepro installation check passed"

# Check configuration files
echo "📋 Checking configuration files..."

if [ ! -f "conf/distributions" ]; then
    echo "❌ Error: conf/distributions file missing"
    exit 1
fi

if [ ! -f "conf/options" ]; then
    echo "❌ Error: conf/options file missing"
    exit 1
fi

echo "✅ Configuration files check passed"

# Validate distributions file
echo "📋 Validating distributions configuration..."
if ! reprepro check 2>/dev/null; then
    echo "⚠️  Warning: reprepro check failed (this is normal without packages)"
else
    echo "✅ reprepro configuration valid"
fi

# Check script permissions
echo "📋 Checking script permissions..."
for script in scripts/*.sh; do
    if [ -f "$script" ] && [ ! -x "$script" ]; then
        echo "❌ Error: $script is not executable"
        echo "   Fix with: chmod +x $script"
        exit 1
    fi
done

echo "✅ Script permissions check passed"

# Check directory structure
echo "📋 Checking directory structure..."
required_dirs=("conf" "scripts" "incoming" ".github/workflows")
for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "❌ Error: Required directory '$dir' missing"
        exit 1
    fi
done

echo "✅ Directory structure check passed"

# Check for GPG key
echo "📋 Checking GPG setup..."
if gpg --list-secret-keys | grep -q "ADB APT Repository"; then
    echo "✅ GPG key found"
    
    # Check if public key is exported
    if [ -f "pubkey.gpg" ]; then
        echo "✅ Public key exported"
    else
        echo "⚠️  Warning: Public key not exported"
        echo "   Run: ./scripts/generate-gpg-key.sh"
    fi
else
    echo "⚠️  Warning: No GPG key found"
    echo "   Run: ./scripts/generate-gpg-key.sh"
fi

# Check GitHub Actions workflows
echo "📋 Checking GitHub Actions workflows..."
if [ -f ".github/workflows/build-deploy.yml" ]; then
    echo "✅ Build and deploy workflow found"
else
    echo "❌ Error: Build and deploy workflow missing"
    exit 1
fi

if [ -f ".github/workflows/accept-upload.yml" ]; then
    echo "✅ Upload acceptance workflow found"
else
    echo "❌ Error: Upload acceptance workflow missing"
    exit 1
fi

# Test basic reprepro functionality
echo "📋 Testing reprepro functionality..."

# Create test directories
mkdir -p dists pool

# Try to export (should work even with no packages)
if reprepro export >/dev/null 2>&1; then
    echo "✅ reprepro export test passed"
else
    echo "⚠️  Warning: reprepro export failed (may be normal)"
fi

echo
echo "=== Test Summary ==="
echo "✅ Repository setup is ready!"
echo
echo "Next steps:"
echo "1. Generate GPG key if not done: ./scripts/generate-gpg-key.sh"
echo "2. Configure GitHub repository secrets (see SETUP.md)"
echo "3. Enable GitHub Pages in repository settings"
echo "4. Test with a sample package upload"
echo
echo "For detailed setup instructions, see SETUP.md"
