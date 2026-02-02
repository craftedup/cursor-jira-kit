#!/bin/bash

# Config helper for Cursor JIRA Kit
# Source this in other scripts: source "$(dirname "$0")/config.sh"

CONFIG_FILE=".cursor-jira-kit.yaml"

# Find config file (search up directory tree)
find_config() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/$CONFIG_FILE" ]]; then
      echo "$dir/$CONFIG_FILE"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

# Simple YAML value extractor (handles basic key: value patterns)
get_yaml_value() {
  local file="$1"
  local key="$2"
  grep -E "^\s*${key}:" "$file" 2>/dev/null | head -1 | sed 's/.*:\s*//' | sed 's/^["'"'"']//' | sed 's/["'"'"']$//' | sed 's/#.*//' | xargs
}

# Load configuration
load_config() {
  local config_path
  config_path=$(find_config)

  if [[ -z "$config_path" ]]; then
    echo "Warning: No $CONFIG_FILE found. Using environment variables only." >&2
    return 1
  fi

  # Load values from config (environment variables take precedence)
  export CONFIG_JIRA_KEY="${CONFIG_JIRA_KEY:-$(get_yaml_value "$config_path" "jiraKey")}"
  export CONFIG_REPO="${CONFIG_REPO:-$(get_yaml_value "$config_path" "repo")}"
  export CONFIG_BASE_BRANCH="${CONFIG_BASE_BRANCH:-$(get_yaml_value "$config_path" "baseBranch")}"
  export CONFIG_BRANCH_PATTERN="${CONFIG_BRANCH_PATTERN:-$(get_yaml_value "$config_path" "branchPattern")}"
  export CONFIG_ON_PR_CREATED="${CONFIG_ON_PR_CREATED:-$(get_yaml_value "$config_path" "onPrCreated")}"

  # JIRA credentials (env vars take precedence)
  if [[ -z "$JIRA_HOST" ]]; then
    export JIRA_HOST="$(get_yaml_value "$config_path" "host")"
  fi
  if [[ -z "$JIRA_EMAIL" ]]; then
    export JIRA_EMAIL="$(get_yaml_value "$config_path" "email")"
  fi
  if [[ -z "$JIRA_API_TOKEN" ]]; then
    export JIRA_API_TOKEN="$(get_yaml_value "$config_path" "apiToken")"
  fi

  # Set defaults
  export CONFIG_BASE_BRANCH="${CONFIG_BASE_BRANCH:-develop}"
  export CONFIG_BRANCH_PATTERN="${CONFIG_BRANCH_PATTERN:-feature/{ticket_key}}"

  return 0
}

# Validate required JIRA credentials
validate_jira_credentials() {
  local missing=""

  if [[ -z "$JIRA_HOST" ]]; then
    missing="$missing JIRA_HOST"
  fi
  if [[ -z "$JIRA_EMAIL" ]]; then
    missing="$missing JIRA_EMAIL"
  fi
  if [[ -z "$JIRA_API_TOKEN" ]]; then
    missing="$missing JIRA_API_TOKEN"
  fi

  if [[ -n "$missing" ]]; then
    echo "Error: Missing required environment variables:$missing" >&2
    echo "Set these in your shell profile or in $CONFIG_FILE" >&2
    return 1
  fi

  return 0
}

# Auto-load config when sourced
load_config
