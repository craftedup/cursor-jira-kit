#!/bin/bash
# Get Vercel preview deployment URL from a GitHub PR
# Usage: ./scripts/get-vercel-preview-url.sh [PR_NUMBER]
# If no PR number provided, uses the current branch's PR

set -e

PR_NUMBER="$1"

# If no PR number provided, get it from current branch
if [ -z "$PR_NUMBER" ]; then
    PR_NUMBER=$(gh pr view --json number -q '.number' 2>/dev/null || echo "")
    if [ -z "$PR_NUMBER" ]; then
        echo "Error: No PR found for current branch and no PR number provided" >&2
        exit 1
    fi
fi

# Get the head SHA of the PR
HEAD_SHA=$(gh pr view "$PR_NUMBER" --json headRefOid -q '.headRefOid')

if [ -z "$HEAD_SHA" ]; then
    echo "Error: Could not get head SHA for PR #${PR_NUMBER}" >&2
    exit 1
fi

echo "Checking deployments for PR #${PR_NUMBER} (${HEAD_SHA:0:7})..." >&2

# Get repo info
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')

# Wait for deployment to appear and succeed (max 90 seconds)
MAX_ATTEMPTS=18
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    # Get the latest Preview deployment for this SHA
    DEPLOYMENT_ID=$(gh api "repos/${REPO}/deployments?sha=${HEAD_SHA}&environment=Preview" --jq '.[0].id' 2>/dev/null || echo "")

    if [ -n "$DEPLOYMENT_ID" ] && [ "$DEPLOYMENT_ID" != "null" ]; then
        # Get the deployment status with the environment URL
        PREVIEW_URL=$(gh api "repos/${REPO}/deployments/${DEPLOYMENT_ID}/statuses" --jq '.[0].environment_url' 2>/dev/null || echo "")

        if [ -n "$PREVIEW_URL" ] && [ "$PREVIEW_URL" != "null" ]; then
            echo "$PREVIEW_URL"
            exit 0
        fi
    fi

    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
        echo "Waiting for Vercel deployment... (attempt $ATTEMPT/$MAX_ATTEMPTS)" >&2
        sleep 5
    fi
done

echo "Error: Could not find Vercel preview URL after ${MAX_ATTEMPTS} attempts" >&2
exit 1
