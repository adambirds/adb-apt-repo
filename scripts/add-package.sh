#!/bin/bash

# Script to add a package to the repository
# Usage: ./add-package.sh <package.deb> [distribution] [component]

set -e

PACKAGE_FILE="$1"
DISTRIBUTION="${2:-stable}"
COMPONENT="${3:-main}"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <package.deb> [distribution] [component]"
    echo "  distribution: stable (default) or testing"
    echo "  component: main (default) or contrib"
    exit 1
fi

if [ ! -f "$PACKAGE_FILE" ]; then
    echo "Error: Package file '$PACKAGE_FILE' not found"
    exit 1
fi

# Check if package file is a .deb
if [[ "$PACKAGE_FILE" != *.deb ]]; then
    echo "Error: File must be a .deb package"
    exit 1
fi

echo "Adding package: $PACKAGE_FILE"
echo "Distribution: $DISTRIBUTION"
echo "Component: $COMPONENT"

# Add package to repository
reprepro includedeb "$DISTRIBUTION" "$PACKAGE_FILE"

echo "Package added successfully!"
echo "Repository updated."
