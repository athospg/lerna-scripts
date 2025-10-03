#! /bin/bash

# This script is used to commit and push changes to a branch.
# It checks for changes, commits them, and pushes to a new branch.
#
# Usage:
#   ./commit-and-push.sh "Your commit message"
#   ./commit-and-push.sh "Your commit message" --ignore-web-app
#   ./commit-and-push.sh "Your commit message" "branch-name"
#   ./commit-and-push.sh "Your commit message" "branch-name" --ignore-web-app
#
# For Lerna monorepos:
#   Use the following command to run this script in the root of your Lerna monorepo:
#   npx lerna exec "bash ../../../scripts/commit-and-push.sh 'Your commit message'"
#   npx lerna exec "bash ../../../scripts/commit-and-push.sh 'Your commit message' branch-name"
#
# If the -b option is not provided, it will use the current branch.

# Example:
# lerna exec "bash ../../../scripts/commit-and-push.sh 'fix: Transfer scroll' 82822-master-data-management-test-definition-scroll-jumps-to-top"
# lerna exec "bash ../../../scripts/commit-and-push.sh 'fix: short reschedule refactor' 82980-short-reschedule-refactor"
# lerna exec "bash ../../../scripts/commit-and-push.sh 'fix: diagram modal' 82861-fix-diagram-modal"
# lerna exec "bash ../../../scripts/commit-and-push.sh 'feat: customer order details general improvements' 82543-customer-order-details-general-improvements --ignore-web-app"
# lerna exec "bash ../../../scripts/commit-and-push.sh 'fix: order management missing code to open details' 83807-order-management-missing-code --ignore-web-app"

if [ -z "$1" ]; then
  echo "Usage: $0 'Your commit message' [branch-name]"
  exit 1
fi

COMMIT_MESSAGE="$1"
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
if [ ! -z "$2" ] && [ "$2" != "--ignore-web-app" ]; then
  BRANCH_NAME="$2"
fi

# check --ignore-web-app and if the current directory is "sms-mes-webapplication-fe-mvp"
IGNORE_WEB_APP=false
if [ "$2" == "--ignore-web-app" ] || [ "$3" == "--ignore-web-app" ]; then
  IGNORE_WEB_APP=true
fi

CURRENT_DIR_NAME=$(basename "$PWD")
if [ "$IGNORE_WEB_APP" = true ] && [ "$CURRENT_DIR_NAME" == "sms-mes-webapplication-fe-mvp" ]; then
  echo "Skipping commit and push in web-app directory."
  exit 0
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
