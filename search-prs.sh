#! /bin/bash

# This script list all azure PRs with title containing the given string.
# It requires the Azure CLI to be installed and configured with the appropriate permissions.

if [ -z "$1" ]; then
  echo "Usage: $0 <search-string>"
  exit 1
fi

SEARCH_STRING="$1"

ORG_URL="https://dev.azure.com/sms-digital"
PROJECT_NAME="CoC Planning"

PROJECT_NAME_URL_ENCODED=$(echo "$PROJECT_NAME" | sed 's/ /%20/g')

echo "Searching for PRs with title containing: $SEARCH_STRING"

az repos pr list --org "$ORG_URL" --project "$PROJECT_NAME" --status "active" --query "[?contains(title, '$SEARCH_STRING')].{Title: title, CreatedBy: createdBy.displayName, URL: join('', ['$ORG_URL/$PROJECT_NAME_URL_ENCODED/_git/', repository.name, '/pullrequest/', to_string(pullRequestId)])}" -o table
