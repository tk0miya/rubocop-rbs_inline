#!/bin/bash

# Initialize rbenv for Claude Code on the Web
eval "$(rbenv init -)"

# Install dependencies
# Note: Bundler 4.0.3 has a bug with Ruby 3.3.x causing CGI class variable errors.
# Install and use Bundler 2.x to avoid this issue.
gem install bundler -v 2.7.2 --no-document
bundle _2.7.2_ install

# Install dependencies for each gem directory (directories with .gemspec files)
for gemspec in "$CLAUDE_PROJECT_DIR"/*/*.gemspec; do
  if [[ -f "$gemspec" ]]; then
    gem_dir=$(dirname "$gemspec")
    if [[ -f "$gem_dir/Gemfile" ]]; then
      echo "Installing dependencies for $(basename "$gem_dir")..."
      (cd "$gem_dir" && bundle _2.7.2_ install)
    fi
  fi
done

# Persist environment for subsequent commands
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'eval "$(rbenv init -)"' >> "$CLAUDE_ENV_FILE"
fi

exit 0
