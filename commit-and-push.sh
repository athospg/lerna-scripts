#! /bin/bash

# This script is used to commit and push changes in a Lerna monorepo.
# It checks for changes, commits them, and pushes to a new branch.
# Usage:
#   ./scripts/commit-and-push.sh "Your commit message"
#   ./scripts/commit-and-push.sh "Your commit message" "branch-name"
#   ./scripts/commit-and-push.sh "0000: feat: technical order details drawer" "0000-technical-order-details"
#
# If the -b option is not provided, it will use the current branch.

if [ -z "$1" ]; then
  echo "Usage: $0 \"Your commit message\" <branch-name>"
  exit 1
fi

COMMIT_MESSAGE="$1"
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
if [[ -n "$2" ]]; then
  BRANCH_NAME="$2"
fi

# Checkout to the specified branch or create it if it doesn't exist
lerna exec "git checkout --no-track -b $BRANCH_NAME || echo 'Branch already exists'"

# Add all changes
lerna exec "git add . || echo 'No changes to commit'"

# Commit the changes
lerna exec "git commit -m \"$COMMIT_MESSAGE\" || echo 'No changes to commit'"

# Push the changes to the remote repository
lerna exec "git push --set-upstream origin $BRANCH_NAME --no-verify || echo 'No changes to push'"
