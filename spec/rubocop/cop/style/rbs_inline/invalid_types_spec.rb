# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::InvalidTypes, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense when using `#bad_method`' do
    expect_offense(<<~RUBY)
      # Comments including multibyte characters: あいうえお

      # @rbs! type t = Hash[Symbol,
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/InvalidTypes: Invalid annotation found.

      # @rbs generic t
      ^^^^^^^^^^^^^^^^ Style/RbsInline/InvalidTypes: Invalid annotation found.
      # @rbs module-self Hash[Symbol,
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/InvalidTypes: Invalid annotation found.
      module Foo
        include Enumerable #[Symbol,
                           ^^^^^^^^^ Style/RbsInline/InvalidTypes: Invalid annotation found.

        # @rbs @ivar: Hash[Symbol, String
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/InvalidTypes: Invalid annotation found.

        # @rbs arg: Hash[Symbol, String
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/InvalidTypes: Invalid annotation found.
        # @rbs *: Hash[Symbol, String
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/InvalidTypes: Invalid annotation found.
        # @rbs &block: Hash[Symbol, String
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/InvalidTypes: Invalid annotation found.
        #: () ->
        ^^^^^^^^ Style/RbsInline/InvalidTypes: Invalid annotation found.
        def method(arg) #: Hash[Symbol, String
                        ^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/InvalidTypes: Invalid annotation found.
        end
      end
    RUBY
  end

  it 'does not register an offense when using `#good_method`' do
    expect_no_offenses(<<~RUBY)
      # Comments including multibyte characters: あいうえお

      # @rbs! type t = Hash[Symbol, String]

      # @rbs generic T
      # @rbs module-self Hash[Symbol, String]
      module Foo
        include Enumerable #[Symbol, String]

        # @rbs @ivar: Hash[Symbol, String]

        # @rbs arg: Hash[Symbol, String]
        # @rbs *: Hash[Symbol, String]
        # @rbs &block: () -> void
        #: () -> void
        def method(arg) #: Hash[Symbol, String]
        end
      end
    RUBY
  end
end
