#!/bin/bash
# Add a comment to a Jira ticket
# Usage: ./scripts/update-jira-ticket.sh PROJ-123 "Comment text"
# URLs in the comment will automatically become clickable links

set -e

# Source config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

TICKET_KEY="$1"
COMMENT="$2"

if [ -z "$TICKET_KEY" ] || [ -z "$COMMENT" ]; then
    echo "Usage: $0 TICKET-KEY \"Comment text\""
    exit 1
fi

# Validate JIRA credentials
validate_jira_credentials || exit 1

echo "Adding comment to ${TICKET_KEY}..."

# Generate ADF JSON using perl for robust handling
PAYLOAD=$(perl -e '
    use strict;
    use warnings;
    use JSON::PP;

    my $text = $ARGV[0];
    my @lines = split(/\n/, $text, -1);
    my @paragraphs;

    foreach my $line (@lines) {
        my @content;

        if ($line eq "" || $line =~ /^\s*$/) {
            push @content, { type => "text", text => " " };
        } else {
            # Split by URLs while keeping the URLs
            my @parts = split(/(https?:\/\/[^\s]+)/, $line);

            foreach my $part (@parts) {
                next if $part eq "";

                if ($part =~ /^https?:\/\//) {
                    # URL - make it a link
                    push @content, {
                        type => "text",
                        text => $part,
                        marks => [{ type => "link", attrs => { href => $part } }]
                    };
                } else {
                    # Regular text
                    push @content, { type => "text", text => $part };
                }
            }
        }

        # If no content was added, add a space
        if (scalar(@content) == 0) {
            push @content, { type => "text", text => " " };
        }

        push @paragraphs, { type => "paragraph", content => \@content };
    }

    my $doc = {
        body => {
            type => "doc",
            version => 1,
            content => \@paragraphs
        }
    };

    print encode_json($doc);
' "$COMMENT")

# Add comment to ticket
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Authorization: Basic $(echo -n "${JIRA_EMAIL}:${JIRA_API_TOKEN}" | base64)" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "${JIRA_HOST}/rest/api/3/issue/${TICKET_KEY}/comment")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
    echo "Comment added successfully to ${TICKET_KEY}"
else
    echo "Error adding comment (HTTP ${HTTP_CODE}):"
    echo "$BODY"
    exit 1
fi
