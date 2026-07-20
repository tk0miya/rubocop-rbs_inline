# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::MissingStructClassAnnotation, :config do
  let(:config) { RuboCop::Config.new }

  it "registers an offense and corrects each attribute missing an inline type annotation" do
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

  it "registers an offense and corrects folded Struct.new" do
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

  it "does not register an offense when all attributes have inline type annotations" do
    expect_no_offenses(<<~RUBY)
      Point = Struct.new(
        :x,  #: Integer
        :y   #: Integer
      )
    RUBY
  end

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

  it "does not treat a leading string argument (struct name) as an attribute" do
    expect_offense(<<~RUBY)
      Point = Struct.new("Point", :x, :y)
                                  ^^ Style/RbsInline/MissingStructClassAnnotation: Missing inline type annotation for Struct attribute (e.g., `#: Type`).
                                      ^^ Style/RbsInline/MissingStructClassAnnotation: Missing inline type annotation for Struct attribute (e.g., `#: Type`).
    RUBY

    expect_correction(<<~RUBY)
      Point = Struct.new(
        "Point",
        :x,       #: untyped
        :y        #: untyped
      )
    RUBY
  end

  it "does not treat the keyword_init: keyword argument as an attribute" do
    expect_offense(<<~RUBY)
      Point = Struct.new(:x, :y, keyword_init: true)
                         ^^ Style/RbsInline/MissingStructClassAnnotation: Missing inline type annotation for Struct attribute (e.g., `#: Type`).
                             ^^ Style/RbsInline/MissingStructClassAnnotation: Missing inline type annotation for Struct attribute (e.g., `#: Type`).
    RUBY

    expect_correction(<<~RUBY)
      Point = Struct.new(
        :x,                 #: untyped
        :y,                 #: untyped
        keyword_init: true
      )
    RUBY
  end

  it "does not register an offense for Struct.new with no arguments" do
    expect_no_offenses(<<~RUBY)
      Empty = Struct.new
    RUBY
  end

  it "does not register an offense for other method calls named new" do
    expect_no_offenses(<<~RUBY)
      Foo.new(:name, :node)
    RUBY
  end

  it "does not register an offense for Data.define" do
    expect_no_offenses(<<~RUBY)
      Foo = Data.define(:name, :node)
    RUBY
  end

  it "handles splat argument in Struct.new" do
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
        :foo,      #: untyped
        :bar,      #: untyped
        :baz,      #: untyped
        *QUX_QUUX
      )
    RUBY
  end
end
