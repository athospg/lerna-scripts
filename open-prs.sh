#! /bin/bash

# This script is used to create a pull request in Azure DevOps using the Azure CLI.
# It requires the Azure CLI to be installed and configured with the appropriate permissions.
#
# It will check all folders in "packages/mes-frontend" and create a pull request for each one that has the branch name provided.
# The repository name is the same as the folder name.
#
# Prerequisites:
#   1. Install the Azure CLI:
#        - Windows: winget install -e --id Microsoft.AzureCLI
#        - macOS:   brew update && brew install azure-cli
#        - Linux:   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
#   2. Sign in to Azure DevOps:
#        az login
#   3. Install the Azure DevOps extension (creates the "az repos" commands):
#        az extension add --name azure-devops
#      Verify the installation with:
#        az extension list
#
# Usage: run this script from the workspace root.
#   bash ./scripts/open-prs.sh <branch_name> <title> <pr-type>
#
#   branch_name: the branch to open the PRs from; it must start with the work item number (e.g. 80771-customer-order-details)
#   title:       a short description; the "[TYPE] - <work-item>: type:" prefix is added automatically
#   pr-type:     one of SYNC, DEPLOY, BUGFIX, FEATURE, HOTFIX, or any custom value
#
# Example:
# bash ./scripts/open-prs.sh 80771-customer-order-details "Adding customer order details drawer" FEATURE
# bash ./scripts/open-prs.sh 81375-customer-order-enum-values "Fixing enum values" BUGFIX
# bash ./scripts/open-prs.sh 84987-chemical-formula "add chemical formula \"readonly\" and \"remove last part\"" FEATURE
# bash ./scripts/open-prs.sh 85083-lookup-delay 'Master Data - lookup table - delay when typing in edit mode' BUGFIX
# bash ./scripts/open-prs.sh 92143-live-data 'Material Management - Implement New Plasma Main DataGrid' FEATURE

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <branch_name> <title> <pr-type>"
    exit 1
fi

BRANCH_NAME=$1
TITLE=$2
PR_TYPE=$3

WORK_ITEM=$(echo "$BRANCH_NAME" | grep -oE '^[0-9]+')
if [ -z "$WORK_ITEM" ]; then
    echo "ERROR: could not extract a work item number from branch '$BRANCH_NAME'." >&2
    echo "Expected a branch starting with digits (e.g. 12345-feature-name)." >&2
    exit 1
fi

PR_TYPE_UPPER=$(echo "$PR_TYPE" | tr '[:lower:]' '[:upper:]')
case "$PR_TYPE_UPPER" in
  "BUGFIX") PR_TYPE_ABBREVIATION="FIX" ;;
  "FEATURE") PR_TYPE_ABBREVIATION="FEAT" ;;
  *) PR_TYPE_ABBREVIATION="$PR_TYPE_UPPER" ;;
esac
TITLE="[${PR_TYPE_ABBREVIATION}] - ${WORK_ITEM}: $(echo "$PR_TYPE_ABBREVIATION" | tr '[:upper:]' '[:lower:]'): ${TITLE}"

VERSION_CHANGE='No'

ORG_URL="https://dev.azure.com/sms-digital"
PROJECT_NAME="CoC Planning"
PR_TYPES=("SYNC" "DEPLOY" "BUGFIX" "FEATURE" "HOTFIX")

# ================================== #
# =========== Validation =========== #
# ================================== #

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve the workspace root: prefer the current directory, then fall back to
# the directory that contains this script.
if [ -d "$PWD/packages/mes-frontend" ]; then
    WORKSPACE_ROOT="$PWD"
elif [ -d "$SCRIPT_DIR/../packages/mes-frontend" ]; then
    WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
else
    echo "ERROR: could not find 'packages/mes-frontend' in '$PWD' nor in '$SCRIPT_DIR/..'." >&2
    echo "Run this script from the workspace root, e.g.: bash ./scripts/open-prs.sh <branch> <title> <pr-type>" >&2
    exit 1
fi
REPO_PATH="$WORKSPACE_ROOT/packages/mes-frontend"

if ! command -v az >/dev/null 2>&1; then
    echo "ERROR: Azure CLI ('az') was not found in PATH." >&2
    exit 1
fi

if [ -z "$(az extension list --query "[?name=='azure-devops'].name" -o tsv 2>/dev/null)" ]; then
    echo "ERROR: the 'azure-devops' Azure CLI extension is not installed." >&2
    echo "Install it with: az extension add --name azure-devops" >&2
    exit 1
fi

echo "Workspace root: $WORKSPACE_ROOT"
echo "Branch:         $BRANCH_NAME"
echo "Title:          $TITLE"
echo ""

# ================================== #
# ========= PR type string ========= #
# ================================== #


IS_PR_TYPE_CUSTOM=false
# Check if the provided PR type is valid
if [[ " ${PR_TYPES[@]} " =~ " ${PR_TYPE_UPPER} " ]]; then
    PR_TYPE="$PR_TYPE_UPPER"
else
    IS_PR_TYPE_CUSTOM=true
    echo "Custom PR type detected: $PR_TYPE"
fi
# loop through the PR types and set the checkbox accordingly
PR_TYPE_STRINGS=()
for TYPE in "${PR_TYPES[@]}"; do
    if [ "$TYPE" == "$PR_TYPE" ]; then
        PR_TYPE_STRINGS+=("- [X] $TYPE")
    else
        PR_TYPE_STRINGS+=("- [ ] $TYPE")
    fi
