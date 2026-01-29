# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::RedundantReturnType, :config do
  let(:config) { RuboCop::Config.new('Style/RbsInline/RedundantReturnType' => cop_config) }
  let(:cop_config) { {} }

  context 'when PreferredStyle is inline_signature (default)' do
    context 'when both @rbs return and inline signature are present' do
      it 'registers an offense for @rbs return' do
        expect_offense(<<~RUBY)
          # @rbs return: String
                 ^^^^^^ Redundant `@rbs return` annotation. The return type is already specified in the inline signature `#:`.
          def method(arg) #: (Integer) -> String
          end
        RUBY

        expect_correction(<<~RUBY)
          def method(arg) #: (Integer) -> String
          end
        RUBY
      end

      it 'registers an offense when signature is on the line before method' do
        expect_offense(<<~RUBY)
          # @rbs return: String
                 ^^^^^^ Redundant `@rbs return` annotation. The return type is already specified in the inline signature `#:`.
          #: (Integer) -> String
          def method(arg)
          end
        RUBY

        expect_correction(<<~RUBY)
          #: (Integer) -> String
          def method(arg)
          end
        RUBY
      end

      it 'registers an offense for singleton method' do
        expect_offense(<<~RUBY)
          # @rbs return: String
                 ^^^^^^ Redundant `@rbs return` annotation. The return type is already specified in the inline signature `#:`.
          def self.method(arg) #: (Integer) -> String
          end
        RUBY

        expect_correction(<<~RUBY)
          def self.method(arg) #: (Integer) -> String
          end
        RUBY
      end

      it 'registers an offense with multiple annotations' do
        expect_offense(<<~RUBY)
          # @rbs arg: Integer
          # @rbs return: String
                 ^^^^^^ Redundant `@rbs return` annotation. The return type is already specified in the inline signature `#:`.
          def method(arg) #: (Integer) -> String
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs arg: Integer
          def method(arg) #: (Integer) -> String
          end
        RUBY
      end
    end

    context 'when only @rbs return is present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs return: String
          def method(arg)
          end
        RUBY
      end
    end

    context 'when only inline signature is present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def method(arg) #: (Integer) -> String
          end
        RUBY
      end

      it 'does not register an offense for standalone signature' do
        expect_no_offenses(<<~RUBY)
          #: (Integer) -> String
          def method(arg)
          end
        RUBY
      end
    end

    context 'when no return type annotations are present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs arg: Integer
          def method(arg)
          end
        RUBY
      end
    end
  end

  context 'when PreferredStyle is return_annotation' do
    let(:cop_config) { { 'PreferredStyle' => 'return_annotation' } }

    context 'when both @rbs return and inline signature are present' do
      it 'registers an offense for inline signature' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          def method(arg) #: (Integer) -> String
                          ^^^^^^^^^^^^^^^^^^^^^^ Redundant inline signature `#:`. The return type is already specified in `@rbs return` annotation.
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs return: String
          def method(arg)
          end
        RUBY
      end

      it 'registers an offense for standalone signature comment' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          #: (Integer) -> String
          ^^^^^^^^^^^^^^^^^^^^^^ Redundant inline signature `#:`. The return type is already specified in `@rbs return` annotation.
          def method(arg)
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs return: String
          def method(arg)
          end
        RUBY
      end

      it 'registers an offense for singleton method' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          def self.method(arg) #: (Integer) -> String
                               ^^^^^^^^^^^^^^^^^^^^^^ Redundant inline signature `#:`. The return type is already specified in `@rbs return` annotation.
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs return: String
          def self.method(arg)
          end
        RUBY
      end
    end

    context 'when only @rbs return is present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs return: String
          def method(arg)
          end
        RUBY
      end
    end

    context 'when only inline signature is present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def method(arg) #: (Integer) -> String
          end
        RUBY
      end
    end
  end

  context 'with complex method signatures' do
    it 'handles block signatures' do
      expect_offense(<<~RUBY)
        # @rbs return: String
               ^^^^^^ Redundant `@rbs return` annotation. The return type is already specified in the inline signature `#:`.
        def method(arg) #: (Integer) { (String) -> void } -> String
        end
      RUBY

      expect_correction(<<~RUBY)
        def method(arg) #: (Integer) { (String) -> void } -> String
        end
      RUBY
    end

    it 'handles optional block signatures' do
      expect_offense(<<~RUBY)
        # @rbs return: String
               ^^^^^^ Redundant `@rbs return` annotation. The return type is already specified in the inline signature `#:`.
        def method(arg) #: (Integer) ?{ (String) -> void } -> String
        end
      RUBY

      expect_correction(<<~RUBY)
        def method(arg) #: (Integer) ?{ (String) -> void } -> String
        end
      RUBY
    end
  end

  context 'with multibyte characters' do
    it 'handles comments with multibyte characters' do
      expect_offense(<<~RUBY)
        # Comments including multibyte characters: あいうえお
        # @rbs return: String
               ^^^^^^ Redundant `@rbs return` annotation. The return type is already specified in the inline signature `#:`.
        def method(arg) #: (Integer) -> String
        end
      RUBY

      expect_correction(<<~RUBY)
        # Comments including multibyte characters: あいうえお
        def method(arg) #: (Integer) -> String
        end
      RUBY
    end
  end
end
