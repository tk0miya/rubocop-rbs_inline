# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::KeywordSeparator, :config do
  let(:config) { rbs_inline_config }

  context "when using `:` after keyword outside a method definition" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs inherits: String
                       ^ Style/RbsInline/KeywordSeparator: Do not use `:` after the keyword.
        # @rbs override:
                       ^ Style/RbsInline/KeywordSeparator: Do not use `:` after the keyword.
        # @rbs use: String
                  ^ Style/RbsInline/KeywordSeparator: Do not use `:` after the keyword.
        # @rbs module-self: String
                          ^ Style/RbsInline/KeywordSeparator: Do not use `:` after the keyword.
        # @rbs generic: String
                      ^ Style/RbsInline/KeywordSeparator: Do not use `:` after the keyword.
        # @rbs skip:
                   ^ Style/RbsInline/KeywordSeparator: Do not use `:` after the keyword.
        # @rbs module: String
                     ^ Style/RbsInline/KeywordSeparator: Do not use `:` after the keyword.
        # @rbs class: String
                    ^ Style/RbsInline/KeywordSeparator: Do not use `:` after the keyword.
      RUBY

      expect_correction(<<~RUBY)
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

  context "when using `#good_method`" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
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

  context "when a keyword is used as a parameter name before a method definition" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs override: Hash[String, untyped]
        def meth(override); end

        # @rbs inherits: Integer
        def meth2(inherits); end

        # @rbs use: Symbol
        # @rbs skip: String
        def meth3(use, skip); end
      RUBY
    end
  end

  context "when override/skip use `:` without a type even before a method definition" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs skip:
                   ^ Style/RbsInline/KeywordSeparator: Do not use `:` after the keyword.
        def foo; end

        # @rbs override:
                       ^ Style/RbsInline/KeywordSeparator: Do not use `:` after the keyword.
        def bar; end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs skip
        def foo; end

        # @rbs override
        def bar; end
      RUBY
    end
  end

  context "when keyword annotations appear at both class and method level" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs inherits Bar
        class Foo
          # @rbs inherits: Integer
          def meth(inherits); end
        end
      RUBY
    end
  end
end
