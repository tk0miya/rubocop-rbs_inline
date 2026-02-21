# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::UnmatchedAnnotations, :config do
  let(:config) { RuboCop::Config.new }

  context 'when an annotation comment found above the instance method definition' do
    context 'when the comment annotates to unknown argument' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          # Comments including multibyte characters: あいうえお

          # @rbs unknown: String
                 ^^^^^^^ Style/RbsInline/UnmatchedAnnotations: target parameter not found.
          # @rbs &unknown: String
                 ^^^^^^^^ Style/RbsInline/UnmatchedAnnotations: target parameter not found.
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

          # @rbs skip
          def method(...); end
        RUBY
      end
    end

    context 'when the comment annotates to the instance variable' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          # Comments including multibyte characters: あいうえお

          # @rbs @var1: String
                 ^^^^^ Style/RbsInline/UnmatchedAnnotations: target parameter not found.
          # @rbs @var2: Integer
                 ^^^^^ Style/RbsInline/UnmatchedAnnotations: target parameter not found.
          def method(arg1, arg2 = nil, *args, kwarg1:, kwarg2: nil, **kwargs, &block); end
        RUBY
      end
    end
  end

  context 'when an annotation comment found above the singleton method definition' do
    context 'when the comment annotates to unknown argument' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          # Comments including multibyte characters: あいうえお

          # @rbs unknown: String
                 ^^^^^^^ Style/RbsInline/UnmatchedAnnotations: target parameter not found.
          # @rbs &unknown: String
                 ^^^^^^^^ Style/RbsInline/UnmatchedAnnotations: target parameter not found.
          def self.method(arg1, arg2 = nil, *args, kwarg1:, kwarg2: nil, **kwargs, &block); end
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
          def self.method(arg1, arg2 = nil, *args, kwarg1:, kwarg2: nil, **kwargs, &block); end
        RUBY
      end
    end
  end

  context 'when an independent annotation comment found' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # Comments including multibyte characters: あいうえお

        # @rbs arg1: String
               ^^^^ Style/RbsInline/UnmatchedAnnotations: target parameter not found.
        # @rbs &block: String
               ^^^^^^ Style/RbsInline/UnmatchedAnnotations: target parameter not found.
        # @rbs return: String
               ^^^^^^ Style/RbsInline/UnmatchedAnnotations: target parameter not found.
      RUBY
    end
  end

  context 'when IgnoreUnderscoreArguments is true' do
    let(:config) do
      RuboCop::Config.new(
        'Style/RbsInline/UnmatchedAnnotations' => { 'IgnoreUnderscoreArguments' => true }
      )
    end

    context 'when annotation references an underscore-prefixed name before a method' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs _name: String
          def method(arg); end
        RUBY
      end
    end

    context 'when annotation references an underscore-prefixed name with no method' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs _name: String
        RUBY
      end
    end

    context 'when annotation references a non-underscore unknown name before a method' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          # @rbs unknown: String
                 ^^^^^^^ target parameter not found.
          def method(arg); end
        RUBY
      end
    end

    context 'when annotation references a known underscore-prefixed argument' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs _name: String
          def method(_name); end
        RUBY
      end
    end

    context 'when annotation references a known non-underscore argument' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs name: String
          def method(name); end
        RUBY
      end
    end
  end
end
