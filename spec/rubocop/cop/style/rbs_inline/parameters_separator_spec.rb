# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::ParametersSeparator, :config do
  let(:config) { rbs_inline_config }

  context "when using `#bad_method`" do
    it "registers an offense" do
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

      expect_correction(<<~RUBY)
        # @rbs param: String
        # @rbs &block: String
        # @rbs *: String
        # @rbs **: String
        # @rbs return: String
        # @rbs return: String
        # @rbs param: String
      RUBY
    end
  end

  context "when using `#good_method`" do
    it "does not register an offense" do
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

  context "with method type signature annotations" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs (Integer) -> String
        # @rbs () -> void
        # @rbs [T] (T) -> T
        # @rbs [T < Parser::AST::Node] (T) -> T
      RUBY
    end
  end
end
