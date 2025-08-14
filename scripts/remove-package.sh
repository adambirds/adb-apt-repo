#!/bin/bash

# Script to remove a package from the repository
# Usage: ./remove-package.sh <package-name> [distribution]

set -e

PACKAGE_NAME="$1"
DISTRIBUTION="${2:-stable}"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <package-name> [distribution]"
    echo "  distribution: stable (default) or testing"
    exit 1
fi

echo "Removing package: $PACKAGE_NAME"
echo "Distribution: $DISTRIBUTION"

# Remove package from repository
reprepro remove "$DISTRIBUTION" "$PACKAGE_NAME"

echo "Package removed successfully!"
echo "Repository updated."
