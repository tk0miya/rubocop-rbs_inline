# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::DataDefineWithBlock, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense when Data.define is called with a do...end block' do
    expect_offense(<<~RUBY)
      User = Data.define(:name, :role) do
             ^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/DataDefineWithBlock: Do not use `Data.define` with a block. RBS::Inline does not parse block contents, so methods defined in the block will not be recognized. Use a separate class definition instead.
        def admin?
          role == :admin
        end
      end
    RUBY
  end

  it 'registers an offense when Data.define is called with a brace block' do
    expect_offense(<<~RUBY)
      User = Data.define(:name, :role) { }
             ^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/DataDefineWithBlock: Do not use `Data.define` with a block. RBS::Inline does not parse block contents, so methods defined in the block will not be recognized. Use a separate class definition instead.
    RUBY
  end

  it 'registers an offense when Data.define with no args is called with a block' do
    expect_offense(<<~RUBY)
      Empty = Data.define do
              ^^^^^^^^^^^ Style/RbsInline/DataDefineWithBlock: Do not use `Data.define` with a block. RBS::Inline does not parse block contents, so methods defined in the block will not be recognized. Use a separate class definition instead.
        def foo
          42
        end
      end
    RUBY
  end

  it 'does not register an offense when Data.define is called without a block' do
    expect_no_offenses(<<~RUBY)
      User = Data.define(:name, :role)
    RUBY
  end

  it 'does not register an offense when class is reopened separately' do
    expect_no_offenses(<<~RUBY)
      User = Data.define(:name, :role)

      class User
        def admin?
          role == :admin
        end
      end
    RUBY
  end

  it 'does not register an offense for other define calls with a block' do
    expect_no_offenses(<<~RUBY)
      Foo.define(:name) do
      end
    RUBY
  end

  it 'does not register an offense for Struct.new with a block' do
    expect_no_offenses(<<~RUBY)
      Foo = Struct.new(:name) do
      end
    RUBY
  end
end
