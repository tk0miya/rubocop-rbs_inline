# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::ParametersSeparator, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense when using `#bad_method`' do
    expect_offense(<<~RUBY)
      # @rbs param String
             ^^^^^^^^^^^^ Style/RbsInline/ParametersSeparator: Use `:` as a separator between parameter name and type.
      # @rbs &block String
             ^^^^^^^^^^^^^ Style/RbsInline/ParametersSeparator: Use `:` as a separator between parameter name and type.
      # @rbs * String
             ^^^^^^^^ Style/RbsInline/ParametersSeparator: Use `:` as a separator between parameter name and type.
      # @rbs ** String
             ^^^^^^^^^ Style/RbsInline/ParametersSeparator: Use `:` as a separator between parameter name and type.
      # @rbs return String
             ^^^^^^^^^^^^^ Style/RbsInline/ParametersSeparator: Use `:` as a separator between parameter name and type.
      # @rbs :return String
             ^^^^^^^^^^^^^^ Style/RbsInline/ParametersSeparator: Use `:` as a separator between parameter name and type.
      # @rbs :param String
             ^^^^^^^^^^^^^ Style/RbsInline/ParametersSeparator: Use `:` as a separator between parameter name and type.
    RUBY
  end

  it 'does not register an offense when using `#good_method`' do
    expect_no_offenses(<<~RUBY)
      # @rbs param: String
      # @rbs &block: String
      # @rbs *: String
      # @rbs **: String
      # @rbs return: String

      # @rbs %a{pure}
      # @rbs %a[pure]
      # @rbs %a(pure)
      # @rbs %a{pure} %a{implicitly-returns-nil}
      # @rbs %a{implicitly-returns-nil}
      # @rbs %a(implicitly-returns-nil)
      # @rbs %a[implicitly-returns-nil]

      # @rbs inherits String
      # @rbs override
      # @rbs use String
      # @rbs module-self String
      # @rbs generic String
      # @rbs skip
      # @rbs module String
      # @rbs class String
    RUBY
  end
end
