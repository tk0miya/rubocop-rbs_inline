#!/bin/bash
set -eu

if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
  eval "$(rbenv init - bash)"

  # Set the latest installed Ruby version as the global default
  rbenv global `rbenv versions --bare | sort -rV | head -1`

  echo 'eval "$(rbenv init - bash)"' >> "$CLAUDE_ENV_FILE"
  echo 'export RUBYOPT="-rcgi"' >> "$CLAUDE_ENV_FILE"
  RUBYOPT="-rcgi" bundle install
  bundle exec rbs collection install --frozen
fi
