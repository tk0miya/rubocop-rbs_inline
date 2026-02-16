# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::VariableCommentSpacing, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense when @rbs @ivar comment is directly followed by code' do
    expect_offense(<<~RUBY)
      # @rbs @ivar: Integer
      def method
      ^^^^^^^^^^ Style/RbsInline/VariableCommentSpacing: `@rbs` variable comment must be followed by a blank line.
      end
    RUBY

    expect_correction(<<~RUBY)
      # @rbs @ivar: Integer

      def method
      end
    RUBY
  end

  it 'registers an offense when @rbs @@cvar comment is directly followed by code' do
    expect_offense(<<~RUBY)
      # @rbs @@cvar: Float
      def method
      ^^^^^^^^^^ Style/RbsInline/VariableCommentSpacing: `@rbs` variable comment must be followed by a blank line.
      end
    RUBY

    expect_correction(<<~RUBY)
      # @rbs @@cvar: Float

      def method
      end
    RUBY
  end

  it 'registers an offense when @rbs self.@civar comment is directly followed by code' do
    expect_offense(<<~RUBY)
      # @rbs self.@civar: String
      def method
      ^^^^^^^^^^ Style/RbsInline/VariableCommentSpacing: `@rbs` variable comment must be followed by a blank line.
      end
    RUBY

    expect_correction(<<~RUBY)
      # @rbs self.@civar: String

      def method
      end
    RUBY
  end

  it 'registers an offense when multiple variable comments are directly followed by code' do
    expect_offense(<<~RUBY)
      # @rbs @ivar: Integer
      # @rbs @@cvar: Float
      # @rbs self.@civar: String
      def method
      ^^^^^^^^^^ Style/RbsInline/VariableCommentSpacing: `@rbs` variable comment must be followed by a blank line.
      end
    RUBY

    expect_correction(<<~RUBY)
      # @rbs @ivar: Integer
      # @rbs @@cvar: Float
      # @rbs self.@civar: String

      def method
      end
    RUBY
  end

  it 'does not register an offense when @rbs @ivar comment is followed by a blank line' do
    expect_no_offenses(<<~RUBY)
      # @rbs @ivar: Integer

      def method
      end
    RUBY
  end

  it 'does not register an offense when multiple variable comments are followed by a blank line' do
    expect_no_offenses(<<~RUBY)
      # @rbs @ivar: Integer
      # @rbs @@cvar: Float
      # @rbs self.@civar: String

      def method
      end
    RUBY
  end

  it 'does not register an offense when @rbs variable comment is at the end of file' do
    expect_no_offenses(<<~RUBY)
      # @rbs @ivar: Integer
    RUBY
  end

  it 'registers an offense when @rbs variable comment is followed by a class definition' do
    expect_offense(<<~RUBY)
      # @rbs @ivar: Integer
      class Foo
      ^^^^^^^^^ Style/RbsInline/VariableCommentSpacing: `@rbs` variable comment must be followed by a blank line.
      end
    RUBY

    expect_correction(<<~RUBY)
      # @rbs @ivar: Integer

      class Foo
      end
    RUBY
  end

  it 'does not register an offense with multiple variable comment blocks properly spaced' do
    expect_no_offenses(<<~RUBY)
      # @rbs @ivar1: Integer

      def method1
      end

      # @rbs @ivar2: String

      def method2
      end
    RUBY
  end

  it 'does not register an offense for non-variable @rbs comments' do
    expect_no_offenses(<<~RUBY)
      # @rbs return: Integer
      def method
      end
    RUBY
  end

  it 'registers an offense when variable comment is followed by module definition' do
    expect_offense(<<~RUBY)
      # @rbs @@config: Hash[Symbol, untyped]
      module Config
      ^^^^^^^^^^^^^ Style/RbsInline/VariableCommentSpacing: `@rbs` variable comment must be followed by a blank line.
      end
    RUBY

    expect_correction(<<~RUBY)
      # @rbs @@config: Hash[Symbol, untyped]

      module Config
      end
    RUBY
  end

  context 'with consecutive @rbs variable comments and other @rbs comments' do
    it 'registers an offense when @rbs variable is followed by method annotation without blank line' do
      expect_offense(<<~RUBY)
        # @rbs @ivar: Integer
        # @rbs return: String
        ^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/VariableCommentSpacing: `@rbs` variable comment must be followed by a blank line.
        def bar; end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs @ivar: Integer

        # @rbs return: String
        def bar; end
      RUBY
    end

    it 'does not register an offense when @rbs variable is followed by blank line before method annotation' do
      expect_no_offenses(<<~RUBY)
        # @rbs @ivar: Integer

        # @rbs return: String
        def bar; end
      RUBY
    end
  end

  context 'with class definitions' do
    it 'registers an offense when variable comments inside class are directly followed by method' do
      expect_offense(<<~RUBY)
        class Foo
          # @rbs @ivar: Integer
          # @rbs @@cvar: Float
          def method
        ^^^^^^^^^^^^ Style/RbsInline/VariableCommentSpacing: `@rbs` variable comment must be followed by a blank line.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class Foo
          # @rbs @ivar: Integer
          # @rbs @@cvar: Float

          def method
          end
        end
      RUBY
    end

    it 'does not register an offense when properly spaced inside class' do
      expect_no_offenses(<<~RUBY)
        class Foo
          # @rbs @ivar: Integer
          # @rbs @@cvar: Float

          def method
          end
        end
      RUBY
    end
  end
end
