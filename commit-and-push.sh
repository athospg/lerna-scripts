#! /bin/bash

# This script is used to commit and push changes to a branch.
# It checks for changes, commits them, and pushes to a new branch.
# Usage:
#   ./commit-and-push.sh "Your commit message"
#   ./commit-and-push.sh "Your commit message" "branch-name"
#
# For Lerna monorepos:
#   Use the following command to run this script in the root of your Lerna monorepo:
#   npx lerna exec "bash ../../../scripts/commit-and-push.sh 'Your commit message'"
#   npx lerna exec "bash ../../../scripts/commit-and-push.sh 'Your commit message' branch-name"
#
# If the -b option is not provided, it will use the current branch.

# Example:
# lerna exec "bash ../../../scripts/commit-and-push.sh 'fix: Transfer scroll' 82822-master-data-management-test-definition-scroll-jumps-to-top"

if [ -z "$1" ]; then
  echo "Usage: $0 'Your commit message' [branch-name]"
  exit 1
fi

COMMIT_MESSAGE="$1"
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
if [ -n "$2" ]; then
  BRANCH_NAME="$2"
fi


# Check for changes
if git diff --quiet && git diff --cached --quiet; then
  # echo "No changes to commit."
  exit 0
fi

echo "Changes detected."

echo "\"$COMMIT_MESSAGE\""
echo "\"$BRANCH_NAME\""

# Create and switch to the new branch if it doesn't exist
if ! git show-ref --verify --quiet refs/heads/"$BRANCH_NAME"; then
  git checkout -b $BRANCH_NAME
else
  git checkout $BRANCH_NAME
fi

# Stage all changes
git add .
if [ $? -ne 0 ]; then
  # echo "No changes to add."
  exit 0
fi

# Commit changes
git commit -m "$COMMIT_MESSAGE"
if [ $? -ne 0 ]; then
  echo "No changes to commit."
  exit 0
fi

# Push changes to the remote branch
git push --set-upstream origin $BRANCH_NAME --no-verify
if [ $? -ne 0 ]; then
  echo "Failed to push changes."
  exit 1
fi

echo "Changes pushed to branch $BRANCH_NAME."
exit 0
