# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::StructClassCommentAlignment, :config do
  let(:config) { RuboCop::Config.new }

  it "registers an offense and corrects an annotation that is too close" do
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

  it "registers an offense and corrects an annotation that is too far" do
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

  it "does not register an offense when all annotations are already aligned" do
    expect_no_offenses(<<~RUBY)
      Point = Struct.new(
        :x,         #: Integer
        :long_attr  #: Integer
      )
    RUBY
  end

  it "does not register an offense when there are no annotations" do
    expect_no_offenses(<<~RUBY)
      Point = Struct.new(
        :x,
        :y
      )
    RUBY
  end

  it "does not register an offense when only one attribute has an annotation" do
    expect_no_offenses(<<~RUBY)
      Point = Struct.new(
        :x,
        :y  #: Integer
      )
    RUBY
  end

  it "does not register an offense for folded Struct.new" do
    expect_no_offenses(<<~RUBY)
      Point = Struct.new(:x, :y, :z)
    RUBY
  end

  it "does not register an offense for other method calls named new" do
    expect_no_offenses(<<~RUBY)
      Foo.new(
        :x, #: Integer
        :y, #: Integer
      )
    RUBY
  end

  it "aligns annotations accounting for a leading string argument (struct name)" do
    expect_no_offenses(<<~RUBY)
      Point = Struct.new(
        "Point",
        :x,       #: Integer
        :y        #: Integer
      )
    RUBY
  end

  it "handles splat arguments correctly" do
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
