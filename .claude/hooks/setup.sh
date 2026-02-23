#!/bin/bash
set -euo pipefail

# Only run in Claude Code on the web (remote environment)
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Bundler 4.0 + Ruby 3.3 compatibility workaround:
# Bundler 4.0's vendored net-http-persistent uses CGI.unescape which
# references @@accept_charset before it's initialized in Ruby 3.3.
# Pre-loading the CGI library via RUBYOPT resolves this.
echo 'export RUBYOPT="-rcgi"' >> "$CLAUDE_ENV_FILE"

RUBYOPT="-rcgi" bundle install
