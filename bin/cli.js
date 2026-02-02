#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
const command = args[0];

const packageDir = path.resolve(__dirname, '..');
const targetDir = process.cwd();

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

function install() {
  console.log('Installing Cursor JIRA Kit...\n');

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

  console.log('\n✓ Cursor JIRA Kit installed!\n');
  console.log('Next steps:');
  console.log('  1. Set environment variables:');
  console.log('     export JIRA_HOST="https://yourcompany.atlassian.net"');
  console.log('     export JIRA_EMAIL="your@email.com"');
  console.log('     export JIRA_API_TOKEN="your-api-token"');
  console.log('');
  console.log('  2. (Optional) Copy and customize .cursorrules:');
  console.log('     cp .cursorrules.example .cursorrules');
  console.log('');
  console.log('  3. In Cursor, try: "Work on ticket PROJ-123"');
  console.log('');
}

function showHelp() {
  console.log(`
Cursor JIRA Kit - Drop-in JIRA integration for Cursor AI

Usage:
  cursor-jira-kit init     Install scripts and skills into current directory
  cursor-jira-kit help     Show this help message

Examples:
  cd your-project
  cursor-jira-kit init
`);
}

switch (command) {
  case 'init':
  case 'install':
    install();
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
