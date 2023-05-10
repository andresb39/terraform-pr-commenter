#!/usr/bin/env bash
# Autor: @andresb39
# Date: Marzo 2023
# TODO: This script should run terraform on commit modified folders

# exit on error
set -o errexit

git config --global --add safe.directory '*'

# Fetch all git branches.
git fetch --prune --tags

# Get the name of the last tag.
last_tag=$(git describe --abbrev=0 --tags)

# home directory
home_dir=$(pwd)

# Get the names of modified  folders.
diff=$( git diff --name-only $last_tag HEAD -- '*.tf' | xargs -I{} dirname "{}" | sort -u | sed '/^\./d'| cut -d/ -f 1-2)

#############
# Validations
#############
PR_NUMBER=$(jq -r ".pull_request.number" "$GITHUB_EVENT_PATH")
if [[ "$PR_NUMBER" == "null" ]]; then
  echo "This isn't a PR."
  exit 0
fi

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "GITHUB_TOKEN environment variable missing."
  exit 1
fi

# Read EXPAND_SUMMARY_DETAILS environment variable or use "true"
if [[ ${EXPAND_SUMMARY_DETAILS:-true} == "true" ]]; then
  DETAILS_STATE=" open"
else
  DETAILS_STATE=""
fi

# Read HIGHLIGHT_CHANGES environment variable or use "true"
COLOURISE=${HIGHLIGHT_CHANGES:-true}

ACCEPT_HEADER="Accept: application/vnd.github.v3+json"
AUTH_HEADER="Authorization: token $GITHUB_TOKEN"
CONTENT_HEADER="Content-Type: application/json"

PR_COMMENTS_URL=$(jq -r ".pull_request.comments_url" "$GITHUB_EVENT_PATH")
PR_COMMENT_URI=$(jq -r ".repository.issue_comment_url" "$GITHUB_EVENT_PATH" | sed "s|{/number}||g")

for folder in $diff; do

  cd "$folder"

  DIRECTORY=$(basename "$folder")

  echo -e "\033[34;1mINFO:\033[0m Formating tfplan for PR Commenter on $folder"

  # Look for an existing plan PR comment and delete
  echo -e "\033[34;1mINFO:\033[0m Looking for an existing plan PR comment."
  PR_COMMENT_ID=$(curl -sS -H "$AUTH_HEADER" -H "$ACCEPT_HEADER" -L "$PR_COMMENTS_URL" | jq '.[] | select(.body|test ("### Terraform `plan` Succeeded for Directory `'"$DIRECTORY"'`")) | .id')
  if [ "$PR_COMMENT_ID" ]; then
    echo -e "\033[34;1mINFO:\033[0m Found existing plan PR comment: $PR_COMMENT_ID. Deleting."
    PR_COMMENT_URL="$PR_COMMENT_URI/$PR_COMMENT_ID"
    curl -sS -X DELETE -H "$AUTH_HEADER" -H "$ACCEPT_HEADER" -L "$PR_COMMENT_URL" > /dev/null
  else
    echo -e "\033[34;1mINFO:\033[0m No existing plan PR comment found."
  fi

  INPUT=$(terraform show tfplan -no-color)

  if [[ $INPUT != "This plan does nothing." ]]; then
    echo "Plan is not empty"
    # Create a new plan PR comment
    CLEAN_PLAN=${INPUT::65300} # GitHub has a 65535-char comment limit - truncate plan, leaving space for comment wrapper
    CLEAN_PLAN=$(echo "$CLEAN_PLAN" | sed -r 's/^([[:blank:]]*)([-+~])/\2\1/g') # Move any diff characters to start of line
    if [[ $COLOURISE == 'true' ]]; then
      CLEAN_PLAN=$(echo "$CLEAN_PLAN" | sed -r 's/^~/!/g') # Replace ~ with ! to colourise the diff in GitHub comments
    fi

    PR_COMMENT="### Terraform \`plan\` Succeeded for Directory \`$DIRECTORY\`
<details$DETAILS_STATE><summary>Show Output</summary>

\`\`\`diff
$CLEAN_PLAN
\`\`\`
</details>"

    # Add plan comment to PR.
    PR_PAYLOAD=$(echo '{}' | jq --arg body "$PR_COMMENT" '.body = $body')
    echo -e "\033[34;1mINFO:\033[0m Adding plan comment to PR."
    curl -sS -X POST -H "$AUTH_HEADER" -H "$ACCEPT_HEADER" -H "$CONTENT_HEADER" -d "$PR_PAYLOAD" -L "$PR_COMMENTS_URL" > /dev/null

  else
    echo "Plan is empty"
  fi
  
  # Return to home directory
  cd "$home_dir"

done
