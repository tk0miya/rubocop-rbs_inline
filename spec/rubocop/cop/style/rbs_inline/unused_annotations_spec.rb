# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::UnusedAnnotations, :config do
  let(:config) { RuboCop::Config.new }

  context 'when an annotation comment found above the method definition' do
    context 'when the comment annotates to unknown argument' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          # Comments including multibyte characters: あいうえお

          # @rbs unknown: String
                 ^^^^^^^ Style/RbsInline/UnusedAnnotations: target parameter not found.
          # @rbs &unknown: String
                 ^^^^^^^^ Style/RbsInline/UnusedAnnotations: target parameter not found.
          def method(arg1, arg2 = nil, *args, kwarg1:, kwarg2: nil, **kwargs, &block); end
        RUBY
      end
    end

    context 'when the comment annotates to known arguments' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # Comments including multibyte characters: あいうえお
          # @rbs @arg1: String

          # @rbs arg1: String
          # @rbs arg2: String
          # @rbs *args: String
          # @rbs *: String
          # @rbs kwarg1: String
          # @rbs kwarg2: String
          # @rbs **kwargs: String
          # @rbs **: String
          # @rbs &block: String
          # @rbs &: String
          # @rbs return: String
          def method(arg1, arg2 = nil, *args, kwarg1:, kwarg2: nil, **kwargs, &block); end
        RUBY
      end
    end
  end

  context 'when an independent annotation comment found' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # Comments including multibyte characters: あいうえお

        # @rbs arg1: String
               ^^^^ Style/RbsInline/UnusedAnnotations: target parameter not found.
        # @rbs &block: String
               ^^^^^^ Style/RbsInline/UnusedAnnotations: target parameter not found.
        # @rbs return: String
               ^^^^^^ Style/RbsInline/UnusedAnnotations: target parameter not found.
      RUBY
    end
  end
end
