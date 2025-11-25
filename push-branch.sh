#! /bin/bash

# This script is used to to push the current branch to origin.
# Usage:
#   ./scripts/push-branch.sh <BRANCH_NAME>
#
# For Lerna monorepos:
#   Use the following command to run this script in the root of your Lerna monorepo:
#   npx lerna exec "bash ../../../scripts/push-branch.sh <BRANCH_NAME>"
#   npx lerna exec "bash ../../../scripts/push-branch.sh 81061-open-new-tab"
#
#   This will execute the script in each package directory managed by Lerna.

if [ -z "$1" ]; then
  echo "npx lerna exec \"bash ../../../scripts/push-branch.sh <BRANCH_NAME>\""
  exit 1
fi

BRANCH_NAME=$1

# Get the current branch name
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "Branch to push: $BRANCH_NAME, current branch: $CURRENT_BRANCH"

if [ "$BRANCH_NAME" != "$CURRENT_BRANCH" ]; then
  echo "Not on branch '$BRANCH_NAME', current branch '$CURRENT_BRANCH'."
  exit 0
fi

git push --set-upstream origin $CURRENT_BRANCH --no-verify
if [ $? -ne 0 ]; then
  echo "Failed to push changes."
  exit 1
fi

echo "Operation completed successfully."
