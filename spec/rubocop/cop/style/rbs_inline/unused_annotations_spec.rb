# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::UnusedAnnotations, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense when annotating to unknown argument' do
    expect_offense(<<~RUBY)
      # @rbs unknown: String
             ^^^^^^^ Style/RbsInline/UnusedAnnotations: target parameter not found.
      def method(arg1, arg2 = nil, *args, kwarg1:, kwarg2: nil, **kwargs, &block); end
    RUBY
  end

  it 'does not register an offense when annotating to known arguments' do
    expect_no_offenses(<<~RUBY)
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
      def method(arg1, arg2 = nil, *args, kwarg1:, kwarg2: nil, **kwargs, &block); end
    RUBY
  end
end
