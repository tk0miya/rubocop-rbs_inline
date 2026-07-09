# Changelog

## Unreleased

### Enhancements

- **Style/RbsInline**: All cops now respect a shared `Mode` setting that gates whether a file is checked at all. Setting `Mode: opt_in` in the department-level config (`Style/RbsInline: Mode: opt_in`) restricts every cop to files that carry a `# rbs_inline: enabled` magic comment; `Mode: opt_out` (or no setting) preserves the previous behavior of checking every file.
- **Style/RbsInline/RequireRbsInlineComment**: Replaces `EnforcedStyle` with a `Mode` setting (`opt_in` / `opt_out`) that mirrors RBS::Inline's own mode terminology, and adds an `AllowMissingComment` option so gradual-adoption projects can keep the file filter without being forced to add a magic comment to every file.

### Deprecations

- **Style/RbsInline/RequireRbsInlineComment**: `EnforcedStyle` is deprecated in favor of `Mode`. Existing configs continue to work with a warning; migrate `EnforcedStyle: always` to `Mode: opt_in` and `EnforcedStyle: never` to `Mode: opt_out`. `EnforcedStyle` will be removed in the next major version, along with the "no filtering when `Mode` is unset" fallback — the default will become `Mode: opt_in`.

## 1.6.0 (2026-07-05)

### Changes

- All cops now exclude `spec/**/*` and `test/**/*` by default. Override with `Exclude: []` per cop to lint annotations in test code.

### Bug Fixes

- **Style/RbsInline/UntypedInstanceVariable**: No longer reports a false positive for class instance variables (assigned inside `class << self` or `def self.foo`) that have a `# @rbs self.@name: Type` annotation.

## 1.5.5 (2026-05-19)

### Bug Fixes

- **Style/RbsInline/ParametersSeparator**: No longer reports false positives for `# @rbs` method type signature annotations such as `# @rbs (Type) -> ReturnType` or `# @rbs [T] (T) -> T`.
- **Style/RbsInline/MissingTypeAnnotation**: Recognizes `# @rbs` method type signature annotations (e.g. `# @rbs (Type) -> ReturnType`) as satisfying the `method_type_signature` and `method_type_signature_or_return_annotation` styles.

## 1.5.4 (2026-03-30)

### Internal

- Extracted `ASTUtils` module to consolidate shared AST helper methods across cops.
- Removed duplicate RBS type definitions from `sig/gems` and fixed hidden type errors.
- Fixed node type annotations to use `RuboCop::AST::Node` instead of `Parser::AST::Node`.
- Removed binstubs; use `bundle exec` instead.
## 1.5.3 (2026-03-02)

### Enhancements

- **Style/RbsInline/MissingTypeAnnotation**: Added `method_type_signature_or_return_annotation` style. Methods with arguments require a leading `#:` method type signature; methods without arguments accept either a leading `#:` signature or a trailing `#:` return type annotation.

## 1.5.2 (2026-02-26)

### Bug Fixes

- **Style/RbsInline/EmbeddedRbsSpacing**: No longer reports an offense when a `@rbs!` comment appears at the end of a class or module body (i.e. immediately before `end`). Adding a blank line before `end` is not recommended in Ruby style guides.

## 1.5.1 (2026-02-24)

### Bug Fixes

- **Style/RbsInline/UntypedInstanceVariable**: No longer reports an offense for instance variables that are only read without being assigned in the class. Read-only references are excluded because the variable may be defined in a parent class, making it impossible to determine whether a type annotation is needed.

## 1.5.0 (2026-02-24)

### New Cops

- **Style/RbsInline/UntypedInstanceVariable**: Warns when an instance variable used in a class or module does not have an RBS type annotation. An instance variable is considered typed when a `# @rbs @ivar: Type` annotation exists in the class body, or when it is covered by an `attr_reader`, `attr_writer`, or `attr_accessor` declaration with an inline `#: Type` comment.
- **Style/RbsInline/RedundantAnnotationWithSkip**: Warns when type annotations (`#:` method type signatures, `# @rbs` method types, parameter annotations, return type annotations, or trailing inline types) are present alongside `# @rbs skip` or `# @rbs override`. These directives skip RBS generation, making any additional type annotations redundant. Supports unsafe autocorrect.
- **Style/RbsInline/RedundantTypeAnnotation**: Warns when redundant type annotations exist for the same method definition. Detects conflicts between `#:` method type signatures, `# @rbs param:` annotations, `# @rbs return:` annotations, and trailing inline `#:` return types. The `EnforcedStyle` option accepts `method_type_signature` (prefer `#:` signatures), `doc_style` (prefer `# @rbs` annotations), or `doc_style_and_return_annotation` (prefer `# @rbs` params with trailing `#:` return type, default: `doc_style`). Supports unsafe autocorrect.
- **Style/RbsInline/MissingTypeAnnotation**: Warns when a method definition has no type annotation. The `Visibility` option narrows the target methods by visibility (default: `all`).
- **Style/RbsInline/RequireRbsInlineComment**: Enforces the presence or absence of a `# rbs_inline:` magic comment. The `EnforcedStyle` option accepts `always` (default, requires the comment) or `never` (forbids the comment).
- **Style/RbsInline/EmbeddedRbsSpacing**: Warns when a `@rbs!` embedded RBS comment block is not followed by a blank line. Supports autocorrect.
- **Style/RbsInline/VariableCommentSpacing**: Warns when a `@rbs` variable comment (`@ivar`, `@@cvar`, `self.@ivar`) is not followed by a blank line. Supports autocorrect.
- **Style/RbsInline/MethodCommentSpacing**: Warns when a method-related `@rbs` annotation (`param`, `return`, `&block`, `override`, `skip`, etc.) is not placed immediately before the method definition it describes.
- **Style/RbsInline/MissingDataClassAnnotation**: Warns when an attribute passed to `Data.define` does not have a trailing `#:` inline type annotation. Supports autocorrect.
- **Style/RbsInline/DataClassCommentAlignment**: Warns when the `#:` inline type annotation comments in a multiline `Data.define` block are not aligned to the same column. Supports autocorrect.
- **Style/RbsInline/DataDefineWithBlock**: Warns when `Data.define` is called with a block. RBS::Inline does not parse block contents, so methods defined inside will not be recognized. Users should call `Data.define` without a block and reopen the class separately to add methods.
- **Style/RbsInline/RedundantInstanceVariableAnnotation**: Warns when a `# @rbs @ivar: Type` instance variable type annotation is redundant because an `attr_*` with an inline type annotation already exists for the same attribute. Supports autocorrect.

### Enhancements

- **InvalidComment**: Added autocorrect support.
- **KeywordSeparator**: Added autocorrect support.
- **ParametersSeparator**: Added autocorrect support.

### Dependency Updates

- Updated rbs-inline to 0.13.0.
- Raised minimum Ruby version to 3.3.0.
