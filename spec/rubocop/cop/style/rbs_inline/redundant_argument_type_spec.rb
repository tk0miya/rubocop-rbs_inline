# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::RedundantArgumentType, :config do
  context 'when EnforcedStyle is annotation_comment' do
    let(:config) do
      RuboCop::Config.new(
        'Style/RbsInline/RedundantArgumentType' => {
          'EnforcedStyle' => 'annotation_comment',
          'SupportedStyles' => %w[annotation_comment rbs_param_comment]
        }
      )
    end

    context 'when both #: with params and # @rbs param: are present' do
      it 'registers an offense on the # @rbs param: annotation' do
        expect_offense(<<~RUBY)
          # @rbs a: Integer
          ^^^^^^^^^^^^^^^^^ Redundant `@rbs` parameter annotation.
          #: (Integer) -> void
          def method(a)
          end
        RUBY

        expect_correction(<<~RUBY)
          #: (Integer) -> void
          def method(a)
          end
        RUBY
      end
    end

    context 'when both #: with params and # @rbs param: are present on a singleton method' do
      it 'registers an offense on the # @rbs param: annotation' do
        expect_offense(<<~RUBY)
          # @rbs a: Integer
          ^^^^^^^^^^^^^^^^^ Redundant `@rbs` parameter annotation.
          #: (Integer) -> void
          def self.method(a)
          end
        RUBY

        expect_correction(<<~RUBY)
          #: (Integer) -> void
          def self.method(a)
          end
        RUBY
      end
    end

    context 'when multiple # @rbs param: annotations are present' do
      it 'registers an offense on each # @rbs param: annotation' do
        expect_offense(<<~RUBY)
          # @rbs a: Integer
          ^^^^^^^^^^^^^^^^^ Redundant `@rbs` parameter annotation.
          # @rbs b: String
          ^^^^^^^^^^^^^^^^ Redundant `@rbs` parameter annotation.
          #: (Integer, String) -> void
          def method(a, b)
          end
        RUBY

        expect_correction(<<~RUBY)
          #: (Integer, String) -> void
          def method(a, b)
          end
        RUBY
      end
    end

    context 'when # @rbs &block: and #: with block are present' do
      it 'registers an offense on the # @rbs &block: annotation' do
        expect_offense(<<~RUBY)
          # @rbs &block: () -> void
          ^^^^^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs` parameter annotation.
          #: () { () -> void } -> void
          def method(&block)
          end
        RUBY

        expect_correction(<<~RUBY)
          #: () { () -> void } -> void
          def method(&block)
          end
        RUBY
      end
    end

    context 'when # @rbs param: and # @rbs return: are mixed with #:' do
      it 'registers an offense only on the # @rbs param: annotation' do
        expect_offense(<<~RUBY)
          # @rbs a: Integer
          ^^^^^^^^^^^^^^^^^ Redundant `@rbs` parameter annotation.
          # @rbs return: String
          #: (Integer) -> String
          def method(a)
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs return: String
          #: (Integer) -> String
          def method(a)
          end
        RUBY
      end
    end

    context 'when multi-line #: with params and # @rbs param: are present' do
      it 'registers an offense on the # @rbs param: annotation' do
        expect_offense(<<~RUBY)
          # @rbs a: Integer
          ^^^^^^^^^^^^^^^^^ Redundant `@rbs` parameter annotation.
          #: (Integer)
          #:   -> void
          def method(a)
          end
        RUBY

        expect_correction(<<~RUBY)
          #: (Integer)
          #:   -> void
          def method(a)
          end
        RUBY
      end
    end

    context 'when only #: with params is present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          #: (Integer) -> void
          def method(a)
          end
        RUBY
      end
    end

    context 'when only # @rbs param: is present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs a: Integer
          def method(a) #: void
          end
        RUBY
      end
    end

    context 'when no annotations are present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def method(a)
          end
        RUBY
      end
    end
  end

  context 'when EnforcedStyle is rbs_param_comment' do
    let(:config) do
      RuboCop::Config.new(
        'Style/RbsInline/RedundantArgumentType' => {
          'EnforcedStyle' => 'rbs_param_comment',
          'SupportedStyles' => %w[annotation_comment rbs_param_comment]
        }
      )
    end

    context 'when both #: with params and # @rbs param: are present' do
      it 'registers an offense on the #: annotation' do
        expect_offense(<<~RUBY)
          # @rbs a: Integer
          #: (Integer) -> void
          ^^^^^^^^^^^^^^^^^^^^ Redundant annotation comment.
          def method(a)
          end
        RUBY

        expect_no_corrections
      end
    end

    context 'when both #: with params and # @rbs param: are present on a singleton method' do
      it 'registers an offense on the #: annotation' do
        expect_offense(<<~RUBY)
          # @rbs a: Integer
          #: (Integer) -> void
          ^^^^^^^^^^^^^^^^^^^^ Redundant annotation comment.
          def self.method(a)
          end
        RUBY

        expect_no_corrections
      end
    end

    context 'when multiple # @rbs param: annotations and #: are present' do
      it 'registers an offense on the #: annotation' do
        expect_offense(<<~RUBY)
          # @rbs a: Integer
          # @rbs b: String
          #: (Integer, String) -> void
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Redundant annotation comment.
          def method(a, b)
          end
        RUBY

        expect_no_corrections
      end
    end

    context 'when multi-line #: with params and # @rbs param: are present' do
      it 'registers an offense on the #: annotation' do
        expect_offense(<<~RUBY)
          # @rbs a: Integer
          #: (Integer)
          ^^^^^^^^^^^^ Redundant annotation comment.
          #:   -> void
          def method(a)
          end
        RUBY

        expect_no_corrections
      end
    end

    context 'when only #: with params is present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          #: (Integer) -> void
          def method(a)
          end
        RUBY
      end
    end

    context 'when only # @rbs param: is present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs a: Integer
          def method(a) #: void
          end
        RUBY
      end
    end

    context 'when no annotations are present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def method(a)
          end
        RUBY
      end
    end
  end
end
