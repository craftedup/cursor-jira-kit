#!/bin/bash
# Fetch Jira ticket and attachments to local folder
# Usage: ./scripts/fetch-jira-ticket.sh PROJ-123

set -e

# Source config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

TICKET_KEY="$1"

if [ -z "$TICKET_KEY" ]; then
    echo "Usage: $0 TICKET-KEY"
    exit 1
fi

# Validate JIRA credentials
validate_jira_credentials || exit 1

# Create output directory
OUTPUT_DIR=".jira-tickets/${TICKET_KEY}"
mkdir -p "${OUTPUT_DIR}/attachments"

echo "Fetching ticket ${TICKET_KEY}..."

# Fetch ticket data
curl -s -X GET \
    -H "Authorization: Basic $(echo -n "${JIRA_EMAIL}:${JIRA_API_TOKEN}" | base64)" \
    -H "Content-Type: application/json" \
    "${JIRA_HOST}/rest/api/3/issue/${TICKET_KEY}?expand=renderedFields,comments" \
    > "${OUTPUT_DIR}/ticket.json"

# Check if fetch succeeded
if [ ! -s "${OUTPUT_DIR}/ticket.json" ] || grep -q '"errorMessages"' "${OUTPUT_DIR}/ticket.json" 2>/dev/null; then
    echo "Error fetching ticket:"
    cat "${OUTPUT_DIR}/ticket.json"
    exit 1
fi

# Extract key info to a readable summary
jq -r '
"# " + .key + ": " + .fields.summary + "\n\n" +
"**Status:** " + .fields.status.name + "\n" +
"**Type:** " + .fields.issuetype.name + "\n" +
"**Priority:** " + (.fields.priority.name // "None") + "\n" +
"**Assignee:** " + (.fields.assignee.displayName // "Unassigned") + "\n" +
"**Reporter:** " + (.fields.reporter.displayName // "Unknown") + "\n\n" +
"## Description\n\n" + (.fields.description.content // [] | .. | .text? // empty) + "\n\n" +
"## Acceptance Criteria\n\n" + (.fields.customfield_10016 // "Not specified")
' "${OUTPUT_DIR}/ticket.json" > "${OUTPUT_DIR}/summary.md" 2>/dev/null || true

# Also create a simpler description extraction
jq -r '.fields.description' "${OUTPUT_DIR}/ticket.json" > "${OUTPUT_DIR}/description.json"

# Download attachments
echo "Checking for attachments..."
ATTACHMENTS=$(jq -r '.fields.attachment[]? | "\(.id)|\(.filename)|\(.content)"' "${OUTPUT_DIR}/ticket.json")

if [ -n "$ATTACHMENTS" ]; then
    echo "$ATTACHMENTS" | while IFS='|' read -r id filename url; do
        if [ -n "$url" ]; then
            echo "  Downloading: ${filename}"
            curl -sL \
                -H "Authorization: Basic $(echo -n "${JIRA_EMAIL}:${JIRA_API_TOKEN}" | base64)" \
                -o "${OUTPUT_DIR}/attachments/${filename}" \
                "$url"
        fi
    done
    echo "Attachments saved to ${OUTPUT_DIR}/attachments/"
else
    echo "  No attachments found"
fi

# Fetch comments
echo "Fetching comments..."
jq -r '.fields.comment.comments[]? | "### " + .author.displayName + " (" + .created[0:10] + ")\n" + (.body.content[]?.content[]?.text // "") + "\n"' \
    "${OUTPUT_DIR}/ticket.json" > "${OUTPUT_DIR}/comments.md" 2>/dev/null || true

echo ""
echo "Ticket data saved to ${OUTPUT_DIR}/"
echo "  - ticket.json    (raw API response)"
echo "  - summary.md     (readable summary)"
echo "  - comments.md    (all comments)"
echo "  - attachments/   (downloaded files)"