done
# If the PR type is custom, add it to the list
if $IS_PR_TYPE_CUSTOM; then
    PR_TYPE_STRINGS+=("- [X] Another (Please specify): **$PR_TYPE**")
else
    PR_TYPE_STRINGS+=("- [ ] Another (Please specify): **INSERT TYPE OF PR**")
fi

# ================================== #
# ===== Version change string ====== #
# ================================== #

VERSION_CHANGE_UPPER=$(echo "$VERSION_CHANGE" | tr '[:lower:]' '[:upper:]')
VERSION_CHANGE_STRINGS=()
if [ "$VERSION_CHANGE_UPPER" == "NO" ]; then
    VERSION_CHANGE_STRINGS+=("- [ ] Yes")
    VERSION_CHANGE_STRINGS+=("- [X] No")
    VERSION_CHANGE_STRINGS+=("")
    VERSION_CHANGE_STRINGS+=("If 'Yes,' please specify the new version: **INSERT NEW VERSION**")

else
    VERSION_CHANGE_STRINGS+=("- [X] Yes")
    VERSION_CHANGE_STRINGS+=("- [ ] No")
    VERSION_CHANGE_STRINGS+=("")
    VERSION_CHANGE_STRINGS+=("If 'Yes,' please specify the new version: **$VERSION_CHANGE**")
fi

# ================================== #
# ====== Loop over all repos ======= #
# ================================== #

REPOS=$(find "$REPO_PATH" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
CREATED=0
SKIPPED=0
FAILED=0

for REPO in $REPOS; do
    echo "Processing repository: $REPO"

    # Check if the branch exists in the local git repository
    if ! git -C "$REPO_PATH/$REPO" show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        echo "  SKIP: branch '$BRANCH_NAME' does not exist locally."
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Check if the branch exists on the remote repository
    REF_OUTPUT=$(az repos ref list \
        --org "$ORG_URL" \
        --project "$PROJECT_NAME" \
        --repository "$REPO" \
        --filter "heads/$BRANCH_NAME" \
        --query "[?name=='refs/heads/$BRANCH_NAME']" 2>&1)
    REF_STATUS=$?
    if [ $REF_STATUS -ne 0 ]; then
        echo "  ERROR: failed to query the remote branch (az exited with $REF_STATUS)." >&2
        printf '%s\n' "$REF_OUTPUT" >&2
        FAILED=$((FAILED + 1))
        continue
    fi
    if ! grep -q "refs/heads/$BRANCH_NAME" <<< "$REF_OUTPUT"; then
        echo "  SKIP: branch '$BRANCH_NAME' does not exist on the remote."
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Create the pull request
    PR_OUTPUT=$(az repos pr create \
        --org "$ORG_URL" \
        --project "$PROJECT_NAME" \
        --repository "$REPO" \
        --source-branch "$BRANCH_NAME" \
        --title "$TITLE" \
        --work-items "$WORK_ITEM" \
        --open \
        --description "Please provide a brief description of the changes made in this pull request." \
        "" \
        "## Type of PR" \
        "" \
        "${PR_TYPE_STRINGS[@]}" \
        "" \
        "## Version Change" \
        "" \
        "${VERSION_CHANGE_STRINGS[@]}" \
        "" \
        "## Related PRs" \
        "" \
        "- [ ] Created a PR for the web app: [Web App PR](INSERT LINK HERE)" \
        "" \
        "## Checklist" \
        "" \
        "- [ ] Code has been reviewed and is ready for merge." \
        "- [ ] Unit tests have been written or updated, and they pass successfully." \
        "- [ ] Documentation has been updated, if necessary." \
        "- [ ] The code follows the project's coding standards and conventions." \
        "- [ ] All the automated CI/CD checks and tests have passed." \
        "- [ ] Reviewer has tested the modifications." \
        "" \
        "## Script sequence number (dev-qa)" \
        "" \
        "Please provide the sequence repositories number used to conclude the card (use the list below):" \
        "" \
        "0. Web Application" \
        "1. Layout Manager" \
        "2. Configuration Management Module" \
        "3. Customer Order Module" \
        "4. Equipment Management" \
        "5. Master Data Management" \
        "6. Material Module" \
        "7. Material Management Module" \
        "8. Operations Definition Module" \
        "9. Process Definition Module" \
        "10. Process Segment Module" \
        "11. Shared Components" \
        "12. Short Rescheduler" \
        "13. Steel Grade Module" \
        "14. Technical Order Module" \
        "15. Lookup Table" \
        "" \
        "Example: If the modifications were made in the Layout Manager, Equipment Management and Process Segment Module, so the sequence is: 1 4 10" \
        "" \
        "## Additional Information" \
        "" \
        "Please provide any additional information or context that might be relevant to this pull request:" \
        "" \
        "## Screenshots or Images" \
        "" \
        "You can just drag and drop screenshots or images here to provide visual context for your changes:" 2>&1)
    PR_STATUS=$?

    if [ $PR_STATUS -ne 0 ]; then
        echo "  ERROR: failed to create the pull request (az exited with $PR_STATUS)." >&2
        printf '%s\n' "$PR_OUTPUT" >&2
        FAILED=$((FAILED + 1))
    else
        echo "  OK: pull request created."
        printf '%s\n' "$PR_OUTPUT"
        CREATED=$((CREATED + 1))
    fi

    echo ""
done

echo "Summary: created=$CREATED skipped=$SKIPPED failed=$FAILED"
if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
