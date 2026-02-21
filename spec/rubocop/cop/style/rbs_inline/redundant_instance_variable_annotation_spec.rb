# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::RedundantInstanceVariableAnnotation, :config do
  context 'with attr_reader' do
    context 'when both @rbs ivar type and inline annotation are present' do
      it 'registers an offense on the ivar type annotation' do
        expect_offense(<<~RUBY)
          # @rbs @foo: Integer
          ^^^^^^^^^^^^^^^^^^^^ Redundant instance variable type annotation. `attr_*` already declares the type inline.

          attr_reader :foo #: Integer
        RUBY

        expect_correction(<<~RUBY)
          attr_reader :foo #: Integer
        RUBY
      end
    end

    context 'when ivar type annotation is immediately before attr_reader' do
      it 'registers an offense on the ivar type annotation' do
        expect_offense(<<~RUBY)
          # @rbs @foo: Integer
          ^^^^^^^^^^^^^^^^^^^^ Redundant instance variable type annotation. `attr_*` already declares the type inline.
          attr_reader :foo #: Integer
        RUBY

        expect_correction(<<~RUBY)
          attr_reader :foo #: Integer
        RUBY
      end
    end

    context 'when only inline annotation is present without ivar type declaration' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          attr_reader :foo #: Integer
        RUBY
      end
    end

    context 'when ivar type annotation is present with attr_reader but no inline annotation' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs @foo: Integer

          attr_reader :foo
        RUBY
      end
    end
  end

  context 'with attr_writer' do
    context 'when both @rbs ivar type and inline annotation are present' do
      it 'registers an offense on the ivar type annotation' do
        expect_offense(<<~RUBY)
          # @rbs @foo: Integer
          ^^^^^^^^^^^^^^^^^^^^ Redundant instance variable type annotation. `attr_*` already declares the type inline.

          attr_writer :foo #: Integer
        RUBY

        expect_correction(<<~RUBY)
          attr_writer :foo #: Integer
        RUBY
      end
    end
  end

  context 'with attr_accessor' do
    context 'when both @rbs ivar type and inline annotation are present' do
      it 'registers an offense on the ivar type annotation' do
        expect_offense(<<~RUBY)
          # @rbs @foo: Integer
          ^^^^^^^^^^^^^^^^^^^^ Redundant instance variable type annotation. `attr_*` already declares the type inline.

          attr_accessor :foo #: Integer
        RUBY

        expect_correction(<<~RUBY)
          attr_accessor :foo #: Integer
        RUBY
      end
    end
  end

  context 'with multiple attributes on one line' do
    context 'when one attribute has an ivar type declaration' do
      it 'registers an offense for the matching ivar annotation' do
        expect_offense(<<~RUBY)
          # @rbs @foo: Integer
          ^^^^^^^^^^^^^^^^^^^^ Redundant instance variable type annotation. `attr_*` already declares the type inline.

          attr_reader :foo, :bar #: Integer
        RUBY

        expect_correction(<<~RUBY)
          attr_reader :foo, :bar #: Integer
        RUBY
      end
    end

    context 'when all attributes have ivar type declarations' do
      it 'registers an offense for each matching ivar annotation' do
        expect_offense(<<~RUBY)
          # @rbs @foo: Integer
          ^^^^^^^^^^^^^^^^^^^^ Redundant instance variable type annotation. `attr_*` already declares the type inline.
          # @rbs @bar: String
          ^^^^^^^^^^^^^^^^^^^ Redundant instance variable type annotation. `attr_*` already declares the type inline.

          attr_reader :foo, :bar #: Integer
        RUBY

        expect_correction(<<~RUBY)
          attr_reader :foo, :bar #: Integer
        RUBY
      end
    end
  end

  context 'when ivar type annotation uses a different variable name' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        # @rbs @bar: Integer

        attr_reader :foo #: Integer
      RUBY
    end
  end

  context 'with class scope' do
    context 'when ivar annotation and attr_* are in the same class' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class Foo
            # @rbs @foo: Integer
            ^^^^^^^^^^^^^^^^^^^^ Redundant instance variable type annotation. `attr_*` already declares the type inline.

            attr_reader :foo #: Integer
          end
        RUBY
      end
    end

    context 'when ivar annotation is in a different class from attr_*' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          class Foo
            attr_reader :foo #: Integer
          end

          class Bar
            # @rbs @foo: Integer

            def initialize
              @foo = 1
            end
          end
        RUBY
      end
    end

    context 'when ivar annotation is in outer class but attr_* is in inner class' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          class Outer
            # @rbs @foo: Integer

            class Inner
              attr_reader :foo #: Integer
            end
          end
        RUBY
      end
    end
  end

  context 'with module scope' do
    context 'when ivar annotation and attr_* are in the same module' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          module Foo
            # @rbs @foo: Integer
            ^^^^^^^^^^^^^^^^^^^^ Redundant instance variable type annotation. `attr_*` already declares the type inline.

            attr_reader :foo #: Integer
          end
        RUBY
      end
    end
  end

  context 'when the same ivar is declared via attr_reader and attr_writer' do
    it 'registers the offense only once' do
      expect_offense(<<~RUBY)
        # @rbs @foo: Integer
        ^^^^^^^^^^^^^^^^^^^^ Redundant instance variable type annotation. `attr_*` already declares the type inline.

        attr_reader :foo #: Integer
        attr_writer :foo #: Integer
      RUBY

      expect_correction(<<~RUBY)
        attr_reader :foo #: Integer
        attr_writer :foo #: Integer
      RUBY
    end
  end
end
