# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::DataClassCommentAlignment, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense and corrects an annotation that is too close' do
    expect_offense(<<~RUBY)
      MethodEntry = Data.define(
        :name, #: Symbol
               ^^^^^^^^^ Style/RbsInline/DataClassCommentAlignment: Misaligned inline type annotation for Data attribute.
        :node,       #: Parser::AST::Node
        :visibility  #: Symbol
      )
    RUBY

    expect_correction(<<~RUBY)
      MethodEntry = Data.define(
        :name,       #: Symbol
        :node,       #: Parser::AST::Node
        :visibility  #: Symbol
      )
    RUBY
  end

  it 'registers an offense and corrects an annotation that is too far' do
    expect_offense(<<~RUBY)
      MethodEntry = Data.define(
        :name,           #: Symbol
                         ^^^^^^^^^ Style/RbsInline/DataClassCommentAlignment: Misaligned inline type annotation for Data attribute.
        :node,       #: Parser::AST::Node
        :visibility  #: Symbol
      )
    RUBY

    expect_correction(<<~RUBY)
      MethodEntry = Data.define(
        :name,       #: Symbol
        :node,       #: Parser::AST::Node
        :visibility  #: Symbol
      )
    RUBY
  end

  it 'registers offenses and corrects multiple misaligned annotations' do
    expect_offense(<<~RUBY)
      MethodEntry = Data.define(
        :name, #: Symbol
               ^^^^^^^^^ Style/RbsInline/DataClassCommentAlignment: Misaligned inline type annotation for Data attribute.
        :node, #: Parser::AST::Node
               ^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/DataClassCommentAlignment: Misaligned inline type annotation for Data attribute.
        :visibility #: Symbol
                    ^^^^^^^^^ Style/RbsInline/DataClassCommentAlignment: Misaligned inline type annotation for Data attribute.
      )
    RUBY

    expect_correction(<<~RUBY)
      MethodEntry = Data.define(
        :name,       #: Symbol
        :node,       #: Parser::AST::Node
        :visibility  #: Symbol
      )
    RUBY
  end

  it 'does not register an offense when all annotations are already aligned' do
    expect_no_offenses(<<~RUBY)
      MethodEntry = Data.define(
        :name,       #: Symbol
        :node,       #: Parser::AST::Node
        :visibility  #: Symbol
      )
    RUBY
  end

  it 'does not register an offense when there are no annotations' do
    expect_no_offenses(<<~RUBY)
      MethodEntry = Data.define(
        :name,
        :node,
        :visibility
      )
    RUBY
  end

  it 'does not register an offense for folded Data.define' do
    expect_no_offenses(<<~RUBY)
      MethodEntry = Data.define(:name, :node, :visibility)
    RUBY
  end

  it 'does not register an offense for attributes folded inside parentheses' do
    expect_no_offenses(<<~RUBY)
      MethodEntry = Data.define(
        :name, :node, :visibility
      )
    RUBY
  end

  it 'does not register an offense for other method calls named define' do
    expect_no_offenses(<<~RUBY)
      Foo.define(
        :name, #: Symbol
        :node, #: Parser::AST::Node
      )
    RUBY
  end

  it 'handles splat arguments correctly' do
    expect_offense(<<~RUBY)
      Data.define(
        :foo, #: Integer
              ^^^^^^^^^^ Style/RbsInline/DataClassCommentAlignment: Misaligned inline type annotation for Data attribute.
        :bar, #: String
              ^^^^^^^^^ Style/RbsInline/DataClassCommentAlignment: Misaligned inline type annotation for Data attribute.
        *QUX_QUUX
      )
    RUBY

    expect_correction(<<~RUBY)
      Data.define(
        :foo,      #: Integer
        :bar,      #: String
        *QUX_QUUX
      )
    RUBY
  end
end
