# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

rubocop-rbs_inline is a RuboCop extension gem that provides cops for validating RBS::Inline type annotation comments in Ruby code. It checks syntax, formatting, and redundancy of `#:` and `# @rbs` style annotations.

## Common Commands

```bash
# Run tests
bin/rspec
bin/rspec spec/rubocop/cop/style/rbs_inline/invalid_comment_spec.rb      # single file
bin/rspec spec/rubocop/cop/style/rbs_inline/invalid_comment_spec.rb:8     # single example

# Lint
bin/rake rubocop
bin/rake rubocop:autocorrect       # safe autocorrect
bin/rake rubocop:autocorrect_all   # all autocorrect

# Type check
bin/rake rbs:check                 # runs steep check

# Default rake task (rubocop + type check, does NOT run specs)
bin/rake

# Generate a new cop
bin/rake 'new_cop[Style/RbsInline/CopName]'
```

## Architecture

### Cop Structure

All cops live under `RuboCop::Cop::Style::RbsInline` namespace in `lib/rubocop/cop/style/rbs_inline/`. Each cop validates a different aspect of RBS::Inline annotations:

- **InvalidComment** - Validates `#:` and `# @rbs` comment syntax
- **InvalidTypes** - Validates RBS type syntax in annotations
- **KeywordSeparator** - Ensures keywords like `module-self` aren't followed by `:`
- **ParametersSeparator** - Ensures parameter annotations use `:` separator
- **RedundantArgumentType** - Detects redundant argument type specs (configurable style)
- **RedundantReturnType** - Detects redundant return type specs (3 style options)
- **UnmatchedAnnotations** - Ensures annotation parameters match actual method parameters

### Shared CommentParser Module

`comment_parser.rb` is a module mixed into cops that need to parse RBS::Inline annotations. It uses `RBS::Inline::AnnotationParser` and Prism to parse comments, and provides helpers for finding leading annotations, inline comments, and return annotations relative to method definitions.

### Plugin System

The gem integrates with RuboCop via LintRoller (`lib/rubocop/rbs_inline/plugin.rb`). Default cop configuration is in `config/default.yml`.

### Type Signatures

RBS type signatures for all source files are maintained in `sig/` directory. The project uses Steep for static type checking, configured via `Steepfile`.

### Testing Pattern

Tests use RuboCop's RSpec support helpers (`expect_offense` / `expect_no_offenses`). Test files mirror the cop file structure under `spec/rubocop/cop/style/rbs_inline/`.

## Code Style Notes

- `Layout/LeadingCommentSpace` and `Style/CommentedKeyword` are disabled because RBS::Inline `#:` comments violate these rules by design.
- Max line length: 120 characters.
- The codebase itself uses RBS::Inline annotations (`#:` and `# @rbs` comments) for type definitions.
