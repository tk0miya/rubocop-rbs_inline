# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::DataClassAlignment, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense and corrects misaligned type annotations' do
    expect_offense(<<~RUBY)
      MethodEntry = Data.define(
        :name, #: Symbol
               ^^^^^^^^^ Style/RbsInline/DataClassAlignment: Inline type annotation is not aligned.
        :node, #: Parser::AST::Node
               ^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/DataClassAlignment: Inline type annotation is not aligned.
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

  it 'does not register an offense when annotations are already aligned' do
    expect_no_offenses(<<~RUBY)
      MethodEntry = Data.define(
        :name,       #: Symbol
        :node,       #: Parser::AST::Node
        :visibility  #: Symbol
      )
    RUBY
  end

  it 'does not register an offense for one-liner Data.define' do
    expect_no_offenses(<<~RUBY)
      Point = Data.define(:x, :y)
    RUBY
  end

  it 'does not register an offense when only one attribute has a type annotation' do
    expect_no_offenses(<<~RUBY)
      Point = Data.define(
        :x,  #: Integer
        :y
      )
    RUBY
  end

  it 'does not register an offense when no attributes have type annotations' do
    expect_no_offenses(<<~RUBY)
      Point = Data.define(
        :x,
        :y
      )
    RUBY
  end

  it 'registers an offense and corrects when some annotations are misaligned' do
    expect_offense(<<~RUBY)
      Point = Data.define(
        :x, #: Integer
            ^^^^^^^^^^ Style/RbsInline/DataClassAlignment: Inline type annotation is not aligned.
        :long_name  #: Integer
      )
    RUBY

    expect_correction(<<~RUBY)
      Point = Data.define(
        :x,         #: Integer
        :long_name  #: Integer
      )
    RUBY
  end

  it 'does not register an offense for other method calls named define' do
    expect_no_offenses(<<~RUBY)
      Foo.define(
        :name, #: Symbol
        :node  #: Node
      )
    RUBY
  end

  it 'does not register an offense for Struct.new' do
    expect_no_offenses(<<~RUBY)
      Foo = Struct.new(
        :name, #: Symbol
        :node  #: Node
      )
    RUBY
  end

  it 'does not register an offense for Data.define with no arguments' do
    expect_no_offenses(<<~RUBY)
      Empty = Data.define
    RUBY
  end

  it 'aligns annotations to the rightmost existing position' do
    expect_offense(<<~RUBY)
      Entry = Data.define(
        :short,      #: String
                     ^^^^^^^^^ Style/RbsInline/DataClassAlignment: Inline type annotation is not aligned.
        :very_long_name, #: Integer
        :mid,   #: Float
                ^^^^^^^^ Style/RbsInline/DataClassAlignment: Inline type annotation is not aligned.
      )
    RUBY

    expect_correction(<<~RUBY)
      Entry = Data.define(
        :short,          #: String
        :very_long_name, #: Integer
        :mid,            #: Float
      )
    RUBY
  end

  it 'handles attributes with only minimum spacing needed' do
    expect_offense(<<~RUBY)
      Pair = Data.define(
        :first, #: String
                ^^^^^^^^^ Style/RbsInline/DataClassAlignment: Inline type annotation is not aligned.
        :second  #: String
      )
    RUBY

    expect_correction(<<~RUBY)
      Pair = Data.define(
        :first,  #: String
        :second  #: String
      )
    RUBY
  end
end
