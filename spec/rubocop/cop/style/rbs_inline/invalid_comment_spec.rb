# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::InvalidComment, :config do
  let(:config) { RuboCop::Config.new }

  context 'When code contains `#:` style annotation comments' do
    it 'registers an offense when using invalid annotation comments' do
      expect_offense(<<~RUBY)
        # () -> void
        ^^^^^^^^^^^^ Style/RbsInline/InvalidComment: Invalid RBS annotation comment found.
        # : () -> void
        ^^^^^^^^^^^^^^ Style/RbsInline/InvalidComment: Invalid RBS annotation comment found.
        #: @rbs param: String
        ^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/InvalidComment: Invalid RBS annotation comment found.
      RUBY
    end

    it 'does not register an offense when using valid annotation comments' do
      expect_no_offenses(<<~RUBY)
        #: () -> void
        # a comment not related to types
        # : a comment not related to types, but start with a colon
        #: a comment not related to types, but start with a colon
      RUBY
    end
  end

  context 'When code contains `# @rbs` style annotation comments' do
    it 'registers an offense when using invalid annotation comments' do
      expect_offense(<<~RUBY)
        # rbs return: String
        ^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/InvalidComment: Invalid RBS annotation comment found.
        # rbs inherits String
        ^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/InvalidComment: Invalid RBS annotation comment found.
        # rbs override
        ^^^^^^^^^^^^^^ Style/RbsInline/InvalidComment: Invalid RBS annotation comment found.
        # rbs use String
        ^^^^^^^^^^^^^^^^ Style/RbsInline/InvalidComment: Invalid RBS annotation comment found.
        # rbs module-self String
        ^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/InvalidComment: Invalid RBS annotation comment found.
        # rbs generic String
        ^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/InvalidComment: Invalid RBS annotation comment found.
        # rbs skip
        ^^^^^^^^^^ Style/RbsInline/InvalidComment: Invalid RBS annotation comment found.
        # rbs module String
        ^^^^^^^^^^^^^^^^^^^ Style/RbsInline/InvalidComment: Invalid RBS annotation comment found.
        # rbs class String
        ^^^^^^^^^^^^^^^^^^ Style/RbsInline/InvalidComment: Invalid RBS annotation comment found.
        # rbs param: String
        ^^^^^^^^^^^^^^^^^^^ Style/RbsInline/InvalidComment: Invalid RBS annotation comment found.
        # rbs &block: String
        ^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/InvalidComment: Invalid RBS annotation comment found.
        # rbs *: String
        ^^^^^^^^^^^^^^^ Style/RbsInline/InvalidComment: Invalid RBS annotation comment found.
        # rbs **: String
        ^^^^^^^^^^^^^^^^ Style/RbsInline/InvalidComment: Invalid RBS annotation comment found.
      RUBY
    end

    it 'does not register an offense when valid annotation comments' do
      expect_no_offenses(<<~RUBY)
        # @rbs return: String
        # @rbs inherits String
        # @rbs override
        # @rbs use String
        # @rbs module-self String
        # @rbs generic String
        # @rbs in String
        # @rbs out String
        # @rbs unchecked String
        # @rbs self String
        # @rbs skip
        # @rbs module String
        # @rbs class String
        # @rbs param: String
        # @rbs &block: String
        # @rbs *: String
        # @rbs **: String
        # rbs
        # a comment not related to types
        # rbs comment starts with "rbs"
      RUBY
    end
  end
end
