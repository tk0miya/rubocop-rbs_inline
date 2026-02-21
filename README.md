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

### Style/RbsInline/DataClassCommentAlignment

Checks that `#:` inline type annotations in a multiline `Data.define` call are aligned to the same column. The expected column is determined by the longest attribute name (plus its trailing comma). Folded `Data.define` calls (where multiple attributes share a line) are excluded.

Supports autocorrect.

**Examples:**
```ruby
# bad
MethodEntry = Data.define(
  :name, #: Symbol
  :node,       #: Parser::AST::Node
  :visibility  #: Symbol
)

# good
MethodEntry = Data.define(
  :name,       #: Symbol
  :node,       #: Parser::AST::Node
  :visibility  #: Symbol
)
```

### Style/RbsInline/DataDefineWithBlock

Checks for `Data.define` calls with a block. RBS::Inline does not parse block contents, so any methods defined inside the block will not be recognized for type checking. Instead, call `Data.define` without a block and reopen the class separately to add methods.

**Examples:**
```ruby
# bad
User = Data.define(:name, :role) do
  def admin?
    role == :admin
  end
end

# good
User = Data.define(:name, :role)

class User
  def admin? #: bool
    role == :admin
  end
end
```

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

### Style/RbsInline/MethodCommentSpacing

Checks that method-related `@rbs` annotations are placed immediately before their method definition, with no blank lines in between. Also flags method-related annotations that are not followed by a method definition at all.

Method-related annotations include `# @rbs param:`, `# @rbs return:`, `# @rbs &block:`, `# @rbs override`, `# @rbs skip`, `# @rbs %a{...}`, `# @rbs (...) -> Type`, and `#: (...) -> Type`.

Supports autocorrect (removes blank lines between the annotation and the method definition).

**Examples:**
```ruby
# bad - blank line between annotation and method
# @rbs x: Integer
# @rbs return: String

def method(x)
end

# bad - annotation comment not followed by a method definition
# @rbs x: Integer
puts "something"

# good
# @rbs x: Integer
# @rbs return: String
def method(x)
end

# good
#: (Integer) -> String
def method(x)
end
```

### Style/RbsInline/MissingDataClassAnnotation

Checks that each attribute passed to `Data.define` has a trailing `#:` inline type annotation on the same line.

For folded `Data.define` calls (where multiple attributes share a line), the cop will suggest rewriting as a multiline call so each attribute can be annotated individually.

Supports autocorrect.

**Examples:**
```ruby
# bad
MethodEntry = Data.define(:name, :node, :visibility)

# bad - missing annotation for :node
MethodEntry = Data.define(
  :name,       #: Symbol
  :node,
  :visibility  #: Symbol
)

# good
MethodEntry = Data.define(
  :name,       #: Symbol
  :node,       #: Parser::AST::Node
  :visibility  #: Symbol
)
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

### Style/RbsInline/RedundantTypeAnnotation

Detects redundant type annotations when multiple type specifications exist for the same method. This covers both redundant argument type annotations (when both `#:` and `# @rbs param` specify the same parameter) and redundant return type annotations (when multiple of `#:`, trailing `#:`, and `# @rbs return` specify the return type).

Supports unsafe autocorrect.

**Configuration:** `EnforcedStyle` (default: `doc_style`)
- `method_type_signature`: Prefers `#:` annotation comments with the full method signature; `# @rbs param:` and `# @rbs return:` annotations alongside a `#:` signature are redundant
- `doc_style`: Prefers `# @rbs` annotations; `#:` method type signatures alongside `# @rbs` annotations are redundant
- `doc_style_and_return_annotation`: Prefers `# @rbs param:` annotations with a trailing inline `#:` return type; full `#:` signatures and `# @rbs return:` annotations are redundant

**Examples (EnforcedStyle: method_type_signature):**
```ruby
# bad - redundant @rbs parameter annotation
# @rbs a: Integer
#: (Integer) -> void
def method(a)
end

# bad - redundant trailing return type
#: () -> String
def method(arg) #: String
end

# good
#: (Integer) -> String
def method(a)
end
```

**Examples (EnforcedStyle: doc_style):**
```ruby
# bad - redundant #: method type signature
# @rbs a: Integer
#: (Integer) -> void
def method(a)
end

# bad - redundant trailing return type
# @rbs return: String
def method(arg) #: String
end

# good
# @rbs a: Integer
# @rbs return: String
def method(a)
end
```

**Examples (EnforcedStyle: doc_style_and_return_annotation):**
```ruby
# bad - redundant #: method type signature
# @rbs a: Integer
#: (Integer) -> String
def method(a)
end

# bad - redundant @rbs return annotation
# @rbs a: Integer
# @rbs return: String
def method(a) #: String
end

# good
# @rbs a: Integer
def method(a) #: String
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

### Style/RbsInline/UntypedInstanceVariable

Warns when an instance variable used in a class or module does not have an RBS type annotation. An instance variable is considered typed when a `# @rbs @ivar: Type` annotation exists in the class body, or when it is covered by an `attr_reader`, `attr_writer`, or `attr_accessor` declaration with an inline `#: Type` comment.

**Examples:**
```ruby
# bad
class Foo
  def bar
    @baz
  end
end

# good
class Foo
  # @rbs @baz: Integer

  def bar
    @baz
  end
end

# good
class Foo
  attr_reader :baz  #: Integer

  def bar
    @baz
  end
end
```

### Style/RbsInline/VariableCommentSpacing

Checks that `@rbs` variable comments for instance variables (`@ivar`), class variables (`@@cvar`), and class instance variables (`self.@civar`) are followed by a blank line. RBS::Inline requires these comments to be standalone, so code must not immediately follow them.

Supports autocorrect.

**Examples:**
```ruby
# bad
# @rbs @ivar: Integer
# @rbs @@cvar: Float
# @rbs self.@civar: String
def method
end

# good
# @rbs @ivar: Integer
# @rbs @@cvar: Float
# @rbs self.@civar: String

def method
end
```

## Configuration

You can customize cop behavior in your `.rubocop.yml`. For example:

```yaml
# Prefer method type signatures over doc-style annotations
Style/RbsInline/RedundantTypeAnnotation:
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
