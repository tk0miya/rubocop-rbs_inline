# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::MissingStructClassAnnotation, :config do
  let(:config) { rbs_inline_config }

  context "with attributes missing inline type annotations" do
    it "registers an offense and corrects each attribute" do
      expect_offense(<<~RUBY)
        Point = Struct.new(
          :x,
          ^^ Style/RbsInline/MissingStructClassAnnotation: Missing inline type annotation for Struct attribute (e.g., `#: Type`).
          :y,
          ^^ Style/RbsInline/MissingStructClassAnnotation: Missing inline type annotation for Struct attribute (e.g., `#: Type`).
          :z
          ^^ Style/RbsInline/MissingStructClassAnnotation: Missing inline type annotation for Struct attribute (e.g., `#: Type`).
        )
      RUBY

      expect_correction(<<~RUBY)
        Point = Struct.new(
          :x,  #: untyped
          :y,  #: untyped
          :z   #: untyped
        )
      RUBY
    end
  end

  context "with a folded Struct.new" do
    it "registers an offense and corrects it" do
      expect_offense(<<~RUBY)
        Point = Struct.new(:x, :y, :z)
                           ^^ Style/RbsInline/MissingStructClassAnnotation: Missing inline type annotation for Struct attribute (e.g., `#: Type`).
                               ^^ Style/RbsInline/MissingStructClassAnnotation: Missing inline type annotation for Struct attribute (e.g., `#: Type`).
                                   ^^ Style/RbsInline/MissingStructClassAnnotation: Missing inline type annotation for Struct attribute (e.g., `#: Type`).
      RUBY

      expect_correction(<<~RUBY)
        Point = Struct.new(
          :x,  #: untyped
          :y,  #: untyped
          :z   #: untyped
        )
      RUBY
    end
  end

  context "with a mix of annotated and unannotated attributes" do
    it "registers an offense and corrects only attributes without inline type annotations" do
      expect_offense(<<~RUBY)
        Point = Struct.new(
          :x,  #: Integer
          :y,
          ^^ Style/RbsInline/MissingStructClassAnnotation: Missing inline type annotation for Struct attribute (e.g., `#: Type`).
          :z   #: Integer
        )
      RUBY

      expect_correction(<<~RUBY)
        Point = Struct.new(
          :x,  #: Integer
          :y,  #: untyped
          :z   #: Integer
        )
      RUBY
    end
  end

  context "when all attributes have inline type annotations" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        Point = Struct.new(
          :x,  #: Integer
          :y   #: Integer
        )
      RUBY
    end
  end

  context "with existing comments using -- syntax" do
    it "preserves existing comments using -- syntax when correcting" do
      expect_offense(<<~RUBY)
        Point = Struct.new(
          :x,  # the x coordinate
          ^^ Style/RbsInline/MissingStructClassAnnotation: Missing inline type annotation for Struct attribute (e.g., `#: Type`).
          :y   #: Integer
        )
      RUBY

      expect_correction(<<~RUBY)
        Point = Struct.new(
          :x,  #: untyped -- the x coordinate
          :y   #: Integer
        )
      RUBY
    end
  end

  context "with a leading string argument (struct name)" do
    it "does not treat it as an attribute" do
      expect_offense(<<~RUBY)
        Point = Struct.new("Point", :x, :y)
                                    ^^ Style/RbsInline/MissingStructClassAnnotation: Missing inline type annotation for Struct attribute (e.g., `#: Type`).
                                        ^^ Style/RbsInline/MissingStructClassAnnotation: Missing inline type annotation for Struct attribute (e.g., `#: Type`).
      RUBY

      expect_correction(<<~RUBY)
        Point = Struct.new(
          "Point",
          :x,  #: untyped
          :y   #: untyped
        )
      RUBY
    end
  end

  context "with the keyword_init: keyword argument" do
    it "does not treat it as an attribute" do
      expect_offense(<<~RUBY)
        Point = Struct.new(:x, :y, keyword_init: true)
                           ^^ Style/RbsInline/MissingStructClassAnnotation: Missing inline type annotation for Struct attribute (e.g., `#: Type`).
                               ^^ Style/RbsInline/MissingStructClassAnnotation: Missing inline type annotation for Struct attribute (e.g., `#: Type`).
      RUBY

      expect_correction(<<~RUBY)
        Point = Struct.new(
          :x,  #: untyped
          :y,  #: untyped
          keyword_init: true
        )
      RUBY
    end
  end

  context "with Struct.new with no arguments" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        Empty = Struct.new
      RUBY
    end
  end

  context "with other method calls named new" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        Foo.new(:name, :node)
      RUBY
    end
  end

  context "with Data.define" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        Foo = Data.define(:name, :node)
      RUBY
    end
  end

  context "with a splat argument in Struct.new" do
    it "handles the splat argument" do
      expect_offense(<<~RUBY)
        Struct.new(
          :foo,
          ^^^^ Style/RbsInline/MissingStructClassAnnotation: Missing inline type annotation for Struct attribute (e.g., `#: Type`).
          :bar,
          ^^^^ Style/RbsInline/MissingStructClassAnnotation: Missing inline type annotation for Struct attribute (e.g., `#: Type`).
          :baz,
          ^^^^ Style/RbsInline/MissingStructClassAnnotation: Missing inline type annotation for Struct attribute (e.g., `#: Type`).
          *QUX_QUUX
        )
      RUBY

      expect_correction(<<~RUBY)
        Struct.new(
          :foo,  #: untyped
          :bar,  #: untyped
          :baz,  #: untyped
          *QUX_QUUX
        )
      RUBY
    end
  end
end
