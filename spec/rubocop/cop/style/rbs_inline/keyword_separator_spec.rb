# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::KeywordSeparator, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense when using `:` after keyword' do
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

  it 'does not register an offense when using `#good_method`' do
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
