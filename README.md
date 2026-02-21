# rubocop-rbs_inline

rubocop-rbs_inline is a RuboCop extension that checks for [RBS::Inline](https://github.com/soutaro/rbs-inline) annotation comments in Ruby code.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add rubocop-rbs_inline
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install rubocop-rbs_inline
```

Add the following to your `.rubocop.yml`:

```
plugins:
  - rubocop-rbs_inline
```

## Available Cops

rubocop-rbs_inline provides the following cops to validate [RBS::Inline](https://github.com/soutaro/rbs-inline) annotations:

### Style/RbsInline/EmbeddedRbsSpacing

Checks that `@rbs!` comments (embedded RBS) are followed by a blank line.

RBS::Inline requires `@rbs!` comments to be standalone comments, meaning they should not have any code immediately following them. A blank line after the `@rbs!` block ensures proper separation.

**Examples:**
```ruby
# bad
# @rbs! type foo = Integer
def method
end

# good
# @rbs! type foo = Integer

def method
end
```

### Style/RbsInline/InvalidComment

Checks that annotation comments start with `#:` or `# @rbs` (not `# :` or `# rbs`).

**Examples:**
```ruby
# bad
# () -> void
# : () -> void
# rbs param: String

# good
#: () -> void
# @rbs param: String
```

### Style/RbsInline/InvalidTypes

Validates that RBS type syntax in annotations is correct and complete.

**Examples:**
```ruby
# bad
# @rbs arg: Hash[Symbol,
# @rbs &block: String

# good
# @rbs arg: Hash[Symbol, String]
# @rbs &block: () -> void
```

### Style/RbsInline/KeywordSeparator

Ensures RBS keywords (`module-self`, `inherits`, `override`, etc.) are not followed by `:`.

**Examples:**
```ruby
# bad
# @rbs module-self: String

# good
# @rbs module-self String
```

### Style/RbsInline/MissingTypeAnnotation

Enforces that method definitions and `attr_*` declarations have RBS inline type annotations.

**Configuration:**
- `EnforcedStyle` (default: `doc_style`)
  - `method_type_signature`: Requires `#:` annotation comments
  - `doc_style`: Requires `# @rbs` annotations
  - `doc_style_and_return_annotation`: Requires `# @rbs` parameters and inline `#:` return type
- `Visibility` (default: `all`)
  - `all`: Checks all methods regardless of visibility
  - `public`: Only checks public methods and `attr_*` declarations
- `IgnoreUnderscoreArguments` (default: `false`): When `true`, methods whose arguments are all underscore-prefixed are exempt from the `# @rbs` parameter annotation requirement. This reflects the rbs-inline behavior of ignoring `# @rbs _param:` doc-style annotations. Has no effect on `method_type_signature` style.

Methods annotated with `# @rbs skip` are always excluded.

**Examples (EnforcedStyle: doc_style):**
```ruby
# bad - no annotation
def greet(name)
  "Hello, #{name}"
end

# good
# @rbs name: String
# @rbs return: String
def greet(name)
  "Hello, #{name}"
end
```

**Examples (EnforcedStyle: method_type_signature):**
```ruby
# bad - no annotation
def greet(name)
  "Hello, #{name}"
end

# good
#: (String) -> String
def greet(name)
  "Hello, #{name}"
end
```

**Examples (EnforcedStyle: doc_style_and_return_annotation):**
```ruby
# bad - no annotation
def greet(name)
  "Hello, #{name}"
end

# good
# @rbs name: String
def greet(name) #: String
  "Hello, #{name}"
end
```

### Style/RbsInline/ParametersSeparator

Checks that parameter annotations use `:` as a separator between parameter name and type.

**Examples:**
```ruby
# bad
# @rbs param String
# @rbs :param String

# good
# @rbs param: String
# @rbs %a{pure}
```

### Style/RbsInline/RedundantAnnotationWithSkip

Warns when type annotations are present alongside `# @rbs skip` or `# @rbs override`. These directives instruct RBS::Inline to skip or inherit RBS generation for the method, making any additional type annotations redundant.

Detected redundant annotations include `#:` method type signatures, `# @rbs (Type) -> Type` method types, `# @rbs param:` parameter annotations, `# @rbs return:` return type annotations, and trailing `#:` inline types.

Supports unsafe autocorrect (removes the redundant annotations).

**Examples:**
```ruby
# bad - redundant method type signature with @rbs skip
# @rbs skip
#: (Integer) -> void
def method(a)
end

# bad - redundant doc-style method type with @rbs skip
# @rbs skip
# @rbs (Integer) -> void
def method(a)
end

# bad - redundant param annotation with @rbs override
# @rbs override
# @rbs a: Integer
def method(a)
end

# bad - redundant trailing return type with @rbs skip
# @rbs skip
def method(a) #: void
end

# good
# @rbs skip
def method(a)
end

# good
# @rbs override
def method(a)
end
```

### Style/RbsInline/RedundantArgumentType

Detects redundant argument type specifications when both `#:` annotation comments and `# @rbs` parameter comments exist.

**Configuration:** `EnforcedStyle` (default: `doc_style`)
- `method_type_signature`: Prefers `#:` annotation comments with parameter types
- `doc_style`: Prefers `# @rbs param:` annotations

**Examples (EnforcedStyle: doc_style):**
```ruby
# bad - both annotation comment and @rbs param
# @rbs a: Integer
#: (Integer) -> void
def method(a)
end

# good
# @rbs a: Integer
def method(a) #: void
end
```

**Examples (EnforcedStyle: method_type_signature):**
```ruby
# bad - both annotation comment and @rbs param
# @rbs a: Integer
#: (Integer) -> void
def method(a)
end

# good
#: (Integer) -> void
def method(a)
end
```

### Style/RbsInline/RedundantReturnType

Detects redundant return type specifications when multiple return type annotations exist.

**Configuration:** `EnforcedStyle` (default: `return_type_annotation`)
- `method_type_signature`: Prefers `#:` annotation comments before the method
- `return_type_annotation`: Prefers inline `#:` return type on the def line
- `doc_style`: Prefers `# @rbs return:` annotations

**Examples (EnforcedStyle: return_type_annotation):**
```ruby
# bad - multiple return type specifications
#: () -> String
def method(arg) #: String
end

# good - single inline return type
def method(arg) #: String
end
```

**Examples (EnforcedStyle: method_type_signature):**
```ruby
# bad - multiple return type specifications
#: () -> String
def method(arg) #: String
end

# good - annotation comment with return type
#: () -> String
def method(arg)
end
```

**Examples (EnforcedStyle: doc_style):**
```ruby
# bad - multiple return type specifications
# @rbs return: String
def method(arg) #: String
end

# good - @rbs return annotation
# @rbs return: String
def method(arg)
end
```

### Style/RbsInline/RequireRbsInlineComment

Enforces presence or absence of `# rbs_inline:` magic comment for consistency.

**Configuration:** `EnforcedStyle` (default: `always`)
- `always`: Requires `# rbs_inline: enabled` or `# rbs_inline: disabled`
- `never`: Forbids `# rbs_inline: enabled` (allows `# rbs_inline: disabled`)

**Examples (EnforcedStyle: always):**
```ruby
# bad
class Foo
end

# good
# rbs_inline: enabled
class Foo
end
```

### Style/RbsInline/UnmatchedAnnotations

Verifies that annotation parameters match the actual method parameters.

**Examples:**
```ruby
# bad
# @rbs unknown: String
def method(arg); end

# good
# @rbs arg: String
def method(arg); end
```

## Configuration

You can customize cop behavior in your `.rubocop.yml`. For example:

```yaml
# Prefer method type signatures over doc-style annotations
Style/RbsInline/RedundantArgumentType:
  EnforcedStyle: method_type_signature

Style/RbsInline/RedundantReturnType:
  EnforcedStyle: method_type_signature

# Only require annotations on public methods
Style/RbsInline/MissingTypeAnnotation:
  Visibility: public
```

See [config/default.yml](config/default.yml) for all available configuration options.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and add Git tag named `vX.Y.Z` and push it to the GitHub.  Then GitHub Actions will be release the package to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tk0miya/rubocop-rbs_inline. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/tk0miya/rubocop-rbs_inline/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the rubocop-rbs_inline project's codebases and issue trackers is expected to follow the [code of conduct](https://github.com/tk0miya/rubocop-rbs_inline/blob/main/CODE_OF_CONDUCT.md).
