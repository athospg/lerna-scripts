#! /bin/bash

# This script is used to delete a branch in all repos
# Usage:
#   ./delete-branch.sh "<branch-name>"
#
# If the -b option is not provided, it will use the current branch.

if [ -z "$1" ]; then
  echo "Usage: $0 \"<branch-name>\""
  exit 1
fi

BRANCH_NAME="$1"

lerna exec "(git branch --delete --force develop || echo fuu)
         && (git checkout --track -b develop origin/develop || echo fuu)
         && (git branch --delete --force $BRANCH_NAME || echo fuu)"
