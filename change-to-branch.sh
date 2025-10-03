#! /bin/bash

# script to checkout a branch if it exists, if not checkout the develop branch
#
# The script should update all branches and checkout the latest version of the specified branch.
# If the branch does not exist, it will default to checking out the 'develop' branch.
#
# Usage:
#   ./change-to-branch.sh <branch-name>
#
# For lerna monorepo, you can use:
#   npx lerna exec "bash ../../../scripts/change-to-branch.sh <branch-name>"
#   npx lerna exec "bash ../../../scripts/change-to-branch.sh develop"
#   npx lerna exec "bash ../../../scripts/change-to-branch.sh 82822-master-data-management-test-definition-scroll-jumps-to-top"
#   npx lerna exec "bash ../../../scripts/change-to-branch.sh 83335-fix-shipment-and-production-reason"
#   npx lerna exec "bash ../../../scripts/change-to-branch.sh 82980-short-reschedule-refactor"
#   npx lerna exec "bash ../../../scripts/change-to-branch.sh 82861-fix-diagram-modal"
#   npx lerna exec "bash ../../../scripts/change-to-branch.sh 82543-customer-order-details-general-improvements"
#   npx lerna exec "bash ../../../scripts/change-to-branch.sh 83769-fix-ordering-after-non-piece"
#   npx lerna exec "bash ../../../scripts/change-to-branch.sh 83030-delete-scheduled"
#   npx lerna exec "bash ../../../scripts/change-to-branch.sh 84091-chemical-formula"

BRANCH=${1:-develop}

# Get the current branch name
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Check if the specified branch exists on remote origin
REMOTE_BRANCH_EXISTS=$(git ls-remote --exit-code --heads origin "$BRANCH" > /dev/null && echo "true" || echo "false")

# Determine the branch to checkout
if [ "$REMOTE_BRANCH_EXISTS" == "true" ]; then
    BRANCH_TO_CHECKOUT="$BRANCH"
else
    echo "Branch '$BRANCH' does not exist on remote. Defaulting to 'develop'."
    BRANCH_TO_CHECKOUT="develop"
fi

HAS_STASH=0

# Exit if the current branch is the same as the branch to checkout
if [ "$CURRENT_BRANCH" == "$BRANCH_TO_CHECKOUT" ]; then
    echo "Already on branch '$BRANCH_TO_CHECKOUT'. No changes needed."
else
  # Stash any changes and checkout the target branch
  echo "Stashing changes and checking out branch '$BRANCH_TO_CHECKOUT'."

  # Stash current changes
  STASH_OUTPUT=$(git stash push -m "Stash before updating")
  echo $STASH_OUTPUT
  # Check if any files were stashed
  if [[ $STASH_OUTPUT != "No local changes"* ]]; then
      HAS_STASH=1
  fi

  git checkout "$BRANCH_TO_CHECKOUT"
fi

git pull --ff origin "$BRANCH_TO_CHECKOUT" || echo "Failed to pull the latest changes for branch '$BRANCH_TO_CHECKOUT'."

# Reapply the stash
if [ "$HAS_STASH" -eq 1 ]; then
  git stash pop || echo "No stash to apply or conflicts occurred while applying the stash."
fi
