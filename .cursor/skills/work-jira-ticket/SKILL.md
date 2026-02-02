---
name: work-jira-ticket
description: Work on a single Jira ticket by fetching ticket data, creating a feature branch, implementing changes, creating a PR, and updating JIRA. Use when the user wants to work on a Jira ticket, mentions a ticket key like PROJ-123, or asks to implement a ticket.
---

# Work Jira Ticket

Work on a single Jira ticket by key.

## Instructions

1. **Extract ticket key**: Get the Jira ticket key from the user's request (e.g., PROJ-123). If not explicitly provided, ask the user for the ticket key.

2. **Fetch the ticket**: Run `./scripts/fetch-jira-ticket.sh TICKET_KEY` to download ticket data and attachments

3. **Review the ticket**: Read the files in `.jira-tickets/TICKET_KEY/`:
   - `summary.md` for the overview
   - `description.json` for full description details
   - `comments.md` for any discussion
   - `attachments/` folder for screenshots, specs, etc.

4. **Create a feature branch**:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/TICKET_KEY
   ```

5. **Implement the ticket**: Based on the requirements, make the necessary code changes. If there are attachments (especially screenshots or mockups), review them carefully.

6. **Run checks**: Before committing, run any project linting/type checks:
   ```bash
   npm run lint
   # or
   npx tsc --noEmit
   ```

7. **Commit your changes**: Make atomic commits with clear messages referencing the ticket:
   ```bash
   git add -A
   git commit -m "TICKET_KEY: Brief description of change"
   ```

8. **Push and create a Pull Request**:
   ```bash
   git push -u origin feature/TICKET_KEY
   gh pr create --base develop --title "TICKET_KEY: [ticket summary]" --body "## Jira Ticket
   https://yourcompany.atlassian.net/browse/TICKET_KEY

   ## Changes
   - [List what was changed]

   ## Testing
   - [How to test the changes]"
   ```

9. **Get the PR URL**: Capture the PR URL from the output

10. **Update JIRA with PR link**:
    ```bash
    ./scripts/update-jira-ticket.sh TICKET_KEY "PR created: [PR_URL]

    Changes made:
    - [List changes]

    Ready for review."
    ```

11. **Transition ticket status** (optional - if your workflow uses it):
    ```bash
    ./scripts/transition-jira-ticket.sh TICKET_KEY "In Review"
    ```

12. **Report back**: Provide:
    - The PR link
    - Summary of what was implemented
    - Any notes or questions for the reviewer
