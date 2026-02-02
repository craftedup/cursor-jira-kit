# Cursor JIRA Kit

Drop-in JIRA integration for Cursor AI. Work on JIRA tickets directly from your editor with AI assistance.

## Features

- **Single Ticket Workflow**: Fetch, implement, and PR a single JIRA ticket
- **Batch Processing**: Work through all tickets with a given status
- **Auto PR Creation**: Creates PRs with ticket links and change summaries
- **JIRA Updates**: Comment on tickets with PR links and preview URLs
- **Status Transitions**: Automatically move tickets through your workflow

## Installation

### Via npm (Recommended)

**1. Configure npm for GitHub Packages:**

Add to `~/.npmrc`:
```
@craftedup:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=YOUR_GITHUB_TOKEN
```

Get a token at: https://github.com/settings/tokens/new?scopes=read:packages

**2. Install globally:**
```bash
npm install -g @craftedup/cursor-jira-kit
```

**3. Initialize in your project:**
```bash
cd your-project
cursor-jira-kit init
```

### Manual Installation

```bash
# Clone this repo
git clone https://github.com/craftedup/cursor-jira-kit.git

# Copy to your project
cp -r cursor-jira-kit/scripts your-project/
cp -r cursor-jira-kit/.cursor your-project/
```

## Quick Start

### 1. Configure Environment

Set these environment variables (add to your shell profile or `.env.local`):

```bash
export JIRA_HOST="https://yourcompany.atlassian.net"
export JIRA_EMAIL="your@email.com"
export JIRA_API_TOKEN="your-api-token"
```

Get your API token from: https://id.atlassian.com/manage-profile/security/api-tokens

### 2. Install Dependencies

The scripts require:
- `curl` (usually pre-installed)
- `jq` (for JSON parsing)
- `gh` CLI (for GitHub operations)

```bash
# macOS
brew install jq gh

# Authenticate GitHub CLI
gh auth login
```

### 3. Use in Cursor

Open Cursor and ask:
- "Work on ticket PROJ-123"
- "Implement JIRA ticket CW2-456"
- "Work on all tickets with status 'To Do'"

Cursor will use the skills to guide the AI through the workflow.

## Scripts

| Script | Description |
|--------|-------------|
| `fetch-jira-ticket.sh` | Fetch a single ticket's details and attachments |
| `fetch-jira-by-status.sh` | Fetch all tickets with a given status |
| `update-jira-ticket.sh` | Add a comment to a JIRA ticket |
| `transition-jira-ticket.sh` | Change a ticket's status |
| `get-vercel-preview-url.sh` | Get Vercel preview URL for a PR |

### Manual Usage

```bash
# Fetch a ticket
./scripts/fetch-jira-ticket.sh PROJ-123

# Fetch all "To Do" tickets
./scripts/fetch-jira-by-status.sh "To Do" PROJ

# Update ticket with comment
./scripts/update-jira-ticket.sh PROJ-123 "PR ready for review: https://github.com/..."

# Transition ticket status
./scripts/transition-jira-ticket.sh PROJ-123 "In Review"

# Get Vercel preview URL
./scripts/get-vercel-preview-url.sh owner/repo 42
```

## Cursor Skills

### work-jira-ticket

Triggered by: "Work on ticket PROJ-123", "Implement JIRA ticket..."

Workflow:
1. Fetches ticket details and attachments
2. Creates a feature branch
3. Implements the requirements
4. Commits with ticket reference
5. Creates a PR

### work-jira-tickets-by-status

Triggered by: "Work on all To Do tickets", "Process tickets with status..."

Workflow:
1. Fetches all matching tickets
2. Processes each ticket sequentially
3. Creates PRs for each
4. Reports summary when done

## Customization

### Modify Scripts

Edit scripts in `./scripts/` to match your workflow:
- Change branch naming conventions
- Adjust JIRA field mappings
- Add custom status transitions

### Modify Skills

Edit `.cursor/skills/*/SKILL.md` to:
- Change the trigger descriptions
- Adjust workflow steps
- Add project-specific instructions

### Add .cursorrules

Create a `.cursorrules` file in your project root for project-specific context:

```
This is a Next.js project using TypeScript and Tailwind CSS.

When implementing JIRA tickets:
- Components go in src/components/
- Use existing component patterns
- Run `npm run lint` before committing
```

## Related

- **[jira-claude-bot](https://github.com/craftedup/jira-claude-bot)**: Fully autonomous JIRA bot using Claude Code CLI (24/7 daemon mode)

## License

MIT
