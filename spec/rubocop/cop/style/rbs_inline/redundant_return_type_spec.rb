# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::RedundantReturnType, :config do
  context 'when EnforcedStyle is inline_comment (default)' do
    let(:config) do
      RuboCop::Config.new(
        'Style/RbsInline/RedundantReturnType' => {
          'EnforcedStyle' => 'inline_comment',
          'SupportedStyles' => %w[inline_comment rbs_return_comment]
        }
      )
    end

    context 'when both @rbs return and inline #: are present' do
      it 'registers an offense on the @rbs return annotation' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs return` annotation. The return type is already annotated with inline comment.
          def method(arg) #: String
          end
        RUBY
      end
    end

    context 'when both @rbs return and inline #: are present on a singleton method' do
      it 'registers an offense on the @rbs return annotation' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs return` annotation. The return type is already annotated with inline comment.
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
          ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs return` annotation. The return type is already annotated with inline comment.
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

    context 'when only inline #: is present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def method(arg) #: String
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
  end

  context 'when EnforcedStyle is rbs_return_comment' do
    let(:config) do
      RuboCop::Config.new(
        'Style/RbsInline/RedundantReturnType' => {
          'EnforcedStyle' => 'rbs_return_comment',
          'SupportedStyles' => %w[inline_comment rbs_return_comment]
        }
      )
    end

    context 'when both @rbs return and inline #: are present' do
      it 'registers an offense on the inline #: annotation' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          def method(arg) #: String
                          ^^^^^^^^^ Redundant inline return type annotation. The return type is already annotated with `@rbs return`.
          end
        RUBY
      end
    end

    context 'when both @rbs return and inline #: are present on a singleton method' do
      it 'registers an offense on the inline #: annotation' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          def self.method(arg) #: String
                               ^^^^^^^^^ Redundant inline return type annotation. The return type is already annotated with `@rbs return`.
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
  end
end
