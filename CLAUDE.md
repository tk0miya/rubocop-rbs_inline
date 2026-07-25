# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

rubocop-rbs_inline is a RuboCop extension gem that provides cops for validating RBS::Inline type annotation comments in Ruby code. It checks syntax, formatting, and redundancy of `#:` and `# @rbs` style annotations.

## Common Commands

```bash
# Run tests
bundle exec rspec
bundle exec rspec spec/rubocop/cop/style/rbs_inline/invalid_comment_spec.rb      # single file
bundle exec rspec spec/rubocop/cop/style/rbs_inline/invalid_comment_spec.rb:8     # single example

# Lint
bundle exec rake rubocop
bundle exec rake rubocop:autocorrect       # safe autocorrect
bundle exec rake rubocop:autocorrect_all   # all autocorrect

# Type check
bundle exec rake steep                     # runs steep check
bundle exec rake rbs:validate              # validates RBS signatures

# Default rake task (rubocop, specs, steep, rbs:validate)
bundle exec rake

# Generate a new cop
bundle exec rake 'new_cop[Style/RbsInline/CopName]'
```

## Architecture

### Cop Structure

All cops live under the `RuboCop::Cop::Style::RbsInline` namespace in `lib/rubocop/cop/style/rbs_inline/`, one cop per file. `config/default.yml` lists every cop and its options; read it instead of a list kept here.

The other files in that directory are shared modules:

- **`ASTUtils`** - node-level helpers.
- **`SourceCodeHelper`** - `processed_source` access, Prism-to-`Parser::Source::Range` conversion.
- **`CommentParser`** - parses annotations and locates them relative to a method definition.
- **`DataStructHelper`** - helpers over a matched `Data.define` / `Struct.new` node.
- **`ClassCommentAlignment`**, **`MissingClassAnnotation`** - shared by the `Data` / `Struct` cop pairs.
- **`FileFilter`** - the `Mode` (opt-in / opt-out) file filter.

Conventions:

- `FileFilter` is `prepend`ed, not included, so it can short-circuit before the cop parses. Every cop prepends it except `RequireRbsInlineComment`.
- `Data.define` and `Struct.new` cops come in pairs sharing a base module. Behavior belongs in the module; only the node matcher and `MSG` in the cop.

### Plugin System

The gem integrates with RuboCop via LintRoller (`lib/rubocop/rbs_inline/plugin.rb`), which points RuboCop at `config/default.yml`.

### Type Signatures

`sig/` is generated from `lib/` by the hooks in `.claude/hooks/`. Never write anything under `sig/`.

### Testing Pattern

Tests use RuboCop's RSpec support helpers (`expect_offense` / `expect_no_offenses`). Test files mirror the cop file structure under `spec/rubocop/cop/style/rbs_inline/`.

`:config` specs build a bare `RuboCop::Config`, so `config/default.yml` and RuboCop's department-to-cop defaults are not merged in. A spec that sets a value at the department level proves nothing about how it resolves in a real run.

## Code Style Notes

- `Layout/LeadingCommentSpace` and `Style/CommentedKeyword` are disabled because RBS::Inline `#:` comments violate these rules by design.
- Max line length: 120 characters.
- The codebase itself uses RBS::Inline annotations (`#:` and `# @rbs` comments) for type definitions.
