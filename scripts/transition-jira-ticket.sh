#!/bin/bash
# Transition a Jira ticket to a new status
# Usage: ./scripts/transition-jira-ticket.sh PROJ-123 "Status Name"

set -e

# Source config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

TICKET_KEY="$1"
TARGET_STATUS="$2"

if [ -z "$TICKET_KEY" ] || [ -z "$TARGET_STATUS" ]; then
    echo "Usage: $0 TICKET-KEY \"Status Name\""
    exit 1
fi

# Validate JIRA credentials
validate_jira_credentials || exit 1

AUTH_HEADER="Authorization: Basic $(echo -n "${JIRA_EMAIL}:${JIRA_API_TOKEN}" | base64)"

# Get available transitions for this ticket
echo "Finding transition to '${TARGET_STATUS}'..."

TRANSITIONS=$(curl -s -X GET \
    -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    "${JIRA_HOST}/rest/api/3/issue/${TICKET_KEY}/transitions")

# Find the transition ID for the target status (case-insensitive match)
TRANSITION_ID=$(echo "$TRANSITIONS" | jq -r --arg status "$TARGET_STATUS" \
    '.transitions[] | select(.name | ascii_downcase == ($status | ascii_downcase)) | .id' | head -1)

if [ -z "$TRANSITION_ID" ] || [ "$TRANSITION_ID" = "null" ]; then
    echo "Error: Could not find transition to '${TARGET_STATUS}'"
    echo "Available transitions:"
    echo "$TRANSITIONS" | jq -r '.transitions[] | "  - " + .name'
    exit 1
fi

echo "Transitioning ${TICKET_KEY} to '${TARGET_STATUS}'..."

# Perform the transition
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    -d "{\"transition\": {\"id\": \"${TRANSITION_ID}\"}}" \
    "${JIRA_HOST}/rest/api/3/issue/${TICKET_KEY}/transitions")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
    echo "Successfully transitioned ${TICKET_KEY} to '${TARGET_STATUS}'"
else
    echo "Error transitioning ticket (HTTP ${HTTP_CODE}):"
    echo "$BODY"
    exit 1
fi
