#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const readline = require('readline');

const args = process.argv.slice(2);
const command = args[0];

const packageDir = path.resolve(__dirname, '..');
const targetDir = process.cwd();
const configFileName = '.cursor-jira-kit.yaml';

function copyDir(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  const entries = fs.readdirSync(src, { withFileTypes: true });

  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);

    if (entry.isDirectory()) {
      copyDir(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
      // Preserve executable permissions for scripts
      if (srcPath.endsWith('.sh')) {
        fs.chmodSync(destPath, 0o755);
      }
    }
  }
}

function prompt(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

function detectGitRepo() {
  try {
    const gitConfig = fs.readFileSync(path.join(targetDir, '.git/config'), 'utf8');
    const match = gitConfig.match(/url = .*[:/]([^/]+\/[^/]+?)(?:\.git)?$/m);
    if (match) {
      return match[1];
    }
  } catch {
    // Not a git repo or can't read config
  }
  return null;
}

function detectProjectKey() {
  // Try to detect from existing config or package.json
  try {
    const pkg = JSON.parse(fs.readFileSync(path.join(targetDir, 'package.json'), 'utf8'));
    if (pkg.name) {
      // Extract potential project key from package name
      const match = pkg.name.match(/([A-Z]{2,5})/i);
      if (match) {
        return match[1].toUpperCase();
      }
    }
  } catch {
    // No package.json
  }
  return 'PROJ';
}

async function init() {
  console.log('Initializing Cursor JIRA Kit...\n');

  const configPath = path.join(targetDir, configFileName);
  const hasExistingConfig = fs.existsSync(configPath);

  // Detect defaults
  const detectedRepo = detectGitRepo();
  const detectedKey = detectProjectKey();

  // Get project info
  const jiraKey = await prompt(`JIRA Project Key [${detectedKey}]: `) || detectedKey;
  const repo = await prompt(`GitHub Repo (owner/repo) [${detectedRepo || 'owner/repo'}]: `) || detectedRepo || 'owner/repo';
  const baseBranch = await prompt('Base Branch [develop]: ') || 'develop';

  // Create config
  const config = `# Cursor JIRA Kit Configuration

project:
  jiraKey: ${jiraKey}
  repo: ${repo}

workflow:
  baseBranch: ${baseBranch}
  branchPattern: "feature/{ticket_key}"
  transitions:
    onPrCreated: "In Review"  # Status to transition to after PR (optional)

# JIRA credentials - set via environment variables:
#   JIRA_HOST, JIRA_EMAIL, JIRA_API_TOKEN
# Or uncomment and fill in below (not recommended for shared repos):
# jira:
#   host: https://yourcompany.atlassian.net
#   email: your@email.com
#   apiToken: your-api-token
`;

  if (hasExistingConfig) {
    const overwrite = await prompt(`${configFileName} exists. Overwrite? [y/N]: `);
    if (overwrite.toLowerCase() !== 'y') {
      console.log('Keeping existing config.\n');
    } else {
      fs.writeFileSync(configPath, config);
      console.log(`  Created ${configFileName}`);
    }
  } else {
    fs.writeFileSync(configPath, config);
    console.log(`  Created ${configFileName}`);
  }

  // Copy scripts
  const scriptsDir = path.join(packageDir, 'scripts');
  const targetScripts = path.join(targetDir, 'scripts');

  if (fs.existsSync(scriptsDir)) {
    console.log('  Copying scripts/ ...');
    copyDir(scriptsDir, targetScripts);
  }

  // Copy .cursor skills
  const cursorDir = path.join(packageDir, '.cursor');
  const targetCursor = path.join(targetDir, '.cursor');

  if (fs.existsSync(cursorDir)) {
    console.log('  Copying .cursor/ ...');
    copyDir(cursorDir, targetCursor);
  }

  // Copy example cursorrules if it doesn't exist
  const cursorrulesExample = path.join(packageDir, '.cursorrules.example');
  const targetCursorrules = path.join(targetDir, '.cursorrules.example');

  if (fs.existsSync(cursorrulesExample) && !fs.existsSync(targetCursorrules)) {
    console.log('  Copying .cursorrules.example ...');
    fs.copyFileSync(cursorrulesExample, targetCursorrules);
  }

  console.log('\n✓ Cursor JIRA Kit initialized!\n');
  console.log('Next steps:');
  console.log('  1. Set environment variables (add to ~/.zshrc or ~/.bashrc):');
  console.log('     export JIRA_HOST="https://yourcompany.atlassian.net"');
  console.log('     export JIRA_EMAIL="your@email.com"');
  console.log('     export JIRA_API_TOKEN="your-api-token"');
  console.log('');
  console.log('  2. (Optional) Customize .cursorrules.example:');
  console.log('     mv .cursorrules.example .cursorrules');
  console.log('');
  console.log('  3. In Cursor, try: "Work on ticket ' + jiraKey + '-123"');
  console.log('');
}

function showHelp() {
  console.log(`
Cursor JIRA Kit - Drop-in JIRA integration for Cursor AI

Usage:
  cursor-jira-kit init     Initialize kit in current directory (interactive)
  cursor-jira-kit help     Show this help message

Examples:
  cd your-project
  cursor-jira-kit init
`);
}

switch (command) {
  case 'init':
  case 'install':
    init().catch(console.error);
    break;
  case 'help':
  case '--help':
  case '-h':
  case undefined:
    showHelp();
    break;
  default:
    console.error(`Unknown command: ${command}`);
    showHelp();
    process.exit(1);
}
