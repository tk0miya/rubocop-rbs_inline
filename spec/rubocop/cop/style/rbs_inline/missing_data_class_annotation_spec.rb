# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::MissingDataClassAnnotation, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense and corrects each attribute missing an inline type annotation' do
    expect_offense(<<~RUBY)
      MethodEntry = Data.define(
        :name,
        ^^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
        :node,
        ^^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
        :visibility
        ^^^^^^^^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
      )
    RUBY

    expect_correction(<<~RUBY)
      MethodEntry = Data.define(
        :name,       #: untyped
        :node,       #: untyped
        :visibility  #: untyped
      )
    RUBY
  end

  it 'registers an offense and corrects folded Data.define' do
    expect_offense(<<~RUBY)
      MethodEntry = Data.define(:name, :node, :visibility)
                                ^^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
                                       ^^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
                                              ^^^^^^^^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
    RUBY

    expect_correction(<<~RUBY)
      MethodEntry = Data.define(
        :name,       #: untyped
        :node,       #: untyped
        :visibility  #: untyped
      )
    RUBY
  end

  it 'registers an offense and corrects only attributes without inline type annotations' do
    expect_offense(<<~RUBY)
      MethodEntry = Data.define(
        :name,       #: Symbol
        :node,
        ^^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
        :visibility  #: Symbol
      )
    RUBY

    expect_correction(<<~RUBY)
      MethodEntry = Data.define(
        :name,       #: Symbol
        :node,       #: untyped
        :visibility  #: Symbol
      )
    RUBY
  end

  it 'does not register an offense when all attributes have inline type annotations' do
    expect_no_offenses(<<~RUBY)
      MethodEntry = Data.define(
        :name,       #: Symbol
        :node,       #: Parser::AST::Node
        :visibility  #: Symbol
      )
    RUBY
  end

  it 'preserves existing comments using -- syntax when correcting' do
    expect_offense(<<~RUBY)
      MethodEntry = Data.define(
        :name,       # the method name
        ^^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
        :node,       #: Parser::AST::Node
        :visibility  # public, protected, or private
        ^^^^^^^^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
      )
    RUBY

    expect_correction(<<~RUBY)
      MethodEntry = Data.define(
        :name,       #: untyped -- the method name
        :node,       #: Parser::AST::Node
        :visibility  #: untyped -- public, protected, or private
      )
    RUBY
  end

  it 'registers an offense and corrects attributes folded on the same line inside parentheses' do
    expect_offense(<<~RUBY)
      MethodEntry = Data.define(
        :name, :node, :visibility
        ^^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
               ^^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
                      ^^^^^^^^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
      )
    RUBY

    expect_correction(<<~RUBY)
      MethodEntry = Data.define(
        :name,       #: untyped
        :node,       #: untyped
        :visibility  #: untyped
      )
    RUBY
  end

  it 'registers an offense and corrects attributes split across lines but not one per line' do
    expect_offense(<<~RUBY)
      MethodEntry = Data.define(:name, :node,
                                ^^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
                                       ^^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
                                :visibility)
                                ^^^^^^^^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
    RUBY

    expect_correction(<<~RUBY)
      MethodEntry = Data.define(
        :name,       #: untyped
        :node,       #: untyped
        :visibility  #: untyped
      )
    RUBY
  end

  it 'registers an offense and corrects string attributes' do
    expect_offense(<<~RUBY)
      Point = Data.define('x', 'y')
                          ^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
                               ^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
    RUBY

    expect_correction(<<~RUBY)
      Point = Data.define(
        'x',  #: untyped
        'y'   #: untyped
      )
    RUBY
  end

  it 'does not register an offense for Data.define with no arguments' do
    expect_no_offenses(<<~RUBY)
      Empty = Data.define
    RUBY
  end

  it 'does not register an offense for other method calls named define' do
    expect_no_offenses(<<~RUBY)
      Foo.define(:name, :node)
    RUBY
  end

  it 'does not register an offense for Struct.new' do
    expect_no_offenses(<<~RUBY)
      Foo = Struct.new(:name, :node)
    RUBY
  end
end
