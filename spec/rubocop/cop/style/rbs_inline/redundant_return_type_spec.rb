# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::RedundantReturnType, :config do
  context 'when EnforcedStyle is annotation_comment' do
    let(:config) do
      RuboCop::Config.new(
        'Style/RbsInline/RedundantReturnType' => {
          'EnforcedStyle' => 'annotation_comment',
          'SupportedStyles' => %w[annotation_comment inline_comment rbs_return_comment]
        }
      )
    end

    context 'when both annotation #: and inline #: are present' do
      it 'registers an offense on the inline #: annotation' do
        expect_offense(<<~RUBY)
          #: () -> String
          def method(arg) #: String
                          ^^^^^^^^^ Redundant inline return type annotation.
          end
        RUBY

        expect_correction(<<~RUBY)
          #: () -> String
          def method(arg)
          end
        RUBY
      end
    end

    context 'when both annotation #: and inline #: are present on a singleton method' do
      it 'registers an offense on the inline #: annotation' do
        expect_offense(<<~RUBY)
          #: () -> String
          def self.method(arg) #: String
                               ^^^^^^^^^ Redundant inline return type annotation.
          end
        RUBY

        expect_correction(<<~RUBY)
          #: () -> String
          def self.method(arg)
          end
        RUBY
      end
    end

    context 'when both @rbs return and annotation #: are present' do
      it 'registers an offense on the @rbs return annotation' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs return` annotation.
          #: () -> String
          def method(arg)
          end
        RUBY

        expect_correction(<<~RUBY)
          #: () -> String
          def method(arg)
          end
        RUBY
      end
    end

    context 'when both @rbs return and annotation #: are present on a singleton method' do
      it 'registers an offense on the @rbs return annotation' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs return` annotation.
          #: () -> String
          def self.method(arg)
          end
        RUBY

        expect_correction(<<~RUBY)
          #: () -> String
          def self.method(arg)
          end
        RUBY
      end
    end

    context 'when @rbs return, annotation #:, and inline #: are all present' do
      it 'registers offenses on both @rbs return and inline #:' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs return` annotation.
          #: () -> String
          def method(arg) #: String
                          ^^^^^^^^^ Redundant inline return type annotation.
          end
        RUBY

        expect_correction(<<~RUBY)
          #: () -> String
          def method(arg)
          end
        RUBY
      end
    end

    context 'when @rbs return is used with other parameter annotations and annotation #:' do
      it 'registers an offense on the @rbs return annotation' do
        expect_offense(<<~RUBY)
          # @rbs arg: Integer
          # @rbs return: String
          ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs return` annotation.
          #: (Integer) -> String
          def method(arg)
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs arg: Integer
          #: (Integer) -> String
          def method(arg)
          end
        RUBY
      end
    end

    context 'when only annotation #: is present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          #: () -> String
          def method(arg)
          end
        RUBY
      end
    end

    context 'when only inline #: is present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def method(arg) #: String
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

    context 'when no return type annotation is present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs arg: String
          def method(arg)
          end
        RUBY
      end
    end

    context 'when inline #: and @rbs return are present without annotation #:' do
      it 'registers offenses on both inline #: and @rbs return' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs return` annotation.
          def method(arg) #: String
                          ^^^^^^^^^ Redundant inline return type annotation.
          end
        RUBY

        expect_no_corrections
      end
    end

    context 'when multi-line annotation #: and inline #: are present' do
      it 'registers an offense on the inline #: annotation' do
        expect_offense(<<~RUBY)
          #: (Integer)
          #:   -> String
          def method(arg) #: String
                          ^^^^^^^^^ Redundant inline return type annotation.
          end
        RUBY

        expect_correction(<<~RUBY)
          #: (Integer)
          #:   -> String
          def method(arg)
          end
        RUBY
      end
    end
  end

  context 'when EnforcedStyle is inline_comment (default)' do
    let(:config) do
      RuboCop::Config.new(
        'Style/RbsInline/RedundantReturnType' => {
          'EnforcedStyle' => 'inline_comment',
          'SupportedStyles' => %w[annotation_comment inline_comment rbs_return_comment]
        }
      )
    end

    context 'when both @rbs return and inline #: are present' do
      it 'registers an offense on the @rbs return annotation' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs return` annotation.
          def method(arg) #: String
          end
        RUBY

        expect_correction(<<~RUBY)
          def method(arg) #: String
          end
        RUBY
      end
    end

    context 'when both @rbs return and inline #: are present on a singleton method' do
      it 'registers an offense on the @rbs return annotation' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs return` annotation.
          def self.method(arg) #: String
          end
        RUBY

        expect_correction(<<~RUBY)
          def self.method(arg) #: String
          end
        RUBY
      end
    end

    context 'when @rbs return is used with other parameter annotations' do
      it 'registers an offense on the @rbs return annotation' do
        expect_offense(<<~RUBY)
          # @rbs arg: Integer
          # @rbs return: String
          ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs return` annotation.
          def method(arg) #: String
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs arg: Integer
          def method(arg) #: String
          end
        RUBY
      end
    end

    context 'when both annotation #: and inline #: are present' do
      it 'registers an offense on the annotation #:' do
        expect_offense(<<~RUBY)
          #: () -> String
          ^^^^^^^^^^^^^^^ Redundant annotation comment.
          def method(arg) #: String
          end
        RUBY

        expect_no_corrections
      end
    end

    context 'when both annotation #: and inline #: are present on a singleton method' do
      it 'registers an offense on the annotation #:' do
        expect_offense(<<~RUBY)
          #: () -> String
          ^^^^^^^^^^^^^^^ Redundant annotation comment.
          def self.method(arg) #: String
          end
        RUBY

        expect_no_corrections
      end
    end

    context 'when @rbs return, annotation #:, and inline #: are all present' do
      it 'registers offenses on both @rbs return and annotation #:' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs return` annotation.
          #: () -> String
          ^^^^^^^^^^^^^^^ Redundant annotation comment.
          def method(arg) #: String
          end
        RUBY

        expect_correction(<<~RUBY)
          #: () -> String
          def method(arg) #: String
          end
        RUBY
      end
    end

    context 'when multi-line annotation #: and inline #: are present' do
      it 'registers an offense on the annotation #:' do
        expect_offense(<<~RUBY)
          #: (Integer)
          ^^^^^^^^^^^^ Redundant annotation comment.
          def method(arg) #: String
          end
        RUBY

        expect_no_corrections
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

    context 'when only inline #: is present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def method(arg) #: String
          end
        RUBY
      end
    end

    context 'when only annotation #: is present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          #: () -> String
          def method(arg)
          end
        RUBY
      end
    end

    context 'when no return type annotation is present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs arg: String
          def method(arg)
          end
        RUBY
      end
    end

    context 'when annotation #: and @rbs return are present without inline #:' do
      it 'registers offenses on both annotation #: and @rbs return' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs return` annotation.
          #: () -> String
          ^^^^^^^^^^^^^^^ Redundant annotation comment.
          def method(arg)
          end
        RUBY

        expect_no_corrections
      end
    end
  end

  context 'when EnforcedStyle is rbs_return_comment' do
    let(:config) do
      RuboCop::Config.new(
        'Style/RbsInline/RedundantReturnType' => {
          'EnforcedStyle' => 'rbs_return_comment',
          'SupportedStyles' => %w[annotation_comment inline_comment rbs_return_comment]
        }
      )
    end

    context 'when both @rbs return and inline #: are present' do
      it 'registers an offense on the inline #: annotation' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          def method(arg) #: String
                          ^^^^^^^^^ Redundant inline return type annotation.
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs return: String
          def method(arg)
          end
        RUBY
      end
    end

    context 'when both @rbs return and inline #: are present on a singleton method' do
      it 'registers an offense on the inline #: annotation' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          def self.method(arg) #: String
                               ^^^^^^^^^ Redundant inline return type annotation.
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs return: String
          def self.method(arg)
          end
        RUBY
      end
    end

    context 'when both @rbs return and annotation #: are present' do
      it 'registers an offense on the annotation #:' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          #: () -> String
          ^^^^^^^^^^^^^^^ Redundant annotation comment.
          def method(arg)
          end
        RUBY

        expect_no_corrections
      end
    end

    context 'when both @rbs return and annotation #: are present on a singleton method' do
      it 'registers an offense on the annotation #:' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          #: () -> String
          ^^^^^^^^^^^^^^^ Redundant annotation comment.
          def self.method(arg)
          end
        RUBY

        expect_no_corrections
      end
    end

    context 'when @rbs return, annotation #:, and inline #: are all present' do
      it 'registers offenses on both annotation #: and inline #:' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          #: () -> String
          ^^^^^^^^^^^^^^^ Redundant annotation comment.
          def method(arg) #: String
                          ^^^^^^^^^ Redundant inline return type annotation.
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs return: String
          #: () -> String
          def method(arg)
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

    context 'when only inline #: is present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def method(arg) #: String
          end
        RUBY
      end
    end

    context 'when only annotation #: is present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          #: () -> String
          def method(arg)
          end
        RUBY
      end
    end

    context 'when annotation #: and inline #: are present without @rbs return' do
      it 'registers offenses on both annotation #: and inline #:' do
        expect_offense(<<~RUBY)
          #: () -> String
          ^^^^^^^^^^^^^^^ Redundant annotation comment.
          def method(arg) #: String
                          ^^^^^^^^^ Redundant inline return type annotation.
          end
        RUBY

        expect_no_corrections
      end
    end
  end
end
