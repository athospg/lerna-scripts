#! /bin/bash

# This script is used to delete a branch in all repos
# Usage:
#   ./delete-branch.sh "<branch-name>"
#   ./delete-branch.sh "<branch-name>" -r
#
# If the -b option is not provided, it will use the current branch.
#
# Examples:
#   npx lerna exec "bash ../../../scripts/delete-branch.sh 81061-open-new-tab"

if [ -z "$1" ]; then
  echo "Usage: $0 \"<branch-name>\""
  exit 1
fi

BRANCH_NAME="$1"

DELETE_REMOTE=false
for arg in "$@"; do
  if [ "$arg" == "-r" ]; then
    DELETE_REMOTE=true
  fi
done

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Check if the branch does not exist locally
BRANCH_EXISTS=$(git branch --list "$BRANCH_NAME")
if [ -z "$BRANCH_EXISTS" ]; then
  exit 0
fi

# If the current branch is the same as the branch to be deleted, switch to develop
if [ "$CURRENT_BRANCH" == "$BRANCH_NAME" ]; then
  git checkout develop
fi

# Delete the branch locally
git branch -D "$BRANCH_NAME"

# Delete the branch remotely
if [ "$DELETE_REMOTE" == true ]; then
  git push origin --delete "$BRANCH_NAME" --no-verify
fi
