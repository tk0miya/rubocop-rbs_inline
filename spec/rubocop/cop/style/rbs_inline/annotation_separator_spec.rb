# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::AnnotationSeparator, :config do
  let(:config) { RuboCop::Config.new }

  # KeywordSeparator cases

  it 'registers an offense when using `:` after keyword outside a method definition' do
    expect_offense(<<~RUBY)
      # @rbs inherits: String
                     ^ Style/RbsInline/AnnotationSeparator: Do not use `:` after the keyword.
      # @rbs override:
                     ^ Style/RbsInline/AnnotationSeparator: Do not use `:` after the keyword.
      # @rbs use: String
                ^ Style/RbsInline/AnnotationSeparator: Do not use `:` after the keyword.
      # @rbs module-self: String
                        ^ Style/RbsInline/AnnotationSeparator: Do not use `:` after the keyword.
      # @rbs generic: String
                    ^ Style/RbsInline/AnnotationSeparator: Do not use `:` after the keyword.
      # @rbs skip:
                 ^ Style/RbsInline/AnnotationSeparator: Do not use `:` after the keyword.
      # @rbs module: String
                   ^ Style/RbsInline/AnnotationSeparator: Do not use `:` after the keyword.
      # @rbs class: String
                  ^ Style/RbsInline/AnnotationSeparator: Do not use `:` after the keyword.
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

  it 'does not register an offense for keywords without colon' do
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

  it 'does not register an offense when a keyword is used as a parameter name before a method definition' do
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

  it 'registers an offense when override/skip use `:` without a type even before a method definition' do
    expect_offense(<<~RUBY)
      # @rbs skip:
                 ^ Style/RbsInline/AnnotationSeparator: Do not use `:` after the keyword.
      def foo; end

      # @rbs override:
                     ^ Style/RbsInline/AnnotationSeparator: Do not use `:` after the keyword.
      def bar; end
    RUBY

    expect_correction(<<~RUBY)
      # @rbs skip
      def foo; end

      # @rbs override
      def bar; end
    RUBY
  end

  it 'does not register an offense when keyword annotations appear at both class and method level' do
    expect_no_offenses(<<~RUBY)
      # @rbs inherits Bar
      class Foo
        # @rbs inherits: Integer
        def meth(inherits); end
      end
    RUBY
  end

  # ParametersSeparator cases

  it 'registers an offense when parameter annotation is missing the `:` separator' do
    expect_offense(<<~RUBY)
      # @rbs param String
             ^^^^^^^^^^^^ Style/RbsInline/AnnotationSeparator: Use `:` as a separator between parameter name and type.
      # @rbs &block String
             ^^^^^^^^^^^^^ Style/RbsInline/AnnotationSeparator: Use `:` as a separator between parameter name and type.
      # @rbs * String
             ^^^^^^^^ Style/RbsInline/AnnotationSeparator: Use `:` as a separator between parameter name and type.
      # @rbs ** String
             ^^^^^^^^^ Style/RbsInline/AnnotationSeparator: Use `:` as a separator between parameter name and type.
      # @rbs return String
             ^^^^^^^^^^^^^ Style/RbsInline/AnnotationSeparator: Use `:` as a separator between parameter name and type.
      # @rbs :return String
             ^^^^^^^^^^^^^^ Style/RbsInline/AnnotationSeparator: Use `:` as a separator between parameter name and type.
      # @rbs :param String
             ^^^^^^^^^^^^^ Style/RbsInline/AnnotationSeparator: Use `:` as a separator between parameter name and type.
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

  it 'does not register an offense for valid parameter annotations and keywords' do
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
