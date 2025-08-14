#!/bin/bash

# Script to generate GPG key for package signing
# Usage: ./generate-gpg-key.sh

set -e

echo "Generating GPG key for APT repository..."

# Check if GPG key already exists
if gpg --list-secret-keys | grep -q "adb-apt-repo"; then
    echo "GPG key for adb-apt-repo already exists!"
    gpg --list-secret-keys | grep -A 5 -B 5 "adb-apt-repo"
    exit 0
fi

# Generate GPG key configuration
cat > /tmp/gpg-key-config <<EOF
%echo Generating GPG key for ADB APT Repository
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: ADB APT Repository
Name-Email: apt-repo@adambirds.dev
Expire-Date: 2y
Passphrase: 
%commit
%echo GPG key generation complete
EOF

# Generate the key
gpg --batch --generate-key /tmp/gpg-key-config

# Clean up
rm /tmp/gpg-key-config

echo "GPG key generated successfully!"
echo "Exporting public key..."

# Export public key
gpg --armor --export "ADB APT Repository" > pubkey.gpg

echo "Public key exported to pubkey.gpg"
echo "You should commit this file to the repository."

# Show key info
echo "Key information:"
gpg --list-keys "ADB APT Repository"
