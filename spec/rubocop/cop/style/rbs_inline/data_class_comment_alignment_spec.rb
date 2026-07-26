# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::DataClassCommentAlignment, :config do
  let(:config) { rbs_inline_config }

  context "when an annotation is too close" do
    it "registers an offense and corrects it" do
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
  end

  context "when an annotation is too far" do
    it "registers an offense and corrects it" do
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
  end

  context "when multiple annotations are misaligned" do
    it "registers offenses and corrects them" do
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
  end

  context "when all annotations are already aligned" do
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

  context "when there are no annotations" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        MethodEntry = Data.define(
          :name,
          :node,
          :visibility
        )
      RUBY
    end
  end

  context "when only one attribute has an annotation" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        AggregatedResult = Data.define(
          :results,
          :errors  #: Array[String]
        )
      RUBY
    end
  end

  context "when there is only one attribute with an annotation" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        Foo = Data.define(
          :bar  #: String
        )
      RUBY
    end
  end

  context "with folded Data.define" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        MethodEntry = Data.define(:name, :node, :visibility)
      RUBY
    end
  end

  context "with attributes folded inside parentheses" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        MethodEntry = Data.define(
          :name, :node, :visibility
        )
      RUBY
    end
  end

  context "with other method calls named define" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        Foo.define(
          :name, #: Symbol
          :node, #: Parser::AST::Node
        )
      RUBY
    end
  end

  context "with splat arguments" do
    it "handles them correctly" do
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
          :foo,  #: Integer
          :bar,  #: String
          *QUX_QUUX
        )
      RUBY
    end
  end
end
