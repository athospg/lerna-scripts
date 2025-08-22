#! /bin/bash

# This script is used to create a pull request in Azure DevOps using the Azure CLI.
# It requires the Azure CLI to be installed and configured with the appropriate permissions.
#
# It will check all folders in "packages/mes-frontend" and create a pull request for each one that have the branch name provided.
# The repository name is the same as the folder name.
#
# Usage: ./open-prs.sh <branch_name> <title> <work_item> <pr-type> <version-change>
# pr-type can be one of the following: SYNC, DEPLOY, BUGFIX, FEATURE, HOTFIX, Another (Please specify)
# version-change can be one of the following: No or "new version string", the new version must follow semantic versioning (e.g., 1.0.0, 1.0.1, etc.)
#
# Example:
# bash ./scripts/open-prs.sh 80771-customer-order-details "[FEATURE] - 80771: Adding costumer order details drawer" 80771 FEATURE No
# bash ./scripts/open-prs.sh 81375-customer-order-enum-values "[BUGFIX] - 81375: Fixing enum values" 81375 BUGFIX No
# bash ./scripts/open-prs.sh 82315-technical-order-details-order-adjustments "[FEATURE] - 82315: technical order details order adjustments" 82315 FEATURE No
# bash ./scripts/open-prs.sh 82928-adjust-properties "[FIX] - 82928: Adjust properties" 82928 BUGFIX No
# bash ./scripts/open-prs.sh 82822-master-data-management-test-definition-scroll-jumps-to-top "[FIX] - 82822: fix: Transfer scroll" 82822 BUGFIX No

if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <branch_name> <title> <work_item> <pr-type> <version-change>"
    exit 1
fi

BRANCH_NAME=$1
TITLE=$2
WORK_ITEM=$3
PR_TYPE=$4
VERSION_CHANGE=$5

ORG_URL="https://dev.azure.com/sms-digital"
PROJECT_NAME="CoC Planning"
PR_TYPES=("SYNC" "DEPLOY" "BUGFIX" "FEATURE" "HOTFIX")
REPO_PATH="packages/mes-frontend"

# ================================== #
# ========= PR type string ========= #
# ================================== #

PR_TYPE_UPPER=$(echo "$PR_TYPE" | tr '[:lower:]' '[:upper:]')
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
for REPO in $REPOS; do
    echo "Processing repository: $REPO"

    # Check if the branch exists in the git repository
    git -C "$REPO_PATH/$REPO" show-ref --verify --quiet "refs/heads/$BRANCH_NAME"
    if [ $? -ne 0 ]; then
        echo "Branch '$BRANCH_NAME' does not exist in local repository '$REPO'. Skipping..."
        continue
    fi

    # Check if the branch exists in the repository
    if ! az repos ref list --org "$ORG_URL" --project "$PROJECT_NAME" --repository "$REPO" --filter "heads/$BRANCH_NAME" --query "[?name=='refs/heads/$BRANCH_NAME']" | grep -q "refs/heads/$BRANCH_NAME"; then
        echo "Branch '$BRANCH_NAME' does not exist in repository '$REPO'. Skipping..."
        continue
    fi

    # Create the pull request
    az repos pr create \
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
        "You can just drag and drop screenshots or images here to provide visual context for your changes:"

    if [ $? -ne 0 ]; then
        echo "Failed to create pull request for repository: $REPO"
    else
        echo "Pull request created successfully for repository: $REPO"
    fi

    echo ""
done
