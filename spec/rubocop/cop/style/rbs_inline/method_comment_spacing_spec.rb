# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::MethodCommentSpacing, :config do
  let(:config) do
    RuboCop::Config.new('Style/RbsInline/MethodCommentSpacing' => { 'Enabled' => true })
  end

  it 'registers an offense when method annotation has blank line before method definition' do
    expect_offense(<<~RUBY)
      # @rbs param x: Integer
      # @rbs return: String

      ^{} Remove blank line between method annotation and method definition.
      def method(x)
      end
    RUBY

    expect_correction(<<~RUBY)
      # @rbs param x: Integer
      # @rbs return: String
      def method(x)
      end
    RUBY
  end

  it 'registers an offense when method annotation is not followed by method definition' do
    expect_offense(<<~RUBY)
      # @rbs param x: Integer
      # @rbs return: String
      ^^^^^^^^^^^^^^^^^^^^^ Method-related `@rbs` annotation must be immediately before a method definition.
      puts "something"
    RUBY
  end

  it 'registers an offense for param annotation not followed by method' do
    expect_offense(<<~RUBY)
      # @rbs param x: Integer
      ^^^^^^^^^^^^^^^^^^^^^^^ Method-related `@rbs` annotation must be immediately before a method definition.
      x = 1
    RUBY
  end

  it 'registers an offense for return annotation not followed by method' do
    expect_offense(<<~RUBY)
      # @rbs return: String
      ^^^^^^^^^^^^^^^^^^^^^ Method-related `@rbs` annotation must be immediately before a method definition.
      y = 2
    RUBY
  end

  it 'does not register an offense when method annotation is immediately before method definition' do
    expect_no_offenses(<<~RUBY)
      # @rbs param x: Integer
      # @rbs return: String
      def method(x)
      end
    RUBY
  end

  it 'does not register an offense for single param annotation before method' do
    expect_no_offenses(<<~RUBY)
      # @rbs param x: Integer
      def method(x)
      end
    RUBY
  end

  it 'does not register an offense for single return annotation before method' do
    expect_no_offenses(<<~RUBY)
      # @rbs return: String
      def method
      end
    RUBY
  end

  it 'does not register an offense for non-method @rbs annotations' do
    expect_no_offenses(<<~RUBY)
      # @rbs @ivar: Integer
      # @rbs @@cvar: Float

      def method
      end
    RUBY
  end

  it 'handles multiple method definitions correctly' do
    expect_offense(<<~RUBY)
      # @rbs param x: Integer
      # @rbs return: String
      def method1(x)
      end

      # @rbs param y: Float

      ^{} Remove blank line between method annotation and method definition.
      def method2(y)
      end
    RUBY

    expect_correction(<<~RUBY)
      # @rbs param x: Integer
      # @rbs return: String
      def method1(x)
      end

      # @rbs param y: Float
      def method2(y)
      end
    RUBY
  end

  it 'handles annotation with colon after keyword' do
    expect_offense(<<~RUBY)
      # @rbs param: Integer
      # @rbs return: String

      ^{} Remove blank line between method annotation and method definition.
      def method
      end
    RUBY

    expect_correction(<<~RUBY)
      # @rbs param: Integer
      # @rbs return: String
      def method
      end
    RUBY
  end

  it 'does not register an offense when annotation is immediately before method with arguments' do
    expect_no_offenses(<<~RUBY)
      # @rbs param x: Integer
      # @rbs param y: String
      # @rbs return: Hash[Symbol, untyped]
      def method(x, y)
      end
    RUBY
  end

  it 'registers an offense when method type signature has blank line before method definition' do
    expect_offense(<<~RUBY)
      #: (Integer) -> String

      ^{} Remove blank line between method annotation and method definition.
      def method(x)
      end
    RUBY

    expect_correction(<<~RUBY)
      #: (Integer) -> String
      def method(x)
      end
    RUBY
  end

  it 'registers an offense for method type signature not followed by method' do
    expect_offense(<<~RUBY)
      #: (Integer) -> String
      ^^^^^^^^^^^^^^^^^^^^^^ Method-related `@rbs` annotation must be immediately before a method definition.
      x = 1
    RUBY
  end

  it 'does not register an offense when method type signature is immediately before method' do
    expect_no_offenses(<<~RUBY)
      #: (Integer) -> String
      def method(x)
      end
    RUBY
  end

  it 'handles mixed annotation styles correctly' do
    expect_offense(<<~RUBY)
      # @rbs param x: Integer
      #: (Integer) -> String

      ^{} Remove blank line between method annotation and method definition.
      def method(x)
      end
    RUBY

    expect_correction(<<~RUBY)
      # @rbs param x: Integer
      #: (Integer) -> String
      def method(x)
      end
    RUBY
  end

  it 'registers an offense for @rbs block annotation not followed by method' do
    expect_offense(<<~RUBY)
      # @rbs &block: (Integer) -> void
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Method-related `@rbs` annotation must be immediately before a method definition.
      x = 1
    RUBY
  end

  it 'registers an offense for @rbs override annotation not followed by method' do
    expect_offense(<<~RUBY)
      # @rbs override
      ^^^^^^^^^^^^^^^ Method-related `@rbs` annotation must be immediately before a method definition.
      x = 1
    RUBY
  end

  it 'registers an offense for @rbs %a annotation not followed by method' do
    expect_offense(<<~RUBY)
      # @rbs %a{pure}
      ^^^^^^^^^^^^^^^ Method-related `@rbs` annotation must be immediately before a method definition.
      x = 1
    RUBY
  end

  it 'registers an offense for @rbs method signature not followed by method' do
    expect_offense(<<~RUBY)
      # @rbs (Integer) -> String
      ^^^^^^^^^^^^^^^^^^^^^^^^^^ Method-related `@rbs` annotation must be immediately before a method definition.
      x = 1
    RUBY
  end

  it 'does not register an offense for @rbs block annotation before method' do
    expect_no_offenses(<<~RUBY)
      # @rbs &block: (Integer) -> void
      def method
      end
    RUBY
  end

  it 'does not register an offense for @rbs override annotation before method' do
    expect_no_offenses(<<~RUBY)
      # @rbs override
      def method
      end
    RUBY
  end

  it 'does not register an offense for @rbs %a annotation before method' do
    expect_no_offenses(<<~RUBY)
      # @rbs %a{pure}
      def method
      end
    RUBY
  end

  it 'does not register an offense for @rbs method signature before method' do
    expect_no_offenses(<<~RUBY)
      # @rbs (Integer) -> String
      def method(x)
      end
    RUBY
  end

  it 'registers an offense for @rbs skip annotation not followed by method' do
    expect_offense(<<~RUBY)
      # @rbs skip
      ^^^^^^^^^^^ Method-related `@rbs` annotation must be immediately before a method definition.
      x = 1
    RUBY
  end

  it 'registers an offense when @rbs skip annotation has blank line before method definition' do
    expect_offense(<<~RUBY)
      # @rbs skip

      ^{} Remove blank line between method annotation and method definition.
      def method
      end
    RUBY

    expect_correction(<<~RUBY)
      # @rbs skip
      def method
      end
    RUBY
  end

  it 'does not register an offense for @rbs skip annotation before method' do
    expect_no_offenses(<<~RUBY)
      # @rbs skip
      def method(x)
      end
    RUBY
  end

  it 'does not register an offense for trailing #: type assertion after attr_reader' do
    expect_no_offenses(<<~RUBY)
      attr_reader :foo #: Integer
    RUBY
  end

  it 'does not register an offense for trailing #: method type assertion after method definition' do
    expect_no_offenses(<<~RUBY)
      def method(x) #: (Integer) -> String
      end
    RUBY
  end
end
