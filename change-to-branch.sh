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

BRANCH=${1:-develop}

# Update all branches and tags
git fetch --prune --all --tags --verbose

# Check if the specified branch exists
if git show-ref --verify --quiet refs/heads/$BRANCH; then
    git checkout $BRANCH
    git pull --ff origin $BRANCH || echo 1
else
    echo "Branch '$BRANCH' does not exist. Checking out 'develop' branch instead."
    git checkout develop
    git pull --ff origin develop || echo 1
fi
