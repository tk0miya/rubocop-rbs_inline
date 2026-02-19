# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::MissingDataClassAnnotation, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense for each attribute missing an inline type annotation' do
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
  end

  it 'registers an offense for one-liner Data.define' do
    expect_offense(<<~RUBY)
      MethodEntry = Data.define(:name, :node, :visibility)
                                ^^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
                                       ^^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
                                              ^^^^^^^^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
    RUBY
  end

  it 'registers an offense only for attributes without inline type annotations' do
    expect_offense(<<~RUBY)
      MethodEntry = Data.define(
        :name,       #: Symbol
        :node,
        ^^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
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
