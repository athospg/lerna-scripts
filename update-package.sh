#! /bin/bash

# This script is used to update a package in a Lerna monorepo.
# Usage:
#   ./update-package.sh "PACKAGE_NAME@VERSION"
#   ./update-package.sh "PACKAGE_NAME@VERSION" OPTIONAL_FLAGS

if [ -z "$1" ]; then
    echo "Usage: $0 \"PACKAGE_NAME@VERSION\""
    exit 1
fi

PACKAGE="$1"

# Optional flags can be passed to npm install
shift # Remove the first argument (PACKAGE) from the list

# Delete package-lock.json if it exists (from root or any package)
if [ -f package-lock.json ]; then
    rm -rf package-lock.json || echo 'Failed to remove package-lock.json'
fi
lerna exec "rm -rf package-lock.json || echo 'Failed to remove package-lock.json in package'"

# Clean npm cache
lerna exec "npm cache clean --force || echo 'Failed to clean npm cache'"

# Update the package in the monorepo
lerna exec "npm install $PACKAGE $@ || echo 'Failed to update package $PACKAGE'"
