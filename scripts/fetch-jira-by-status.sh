#!/bin/bash
# Fetch all Jira tickets by status
# Usage: ./scripts/fetch-jira-by-status.sh "In Progress"
# Usage: ./scripts/fetch-jira-by-status.sh "To Do" PROJ

set -e

# Source .env if it exists
[ -f .env ] && set -a && source .env && set +a

STATUS="$1"
PROJECT="$2"

if [ -z "$STATUS" ]; then
    echo "Usage: $0 STATUS [PROJECT_KEY]"
    echo "Example: $0 'In Progress'"
    echo "Example: $0 'To Do' PROJ"
    exit 1
fi

# Check required env vars
if [ -z "$JIRA_HOST" ] || [ -z "$JIRA_EMAIL" ] || [ -z "$JIRA_API_TOKEN" ]; then
    echo "Error: Missing required environment variables"
    echo "Required: JIRA_HOST, JIRA_EMAIL, JIRA_API_TOKEN"
    exit 1
fi

# Build JQL query
if [ -n "$PROJECT" ]; then
    JQL="project=${PROJECT} AND status=\"${STATUS}\" ORDER BY priority DESC, created ASC"
else
    JQL="status=\"${STATUS}\" ORDER BY priority DESC, created ASC"
fi

echo "Searching for tickets with status: ${STATUS}"
[ -n "$PROJECT" ] && echo "Project filter: ${PROJECT}"
echo ""

# Build JSON payload with proper escaping
JSON_PAYLOAD=$(jq -n --arg jql "$JQL" '{"jql": $jql, "maxResults": 50, "fields": ["key", "summary", "status", "priority"]}')

# Fetch tickets using new JQL search API (POST)
RESPONSE=$(curl -s -X POST \
    -H "Authorization: Basic $(echo -n "${JIRA_EMAIL}:${JIRA_API_TOKEN}" | base64)" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" \
    "${JIRA_HOST}/rest/api/3/search/jql")

# Check for errors
if echo "$RESPONSE" | grep -q '"errorMessages"'; then
    echo "Error searching tickets:"
    echo "$RESPONSE" | jq -r '.errorMessages[]'
    exit 1
fi

# Extract ticket keys
TICKETS=$(echo "$RESPONSE" | jq -r '.issues[].key')
TOTAL=$(echo "$RESPONSE" | jq -r '.issues | length')

echo "Found ${TOTAL} ticket(s):"
echo ""

# List tickets with summary
echo "$RESPONSE" | jq -r '.issues[] | "  " + .key + " - " + .fields.summary'

echo ""
echo "---"
echo "Ticket keys: $(echo $TICKETS | tr '\n' ' ')"

# Save the list
mkdir -p .jira-tickets
echo "$RESPONSE" > ".jira-tickets/search-results.json"
echo "$TICKETS" > ".jira-tickets/ticket-list.txt"

echo ""
echo "Results saved to .jira-tickets/search-results.json"
echo "Ticket list saved to .jira-tickets/ticket-list.txt"

# Optionally fetch each ticket's full details
if [ "$3" == "--fetch-all" ]; then
    echo ""
    echo "Fetching full details for each ticket..."
    for ticket in $TICKETS; do
        ./scripts/fetch-jira-ticket.sh "$ticket"
    done
fi
