# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::StructClassCommentAlignment, :config do
  let(:config) { RuboCop::Config.new }

  context "with an annotation that is too close" do
    it "registers an offense and corrects it" do
      expect_offense(<<~RUBY)
        Point = Struct.new(
          :x, #: Integer
              ^^^^^^^^^^ Style/RbsInline/StructClassCommentAlignment: Misaligned inline type annotation for Struct attribute.
          :long_attr  #: Integer
        )
      RUBY

      expect_correction(<<~RUBY)
        Point = Struct.new(
          :x,         #: Integer
          :long_attr  #: Integer
        )
      RUBY
    end
  end

  context "with an annotation that is too far" do
    it "registers an offense and corrects it" do
      expect_offense(<<~RUBY)
        Point = Struct.new(
          :x,             #: Integer
                          ^^^^^^^^^^ Style/RbsInline/StructClassCommentAlignment: Misaligned inline type annotation for Struct attribute.
          :long_attr  #: Integer
        )
      RUBY

      expect_correction(<<~RUBY)
        Point = Struct.new(
          :x,         #: Integer
          :long_attr  #: Integer
        )
      RUBY
    end
  end

  context "when all annotations are already aligned" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        Point = Struct.new(
          :x,         #: Integer
          :long_attr  #: Integer
        )
      RUBY
    end
  end

  context "when there are no annotations" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        Point = Struct.new(
          :x,
          :y
        )
      RUBY
    end
  end

  context "when only one attribute has an annotation" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        Point = Struct.new(
          :x,
          :y  #: Integer
        )
      RUBY
    end
  end

  context "with a folded Struct.new" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        Point = Struct.new(:x, :y, :z)
      RUBY
    end
  end

  context "with other method calls named new" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        Foo.new(
          :x, #: Integer
          :y, #: Integer
        )
      RUBY
    end
  end

  context "with a leading string argument (struct name)" do
    it "aligns annotations accounting for it" do
      expect_no_offenses(<<~RUBY)
        Point = Struct.new(
          "Point",
          :x,       #: Integer
          :y        #: Integer
        )
      RUBY
    end
  end

  context "with splat arguments" do
    it "handles them correctly" do
      expect_offense(<<~RUBY)
        Struct.new(
          :foo, #: Integer
                ^^^^^^^^^^ Style/RbsInline/StructClassCommentAlignment: Misaligned inline type annotation for Struct attribute.
          :bar, #: String
                ^^^^^^^^^ Style/RbsInline/StructClassCommentAlignment: Misaligned inline type annotation for Struct attribute.
          *QUX_QUUX
        )
      RUBY

      expect_correction(<<~RUBY)
        Struct.new(
          :foo,      #: Integer
          :bar,      #: String
          *QUX_QUUX
        )
      RUBY
    end
  end
end
