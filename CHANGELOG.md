# Changelog

## 1.5.0 (unreleased)

### New Cops

- **Style/RbsInline/RedundantReturnType**: Warns when both a `# @rbs return` comment and a `#:` annotation comment specify the return type for the same method. The `EnforcedStyle` option accepts `inline_comment` (prefer `#:`) or `rbs_return_comment` (prefer `# @rbs return`). Supports safe autocorrect.
- **Style/RbsInline/RedundantArgumentType**: Warns when both a `# @rbs param` comment and a `#:` annotation comment specify the argument type for the same method. The `EnforcedStyle` option accepts `annotation_comment` or `rbs_param_comment` (default). Supports autocorrect when `annotation_comment` style is preferred.
- **Style/RbsInline/MissingTypeAnnotation**: Warns when a method definition has no type annotation. The `Visibility` option narrows the target methods by visibility (default: `all`).
- **Style/RbsInline/RequireRbsInlineComment**: Enforces the presence or absence of a `# rbs_inline:` magic comment. The `EnforcedStyle` option accepts `always` (default, requires the comment) or `never` (forbids the comment).
- **Style/RbsInline/EmbeddedRbsSpacing**: Warns when a `@rbs!` embedded RBS comment block is not followed by a blank line. Supports autocorrect.
- **Style/RbsInline/VariableCommentSpacing**: Warns when a `@rbs` variable comment (`@ivar`, `@@cvar`, `self.@ivar`) is not followed by a blank line. Supports autocorrect.
- **Style/RbsInline/MethodCommentSpacing**: Warns when a method-related `@rbs` annotation (`param`, `return`, `&block`, `override`, `skip`, etc.) is not placed immediately before the method definition it describes.
- **Style/RbsInline/MissingDataClassAnnotation**: Warns when an attribute passed to `Data.define` does not have a trailing `#:` inline type annotation. Supports autocorrect.
- **Style/RbsInline/DataClassCommentAlignment**: Warns when the `#:` inline type annotation comments in a multiline `Data.define` block are not aligned to the same column. Supports autocorrect.

### Enhancements

- **InvalidComment**: Added autocorrect support.
- **KeywordSeparator**: Added autocorrect support.
- **ParametersSeparator**: Added autocorrect support.

### Dependency Updates

- Updated rbs-inline to 0.13.0.
- Raised minimum Ruby version to 3.3.0.
