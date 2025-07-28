#! /bin/bash

# This script is used to fetch all changes from origin and merge origin/develop into the current branch.
# It uses Lerna to execute the commands in each package.
# Usage:
#   ./scripts/merge-with-develop.sh "COMMIT_MESSAGE"

if [ -z "$1" ]; then
  echo "Usage: $0 \"COMMIT_MESSAGE\""
  exit 1
fi

# Fetch all changes from origin
lerna exec "git fetch --prune origin --tags --verbose || echo 'Failed to fetch changes from origin'"

# Merge origin/develop into the current branch, fasting forward if possible
lerna exec "git merge origin/develop -m '$1' || echo 'Failed to merge origin/develop into the current branch'"

# Push the changes to the remote repository
# lerna exec "git push --set-upstream origin HEAD --no-verify || echo 'Failed to push changes to the remote repository'"
