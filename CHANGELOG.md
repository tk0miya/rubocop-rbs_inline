# Changelog

## 1.5.0 (unreleased)

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

### New Cops

- **Style/RbsInline/AnnotationSeparator**: Replaces the separate `KeywordSeparator` and `ParametersSeparator` cops with a single cop that checks correct use of `:` separators in `# @rbs` annotations: keywords must not be followed by `:`, while parameter names must be followed by `:`. Supports autocorrect.

### Enhancements

- **InvalidComment**: Added autocorrect support.

### Dependency Updates

- Updated rbs-inline to 0.13.0.
- Raised minimum Ruby version to 3.3.0.
