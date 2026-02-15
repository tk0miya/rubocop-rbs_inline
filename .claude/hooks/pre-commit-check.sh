#!/bin/bash

# Hook input is JSON from stdin
input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name')
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Only run for git commit commands
if [[ "$tool_name" != "Bash" ]] || [[ ! "$command" =~ git[[:space:]]+(commit|cherry-pick|merge|rebase) ]]; then
    exit 0
fi

cd "$CLAUDE_PROJECT_DIR" || exit 1

echo "Running pre-commit checks..." >&2

# Generate RBS and run all checks
if ! "$CLAUDE_PROJECT_DIR/bin/rbs-inline" --opt-out --output=sig/ lib/ >&2; then
    echo "Error: RBS generation failed" >&2
    exit 2
fi

if ! "$CLAUDE_PROJECT_DIR/bin/rake" >&2; then
    echo "Error: rake checks failed" >&2
    exit 2
fi

echo "All checks passed!" >&2
exit 0
