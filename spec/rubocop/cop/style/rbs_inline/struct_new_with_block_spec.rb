# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::StructNewWithBlock, :config do
  let(:config) { RuboCop::Config.new }

  it "registers an offense when Struct.new is called with a do...end block" do
    expect_offense(<<~RUBY)
      User = Struct.new(:name, :role) do
             ^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/StructNewWithBlock: Do not use `Struct.new` with a block. RBS::Inline does not parse block contents, so methods defined in the block will not be recognized. Use a separate class definition instead.
        def admin?
          role == :admin
        end
      end
    RUBY
  end

  it "registers an offense when Struct.new is called with a brace block" do
    expect_offense(<<~RUBY)
      User = Struct.new(:name, :role) { }
             ^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/StructNewWithBlock: Do not use `Struct.new` with a block. RBS::Inline does not parse block contents, so methods defined in the block will not be recognized. Use a separate class definition instead.
    RUBY
  end

  it "registers an offense when Struct.new with no args is called with a block" do
    expect_offense(<<~RUBY)
      Empty = Struct.new do
              ^^^^^^^^^^ Style/RbsInline/StructNewWithBlock: Do not use `Struct.new` with a block. RBS::Inline does not parse block contents, so methods defined in the block will not be recognized. Use a separate class definition instead.
        def foo
          42
        end
      end
    RUBY
  end

  it "does not register an offense when Struct.new is called without a block" do
    expect_no_offenses(<<~RUBY)
      User = Struct.new(:name, :role)
    RUBY
  end

  it "does not register an offense when class is reopened separately" do
    expect_no_offenses(<<~RUBY)
      User = Struct.new(:name, :role)

      class User
        def admin?
          role == :admin
        end
      end
    RUBY
  end

  it "does not register an offense for other new calls with a block" do
    expect_no_offenses(<<~RUBY)
      Foo.new(:name) do
      end
    RUBY
  end

  it "does not register an offense for Data.define with a block" do
    expect_no_offenses(<<~RUBY)
      Foo = Data.define(:name) do
      end
    RUBY
  end
end
