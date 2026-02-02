---
name: work-jira-tickets-by-status
description: Fetch and work through all Jira tickets with a given status, processing each ticket sequentially. Use when the user wants to work on multiple tickets, mentions ticket status like "In Progress" or "To Do", or asks to process tickets by status.
---

# Work Jira Tickets by Status

Fetch and work through all tickets with a given status.

## Instructions

1. **Extract arguments**: Get the status and optional project key from the user's request. The format should be STATUS optionally followed by PROJECT_KEY (e.g., "In Progress" or "To Do PROJ"). If not clear, ask the user to clarify.

2. **Parse arguments**: Split the input into STATUS and optional PROJECT_KEY

3. **Fetch tickets by status**: Run `./scripts/fetch-jira-by-status.sh "STATUS" PROJECT_KEY`

4. **Review the ticket list**: Read `.jira-tickets/ticket-list.txt` to see all matching tickets

5. **Ask user which tickets to work**: Present the list and ask the user to confirm which tickets to process (all, or specific ones).

6. **For each ticket**, work through them one at a time:

   a. **Fetch full ticket details**:
      ```bash
      ./scripts/fetch-jira-ticket.sh TICKET-KEY
      ```

   b. **Review the ticket**: Read `.jira-tickets/TICKET-KEY/summary.md` and attachments

   c. **Create a feature branch**:
      ```bash
      git checkout develop
      git pull origin develop
      git checkout -b feature/TICKET-KEY
      ```

   d. **Implement the ticket**: Make necessary code changes based on requirements

   e. **Run checks**: Before committing:
      ```bash
      npm run lint
      # or
      npx tsc --noEmit
      ```

   f. **Commit and push**:
      ```bash
      git add -A
      git commit -m "TICKET-KEY: Brief description"
      git push -u origin feature/TICKET-KEY
      ```

   g. **Create PR**:
      ```bash
      gh pr create --base develop --title "TICKET-KEY: [summary]" --body "## Jira Ticket
      https://yourcompany.atlassian.net/browse/TICKET-KEY

      ## Changes
      - [List changes]

      ## Testing
      - [How to test]"
      ```

   h. **Update JIRA**:
      ```bash
      ./scripts/update-jira-ticket.sh TICKET-KEY "PR created: [PR_URL]

      Changes made:
      - [List changes]

      Ready for review."
      ```

   i. **Transition ticket** (optional):
      ```bash
      ./scripts/transition-jira-ticket.sh TICKET-KEY "In Review"
      ```

   j. **Return to develop** before starting next ticket:
      ```bash
      git checkout develop
      ```

7. **Report summary**: After completing all tickets, provide a summary:
   - List of PRs created with links
   - Summary of changes for each ticket
   - Any tickets that couldn't be completed and why
   - Any questions or blockers encountered
