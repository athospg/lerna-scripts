#! /bin/bash

# This script is used to commit and push changes to a branch.
# It checks for changes, commits them, and pushes to a new branch.
#
# Usage:
#   ./commit-and-push.sh "Your commit message"
#   ./commit-and-push.sh "Your commit message" --ignore-web-app
#   ./commit-and-push.sh "Your commit message" "branch-name"
#   ./commit-and-push.sh "Your commit message" "branch-name" --ignore-web-app
#   ./commit-and-push.sh "Your commit message" "branch-name" --no-push
#   ./commit-and-push.sh "Your commit message" "branch-name" --no-push --ignore-web-app
#
# For Lerna monorepos:
#   Use the following command to run this script in the root of your Lerna monorepo:
#   npx lerna exec "bash ../../../scripts/commit-and-push.sh 'Your commit message'"
#   npx lerna exec "bash ../../../scripts/commit-and-push.sh 'Your commit message' branch-name"
#
# If the branch name is not provided, it will use the current branch.
#
# Examples:
#   lerna exec "bash ../../../scripts/commit-and-push.sh '82822: fix: Transfer scroll' 82822-master-data-management-test-definition-scroll-jumps-to-top"
#   lerna exec "bash ../../../scripts/commit-and-push.sh '82980: fix: short reschedule refactor' 82980-short-reschedule-refactor"
#   lerna exec "bash ../../../scripts/commit-and-push.sh '82861: fix: diagram modal' 82861-fix-diagram-modal"
#   lerna exec "bash ../../../scripts/commit-and-push.sh '82543: feat: customer order details general improvements' 82543-customer-order-details-general-improvements --ignore-web-app"
#   lerna exec "bash ../../../scripts/commit-and-push.sh '83807: fix: order management missing code to open details' 83807-order-management-missing-code --ignore-web-app"
#   lerna exec "bash ../../../scripts/commit-and-push.sh '84091: feat: add chemical formula construction and usage components' 84091-chemical-formula --ignore-web-app"
#   lerna exec "bash ../../../scripts/commit-and-push.sh '84670: feat: add chemical formula component' 84670-formula-expression-menu --ignore-web-app"
#   lerna exec "bash ../../../scripts/commit-and-push.sh '82861: fix: diagram modal (again)' 82861-fix-diagram-modal --ignore-web-app"
#   lerna exec "bash ../../../scripts/commit-and-push.sh '84987: feat: add chemical formula \"readonly\" and \"remove last part\"' 84987-chemical-formula --ignore-web-app"
#   lerna exec "bash ../../../scripts/commit-and-push.sh '83673: fix: diagram popover out off bounds' 83673-diagram-popover-out-of-bounds --ignore-web-app"
#   lerna exec "bash ../../../scripts/commit-and-push.sh '85268: fix: predicate editor i18n' 85268-predicate-editor-i18n"
#   lerna exec "bash ../../../scripts/commit-and-push.sh '85580: fix: setting minimatch version to ignore * from some dependencies' 85580-minimatch-fix"
#   lerna exec "bash ../../../scripts/commit-and-push.sh '81061: fix: links not opening new tabs' 81061-open-new-tab"
#   lerna exec "bash ../../../scripts/commit-and-push.sh '85247: fix: Master Data - field data cleared' 85247-field-data-cleared --ignore-web-app"
#   lerna exec "bash ../../../scripts/commit-and-push.sh '85913: feat: wip edges component' 85913-relationship-details --no-push"
#   lerna exec "bash ../../../scripts/commit-and-push.sh '85083: fix: Master Data - lookup table - delay when typing in edit mode' 85083-lookup-delay"
#   lerna exec "bash ../../../scripts/commit-and-push.sh '86357: fix: Master Data - lookup table - delete edited data when new line is added' 86357-lookup-new-line"
#   lerna exec "bash ../../../scripts/commit-and-push.sh '92143: feat: Material Management - Implement New Plasma Main DataGrid' 92143-live-data"

if [ -z "$1" ]; then
  echo "Usage: $0 'Your commit message' [branch-name]"
  exit 1
fi

COMMIT_MESSAGE="$1"
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
if [ ! -z "$2" ] && [[ "$2" != --* ]]; then
  BRANCH_NAME="$2"
fi

IGNORE_WEB_APP=false
NO_PUSH=false
for arg in "$@"; do
  if [ "$arg" == "--ignore-web-app" ]; then
    IGNORE_WEB_APP=true
  fi
  if [ "$arg" == "--no-push" ]; then
    NO_PUSH=true
  fi
done

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
git commit -m "$COMMIT_MESSAGE" --no-verify
if [ $? -ne 0 ]; then
  echo "No changes to commit."
  exit 0
fi

# Push changes to the remote branch if --no-push is not set
if [ "$NO_PUSH" = false ]; then
  git push --set-upstream origin $BRANCH_NAME --no-verify
  if [ $? -ne 0 ]; then
    echo "Failed to push changes."
    exit 1
  fi

  echo "Changes pushed to branch $BRANCH_NAME."
else
  echo "Skipping push as --no-push flag is set."
fi

exit 0
