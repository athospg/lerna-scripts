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
#   npx lerna exec "bash ../../../scripts/change-to-branch.sh 82822-master-data-management-test-definition-scroll-jumps-to-top"
#   npx lerna exec "bash ../../../scripts/change-to-branch.sh 83006-grid-of-coil-PDI-misaligned"

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

# Exit if the current branch is the same as the branch to checkout
if [ "$CURRENT_BRANCH" == "$BRANCH_TO_CHECKOUT" ]; then
    echo "Already on branch '$BRANCH_TO_CHECKOUT'. No changes needed."
    exit 0
fi

# Update all branches and tags
git fetch --prune --all --tags --verbose

# Stash any changes and checkout the target branch
echo "Stashing changes and checking out branch '$BRANCH_TO_CHECKOUT'."
git stash push -m "Stashed changes before switching branches"
git checkout "$BRANCH_TO_CHECKOUT"
git pull --ff origin "$BRANCH_TO_CHECKOUT" || echo "Failed to pull the latest changes for branch '$BRANCH_TO_CHECKOUT'."
