#!/bin/bash
# Deploy Claude Code GitHub Actions workflow to all repos
# Usage: ./deploy-claude-workflow.sh
#
# Prerequisites:
#   - gh CLI installed and authenticated (gh auth login)
#   - CLAUDE_CODE_OAUTH_TOKEN set in environment or passed as argument
#
# This script will:
#   1. Add the claude.yml workflow to every repo
#   2. Set the CLAUDE_CODE_OAUTH_TOKEN secret on each repo
#   3. Skip repos that already have the workflow

set -euo pipefail

OWNER="ecnepsyroc-bot"

# Get OAuth token
if [ -n "${1:-}" ]; then
    OAUTH_TOKEN="$1"
elif [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
    OAUTH_TOKEN="$CLAUDE_CODE_OAUTH_TOKEN"
else
    echo "Usage: $0 <claude-oauth-token>"
    echo "  or set CLAUDE_CODE_OAUTH_TOKEN environment variable"
    exit 1
fi

WORKFLOW_CONTENT='name: Claude Code

on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
  issues:
    types: [opened, assigned]
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  claude:
    if: |
      (github.event_name == '\''issue_comment'\'' && contains(github.event.comment.body, '\''@claude'\'')) ||
      (github.event_name == '\''pull_request_review_comment'\'' && contains(github.event.comment.body, '\''@claude'\'')) ||
      github.event_name == '\''issues'\'' ||
      github.event_name == '\''pull_request'\''
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
      issues: write
      id-token: write
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 1

      - name: Run Claude
        uses: anthropics/claude-code-action@v1
        with:
          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}'

# Get all repos
echo "Fetching repos for $OWNER..."
REPOS=$(gh repo list "$OWNER" --limit 100 --json name,isArchived --jq '.[] | select(.isArchived == false) | .name')

echo ""
echo "Found repos:"
echo "$REPOS" | while read -r repo; do echo "  - $repo"; done
echo ""

for REPO in $REPOS; do
    echo "=== $OWNER/$REPO ==="

    # Check if workflow already exists
    if gh api "repos/$OWNER/$REPO/contents/.github/workflows/claude.yml" &>/dev/null; then
        echo "  Workflow already exists, updating..."
        SHA=$(gh api "repos/$OWNER/$REPO/contents/.github/workflows/claude.yml" --jq '.sha')
        ENCODED=$(echo -n "$WORKFLOW_CONTENT" | base64 -w 0)
        gh api --method PUT "repos/$OWNER/$REPO/contents/.github/workflows/claude.yml" \
            -f message="Update Claude Code GitHub Actions workflow" \
            -f content="$ENCODED" \
            -f sha="$SHA" > /dev/null
        echo "  Workflow updated."
    else
        echo "  Adding workflow..."
        ENCODED=$(echo -n "$WORKFLOW_CONTENT" | base64 -w 0)
        gh api --method PUT "repos/$OWNER/$REPO/contents/.github/workflows/claude.yml" \
            -f message="Add Claude Code GitHub Actions workflow" \
            -f content="$ENCODED" > /dev/null
        echo "  Workflow added."
    fi

    # Set the secret
    echo "  Setting CLAUDE_CODE_OAUTH_TOKEN secret..."
    gh secret set CLAUDE_CODE_OAUTH_TOKEN --repo "$OWNER/$REPO" --body "$OAUTH_TOKEN"
    echo "  Secret set."

    echo ""
done

echo "Done! Claude Code is deployed to all repos."
echo ""
echo "NOTE: OAuth tokens expire. When you refresh your token, run:"
echo "  $0 <new-token>"
echo "to update the secret across all repos."
