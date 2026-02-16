# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::EmbeddedRbsSpacing, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense when @rbs! comment is directly followed by code' do
    expect_offense(<<~RUBY)
      # @rbs! type foo = Integer
      def method
      ^^^^^^^^^^ Style/RbsInline/EmbeddedRbsSpacing: `@rbs!` comment must be followed by a blank line.
      end
    RUBY

    expect_correction(<<~RUBY)
      # @rbs! type foo = Integer

      def method
      end
    RUBY
  end

  it 'registers an offense when @rbs! block is directly followed by code' do
    expect_offense(<<~RUBY)
      # @rbs! type foo = Integer
      #  type bar = String
      def method
      ^^^^^^^^^^ Style/RbsInline/EmbeddedRbsSpacing: `@rbs!` comment must be followed by a blank line.
      end
    RUBY

    expect_correction(<<~RUBY)
      # @rbs! type foo = Integer
      #  type bar = String

      def method
      end
    RUBY
  end

  it 'does not register an offense when @rbs! comment is followed by a blank line' do
    expect_no_offenses(<<~RUBY)
      # @rbs! type foo = Integer

      def method
      end
    RUBY
  end

  it 'does not register an offense when @rbs! block is followed by a blank line' do
    expect_no_offenses(<<~RUBY)
      # @rbs! type foo = Integer
      #  type bar = String

      def method
      end
    RUBY
  end

  it 'does not register an offense when @rbs! comment is at the end of file' do
    expect_no_offenses(<<~RUBY)
      # @rbs! type foo = Integer
    RUBY
  end

  it 'registers an offense when @rbs! with space is directly followed by code' do
    expect_offense(<<~RUBY)
      # @rbs! type foo = Integer
      class Foo
      ^^^^^^^^^ Style/RbsInline/EmbeddedRbsSpacing: `@rbs!` comment must be followed by a blank line.
      end
    RUBY

    expect_correction(<<~RUBY)
      # @rbs! type foo = Integer

      class Foo
      end
    RUBY
  end

  it 'does not register an offense with multiple @rbs! blocks properly spaced' do
    expect_no_offenses(<<~RUBY)
      # @rbs! type foo = Integer

      def method1
      end

      # @rbs! type bar = String

      def method2
      end
    RUBY
  end

  it 'registers an offense when multi-line @rbs! block is directly followed by code' do
    expect_offense(<<~RUBY)
      # @rbs!
      #   type foo = Integer
      #   type bar = String
      def method
      ^^^^^^^^^^ Style/RbsInline/EmbeddedRbsSpacing: `@rbs!` comment must be followed by a blank line.
      end
    RUBY

    expect_correction(<<~RUBY)
      # @rbs!
      #   type foo = Integer
      #   type bar = String

      def method
      end
    RUBY
  end

  it 'does not register an offense when multi-line @rbs! block is followed by a blank line' do
    expect_no_offenses(<<~RUBY)
      # @rbs!
      #   type foo = Integer
      #   type bar = String

      def method
      end
    RUBY
  end

  it 'registers an offense when @rbs! block with blank comment line is directly followed by code' do
    expect_offense(<<~RUBY)
      # @rbs!
      #   type foo = Integer
      #
      #   type bar = String
      def method
      ^^^^^^^^^^ Style/RbsInline/EmbeddedRbsSpacing: `@rbs!` comment must be followed by a blank line.
      end
    RUBY

    expect_correction(<<~RUBY)
      # @rbs!
      #   type foo = Integer
      #
      #   type bar = String

      def method
      end
    RUBY
  end

  it 'does not register an offense when @rbs! block with blank comment line is followed by a blank line' do
    expect_no_offenses(<<~RUBY)
      # @rbs!
      #   type foo = Integer
      #
      #   type bar = String

      def method
      end
    RUBY
  end

  context 'with consecutive @rbs! and other @rbs comments' do
    it 'registers an offense when @rbs! is followed by @rbs @ivar without blank line' do
      expect_offense(<<~RUBY)
        # @rbs! type foo = Integer
        # @rbs @ivar: Integer
        ^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/EmbeddedRbsSpacing: `@rbs!` comment must be followed by a blank line.

        def bar; end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs! type foo = Integer

        # @rbs @ivar: Integer

        def bar; end
      RUBY
    end

    it 'does not register an offense when @rbs! is followed by blank line before @rbs @ivar' do
      expect_no_offenses(<<~RUBY)
        # @rbs! type foo = Integer

        # @rbs @ivar: Integer

        def bar; end
      RUBY
    end
  end
end
