# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::UntypedInstanceVariable, :config do
  let(:config) { RuboCop::Config.new }

  context 'when instance variable has no type annotation' do
    it 'does not register an offense for an ivar read (may be defined in parent class)' do
      expect_no_offenses(<<~RUBY)
        class Foo
          def bar
            @baz
          end
        end
      RUBY
    end

    it 'registers an offense for an ivar assignment inside a method' do
      expect_offense(<<~RUBY)
        class Foo
          def bar
            @baz = 1
            ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@baz` is not typed. Add `# @rbs @baz: Type` or use `attr_* :baz #: Type`.
          end
        end
      RUBY
    end

    it 'registers an offense for multiple untyped ivar assignments' do
      expect_offense(<<~RUBY)
        class Foo
          def bar
            @baz = 1
            ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@baz` is not typed. Add `# @rbs @baz: Type` or use `attr_* :baz #: Type`.
            @qux = 2
            ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@qux` is not typed. Add `# @rbs @qux: Type` or use `attr_* :qux #: Type`.
          end
        end
      RUBY
    end

    it 'registers an offense for an ivar assignment in a module' do
      expect_offense(<<~RUBY)
        module Foo
          def bar
            @baz = 1
            ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@baz` is not typed. Add `# @rbs @baz: Type` or use `attr_* :baz #: Type`.
          end
        end
      RUBY
    end

    it 'registers an offense for an ivar in ||= expression' do
      expect_offense(<<~RUBY)
        class Foo
          def bar
            @baz ||= 1
            ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@baz` is not typed. Add `# @rbs @baz: Type` or use `attr_* :baz #: Type`.
          end
        end
      RUBY
    end

    it 'registers an offense for an ivar in initialize' do
      expect_offense(<<~RUBY)
        class Foo
          def initialize
            @baz = 1
            ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@baz` is not typed. Add `# @rbs @baz: Type` or use `attr_* :baz #: Type`.
          end
        end
      RUBY
    end

    it 'reports each ivar only once even if assigned multiple times' do
      expect_offense(<<~RUBY)
        class Foo
          def bar
            @baz = 1
            ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@baz` is not typed. Add `# @rbs @baz: Type` or use `attr_* :baz #: Type`.
          end

          def baz
            @baz = 2
          end
        end
      RUBY
    end

    it 'does not register an offense when ivar is only read (not assigned)' do
      expect_no_offenses(<<~RUBY)
        class Foo
          def bar
            @baz
          end

          def baz
            @baz
          end
        end
      RUBY
    end

    it 'does not register an offense when attr_reader has no inline type comment' do
      expect_no_offenses(<<~RUBY)
        class Foo
          attr_reader :baz

          def bar
            @baz
          end
        end
      RUBY
    end
  end

  context 'when instance variable has a @rbs annotation' do
    it 'does not register an offense with @rbs @ivar annotation' do
      expect_no_offenses(<<~RUBY)
        class Foo
          # @rbs @baz: Integer

          def bar
            @baz
          end
        end
      RUBY
    end

    it 'does not register an offense with @rbs annotation for assignment' do
      expect_no_offenses(<<~RUBY)
        class Foo
          # @rbs @baz: Integer

          def initialize
            @baz = 1
          end
        end
      RUBY
    end

    it 'does not register an offense with multiple @rbs annotations' do
      expect_no_offenses(<<~RUBY)
        class Foo
          # @rbs @baz: Integer
          # @rbs @qux: String

          def initialize
            @baz = 1
            @qux = 'hello'
          end
        end
      RUBY
    end
  end

  context 'when instance variable is covered by typed attr_*' do
    it 'does not register an offense with attr_reader and inline type' do
      expect_no_offenses(<<~RUBY)
        class Foo
          attr_reader :baz  #: Integer

          def bar
            @baz
          end
        end
      RUBY
    end

    it 'does not register an offense with attr_writer and inline type' do
      expect_no_offenses(<<~RUBY)
        class Foo
          attr_writer :baz  #: Integer

          def bar
            @baz = 1
          end
        end
      RUBY
    end

    it 'does not register an offense with attr_accessor and inline type' do
      expect_no_offenses(<<~RUBY)
        class Foo
          attr_accessor :baz  #: Integer

          def bar
            @baz
          end
        end
      RUBY
    end

    it 'does not register an offense with multiple attrs and inline types' do
      expect_no_offenses(<<~RUBY)
        class Foo
          attr_reader :baz, :qux  #: Integer

          def bar
            @baz
            @qux
          end
        end
      RUBY
    end
  end

  context 'with nested classes' do
    it 'registers an offense when only inner class annotates the ivar but outer assigns it' do
      expect_offense(<<~RUBY)
        class Outer
          class Inner
            # @rbs @baz: Integer
          end

          def foo
            @baz = 1
            ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@baz` is not typed. Add `# @rbs @baz: Type` or use `attr_* :baz #: Type`.
          end
        end
      RUBY
    end

    it 'registers an offense for the inner class ivar when only outer is annotated' do
      expect_offense(<<~RUBY)
        class Outer
          # @rbs @baz: Integer

          class Inner
            def bar
              @baz = 1
              ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@baz` is not typed. Add `# @rbs @baz: Type` or use `attr_* :baz #: Type`.
            end
          end

          def foo
            @baz = 1
          end
        end
      RUBY
    end

    it 'does not register an offense when each class annotates its own ivars' do
      expect_no_offenses(<<~RUBY)
        class Outer
          # @rbs @baz: Integer

          class Inner
            # @rbs @baz: String

            def bar
              @baz = 'hello'
            end
          end

          def foo
            @baz = 1
          end
        end
      RUBY
    end

    it 'does not register an offense when inner class ivar is typed and outer has none' do
      expect_no_offenses(<<~RUBY)
        class Outer
          class Inner
            # @rbs @baz: Integer

            def bar
              @baz = 1
            end
          end
        end
      RUBY
    end

    it 'does not register an offense for read-only ivar in outer class' do
      expect_no_offenses(<<~RUBY)
        class Outer
          class Inner
            # @rbs @baz: Integer
          end

          def foo
            @baz
          end
        end
      RUBY
    end
  end

  context 'with top-level methods (no class)' do
    it 'registers an offense for ivar assignments outside any class' do
      expect_offense(<<~RUBY)
        def bar
          @baz = 1
          ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@baz` is not typed. Add `# @rbs @baz: Type` or use `attr_* :baz #: Type`.
        end
      RUBY
    end

    it 'does not register an offense for ivar reads outside any class' do
      expect_no_offenses(<<~RUBY)
        def bar
          @baz
        end
      RUBY
    end

    it 'does not register an offense when top-level ivar has @rbs annotation' do
      expect_no_offenses(<<~RUBY)
        # @rbs @baz: Integer

        def bar
          @baz = 1
        end
      RUBY
    end
  end

  context 'with mixed typed and untyped ivars' do
    it 'only reports the untyped ivar assignment' do
      expect_offense(<<~RUBY)
        class Foo
          # @rbs @baz: Integer

          def bar
            @baz = 1
            @qux = 2
            ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@qux` is not typed. Add `# @rbs @qux: Type` or use `attr_* :qux #: Type`.
          end
        end
      RUBY
    end
  end
end
