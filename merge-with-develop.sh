#! /bin/bash

# This script is used to fetch all changes from origin and merge origin/develop into the current branch.
# If the current branch is 'develop', it stashes changes, pulls updates, and reapplies the stash.
# If the current branch is not 'develop', it attempts to merge 'develop' into it, leaving conflicts for the user to resolve.
# Usage:
#   ./scripts/merge-with-develop.sh "COMMIT_MESSAGE"
#
# For Lerna monorepos:
#   Use the following command to run this script in the root of your Lerna monorepo:
#   npx lerna exec "bash ../../../scripts/merge-with-develop.sh 'COMMIT_MESSAGE'"
#   npx lerna exec "bash ../../../scripts/merge-with-develop.sh '82980: fix: short reschedule refactor'"
#   npx lerna exec "bash ../../../scripts/merge-with-develop.sh '82861: fix: diagram modal'"
#
#   This will execute the script in each package directory managed by Lerna.

if [ -z "$1" ]; then
  echo "npx lerna exec \"bash ../../../scripts/merge-with-develop.sh 'COMMIT_MESSAGE'\""
  exit 1
fi

# Get the current branch name
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Fetch all changes
git fetch --prune --all --tags --verbose || { echo "Failed to fetch changes"; exit 1; }

HAS_STASH=0
# Stash current changes
STASH_OUTPUT=$(git stash push -m "Stash before updating")
echo $STASH_OUTPUT
# Check if any files were stashed
if [[ $STASH_OUTPUT != "No local changes"* ]]; then
    HAS_STASH=1
fi

if [ "$CURRENT_BRANCH" == "develop" ]; then
  echo "You are on the 'develop' branch. Stashing changes, pulling updates, and reapplying the stash."

  # Pull changes from origin/develop
  git merge --ff-only origin/develop || { echo "Failed to pull changes from origin/develop"; exit 1; }
else
  echo "You are on branch '$CURRENT_BRANCH'. Attempting to stash changes and merge 'develop' into it."

  # Attempt to merge 'develop' into the current branch
  git merge origin/develop -m "$1"

  # Check if there are merge conflicts
  if [ $? -ne 0 ]; then
    echo "Merge conflicts detected. Please resolve them manually and complete the merge."
    exit 1
  fi

  git push --set-upstream origin $CURRENT_BRANCH --no-verify
  if [ $? -ne 0 ]; then
    echo "Failed to push changes."
    exit 1
  fi
fi

# Reapply the stash
if [ "$HAS_STASH" -eq 1 ]; then
  git stash pop || echo "No stash to apply or conflicts occurred while applying the stash."
fi

echo "Operation completed successfully."
