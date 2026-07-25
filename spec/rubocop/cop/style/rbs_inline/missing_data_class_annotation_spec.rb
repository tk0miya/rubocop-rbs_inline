# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::MissingDataClassAnnotation, :config do
  let(:config) { RuboCop::Config.new }

  context "when each attribute is missing an inline type annotation" do
    it "registers an offense and corrects each attribute" do
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
  end

  context "with a folded Data.define" do
    it "registers an offense and corrects it" do
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
  end

  context "when some attributes lack inline type annotations" do
    it "registers an offense and corrects only attributes without inline type annotations" do
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
  end

  context "when all attributes have inline type annotations" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        MethodEntry = Data.define(
          :name,       #: Symbol
          :node,       #: Parser::AST::Node
          :visibility  #: Symbol
        )
      RUBY
    end
  end

  context "when attributes have existing comments using -- syntax" do
    it "preserves existing comments using -- syntax when correcting" do
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
  end

  context "when attributes are folded on the same line inside parentheses" do
    it "registers an offense and corrects them" do
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
  end

  context "when attributes are split across lines but not one per line" do
    it "registers an offense and corrects them" do
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
  end

  context "with string attributes" do
    it "registers an offense and corrects them" do
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
  end

  context "with Data.define with no arguments" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        Empty = Data.define
      RUBY
    end
  end

  context "with other method calls named define" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        Foo.define(:name, :node)
      RUBY
    end
  end

  context "with Struct.new" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        Foo = Struct.new(:name, :node)
      RUBY
    end
  end

  context "with a splat argument in Data.define" do
    it "handles the splat argument" do
      expect_offense(<<~RUBY)
        Data.define(
          :foo,
          ^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
          :bar,
          ^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
          :baz,
          ^^^^ Style/RbsInline/MissingDataClassAnnotation: Missing inline type annotation for Data attribute (e.g., `#: Type`).
          *QUX_QUUX
        )
      RUBY

      expect_correction(<<~RUBY)
        Data.define(
          :foo,  #: untyped
          :bar,  #: untyped
          :baz,  #: untyped
          *QUX_QUUX
        )
      RUBY
    end
  end
end
