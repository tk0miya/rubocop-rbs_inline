# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::RedundantYardComment, :config do
  let(:config) { RuboCop::Config.new }

  context 'when YARD @param exists with RBS method signature' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # @param name [String] the name
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@param` comment. Use RBS inline annotations instead.
        #: (String) -> void
        def greet(name)
        end
      RUBY

      expect_correction(<<~RUBY)
        #: (String) -> void
        def greet(name)
        end
      RUBY
    end
  end

  context 'when YARD @param exists with # @rbs param annotation' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # @param name [String] the name
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@param` comment. Use RBS inline annotations instead.
        # @rbs name: String
        def greet(name)
        end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs name: String
        def greet(name)
        end
      RUBY
    end
  end

  context 'when multiple YARD @param comments exist' do
    it 'registers offense on each' do
      expect_offense(<<~RUBY)
        # @param a [Integer] first param
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@param` comment. Use RBS inline annotations instead.
        # @param b [String] second param
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@param` comment. Use RBS inline annotations instead.
        #: (Integer, String) -> void
        def method(a, b)
        end
      RUBY

      expect_correction(<<~RUBY)
        #: (Integer, String) -> void
        def method(a, b)
        end
      RUBY
    end
  end

  context 'when YARD @return exists with RBS method signature' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # @return [String] the greeting
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@return` comment. Use RBS inline annotations instead.
        #: (String) -> String
        def greet(name)
        end
      RUBY

      expect_correction(<<~RUBY)
        #: (String) -> String
        def greet(name)
        end
      RUBY
    end
  end

  context 'when YARD @return exists with trailing return type' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # @return [String] the greeting
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@return` comment. Use RBS inline annotations instead.
        def greet(name) #: String
        end
      RUBY

      expect_correction(<<~RUBY)
        def greet(name) #: String
        end
      RUBY
    end
  end

  context 'when YARD @return exists with # @rbs return annotation' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # @return [String] the result
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@return` comment. Use RBS inline annotations instead.
        # @rbs return: String
        def method
        end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs return: String
        def method
        end
      RUBY
    end
  end

  context 'when both YARD @param and @return exist with RBS' do
    it 'registers offenses on both' do
      expect_offense(<<~RUBY)
        # @param name [String] the name
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@param` comment. Use RBS inline annotations instead.
        # @return [String] the greeting
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@return` comment. Use RBS inline annotations instead.
        #: (String) -> String
        def greet(name)
        end
      RUBY

      expect_correction(<<~RUBY)
        #: (String) -> String
        def greet(name)
        end
      RUBY
    end
  end

  context 'when only YARD comments exist without RBS' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        # @param name [String] the name
        # @return [String] the greeting
        def greet(name)
        end
      RUBY
    end
  end

  context 'when only RBS annotations exist without YARD' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        #: (String) -> String
        def greet(name)
        end
      RUBY
    end
  end

  context 'when YARD has only non-type comments' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        # @example
        #   greet("Alice")
        # @see Other#method
        #: (String) -> String
        def greet(name)
        end
      RUBY
    end
  end

  context 'when method is a singleton method' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # @param name [String] the name
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@param` comment. Use RBS inline annotations instead.
        #: (String) -> void
        def self.greet(name)
        end
      RUBY

      expect_correction(<<~RUBY)
        #: (String) -> void
        def self.greet(name)
        end
      RUBY
    end
  end

  context 'when YARD @param exists without corresponding RBS param' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        # @param name [String] the name
        # @rbs return: String
        def greet(name)
        end
      RUBY
    end
  end

  context 'when YARD @return exists without corresponding RBS return' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        # @return [String] the result
        # @rbs name: String
        def greet(name)
        end
      RUBY
    end
  end

  context 'when YARD and RBS are separated by non-comment line' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        # @param name [String] the name

        #: (String) -> String
        def greet(name)
        end
      RUBY
    end
  end

  context 'when YARD comment is after method definition' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        #: (String) -> String
        def greet(name)
          # @param internal note
        end
      RUBY
    end
  end

  context 'when method has mixed documentation styles' do
    it 'registers offense only on type-related YARD comments' do
      expect_offense(<<~RUBY)
        # This is a greeting method
        # @param name [String] the name
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@param` comment. Use RBS inline annotations instead.
        # @example
        #   greet("Alice")
        #: (String) -> String
        def greet(name)
        end
      RUBY

      expect_correction(<<~RUBY)
        # This is a greeting method
        # @example
        #   greet("Alice")
        #: (String) -> String
        def greet(name)
        end
      RUBY
    end
  end

  context 'when using doc_style_and_return_annotation' do
    it 'registers offense for redundant YARD' do
      expect_offense(<<~RUBY)
        # @param a [Integer] first param
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@param` comment. Use RBS inline annotations instead.
        # @rbs a: Integer
        def method(a) #: String
        end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs a: Integer
        def method(a) #: String
        end
      RUBY
    end
  end

  context 'when YARD @option exists with RBS method signature' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # @option opts [String] :name the name
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@option` comment. Use RBS inline annotations instead.
        #: (Hash[Symbol, untyped]) -> void
        def greet(opts)
        end
      RUBY

      expect_correction(<<~RUBY)
        #: (Hash[Symbol, untyped]) -> void
        def greet(opts)
        end
      RUBY
    end
  end

  context 'when YARD @option exists with # @rbs param annotation' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # @option opts [String] :name the name
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@option` comment. Use RBS inline annotations instead.
        # @rbs opts: Hash[Symbol, untyped]
        def greet(opts)
        end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs opts: Hash[Symbol, untyped]
        def greet(opts)
        end
      RUBY
    end
  end

  context 'when YARD @option exists without RBS annotations' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        # @option opts [String] :name the name
        def greet(opts)
        end
      RUBY
    end
  end

  context 'when both YARD @param and @option exist with RBS' do
    it 'registers offenses on both' do
      expect_offense(<<~RUBY)
        # @param opts [Hash] the options
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@param` comment. Use RBS inline annotations instead.
        # @option opts [String] :name the name
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@option` comment. Use RBS inline annotations instead.
        #: (Hash[Symbol, untyped]) -> void
        def greet(opts)
        end
      RUBY

      expect_correction(<<~RUBY)
        #: (Hash[Symbol, untyped]) -> void
        def greet(opts)
        end
      RUBY
    end
  end

  context 'when YARD @yield exists with RBS method signature' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # @yield [item] yields each item
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@yield` comment. Use RBS inline annotations instead.
        #: () { (String) -> void } -> void
        def each(&block)
        end
      RUBY

      expect_correction(<<~RUBY)
        #: () { (String) -> void } -> void
        def each(&block)
        end
      RUBY
    end
  end

  context 'when YARD @yieldparam exists with RBS method signature' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # @yieldparam item [String] the item
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@yieldparam` comment. Use RBS inline annotations instead.
        #: () { (String) -> void } -> void
        def each(&block)
        end
      RUBY

      expect_correction(<<~RUBY)
        #: () { (String) -> void } -> void
        def each(&block)
        end
      RUBY
    end
  end

  context 'when YARD @yieldreturn exists with RBS method signature' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # @yieldreturn [Boolean] whether to continue
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@yieldreturn` comment. Use RBS inline annotations instead.
        #: () { () -> bool } -> void
        def each(&block)
        end
      RUBY

      expect_correction(<<~RUBY)
        #: () { () -> bool } -> void
        def each(&block)
        end
      RUBY
    end
  end

  context 'when YARD @yieldparam exists with # @rbs block annotation' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # @yieldparam item [String] the item
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@yieldparam` comment. Use RBS inline annotations instead.
        # @rbs &block: ^(String) -> void
        def each(&block)
        end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs &block: ^(String) -> void
        def each(&block)
        end
      RUBY
    end
  end

  context 'when YARD @yield exists without RBS block annotation' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        # @yield [item] yields each item
        # @rbs name: String
        def each(name, &block)
        end
      RUBY
    end
  end

  context 'when multiple YARD block tags exist with RBS' do
    it 'registers offense on each' do
      expect_offense(<<~RUBY)
        # @yield [item] yields each item
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@yield` comment. Use RBS inline annotations instead.
        # @yieldparam item [String] the item
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@yieldparam` comment. Use RBS inline annotations instead.
        # @yieldreturn [void]
        ^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@yieldreturn` comment. Use RBS inline annotations instead.
        #: () { (String) -> void } -> void
        def each(&block)
        end
      RUBY

      expect_correction(<<~RUBY)
        #: () { (String) -> void } -> void
        def each(&block)
        end
      RUBY
    end
  end

  context 'when all YARD type tags coexist with RBS' do
    it 'registers offense on each type-related YARD tag' do
      expect_offense(<<~RUBY)
        # @param items [Array] the items
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@param` comment. Use RBS inline annotations instead.
        # @option items [String] :name the name
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@option` comment. Use RBS inline annotations instead.
        # @return [Integer] the count
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@return` comment. Use RBS inline annotations instead.
        # @yield [item] yields each item
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@yield` comment. Use RBS inline annotations instead.
        # @yieldparam item [String] the item
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@yieldparam` comment. Use RBS inline annotations instead.
        # @yieldreturn [void]
        ^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardComment: Redundant YARD `@yieldreturn` comment. Use RBS inline annotations instead.
        #: (Array[String]) { (String) -> void } -> Integer
        def process(items, &block)
        end
      RUBY

      expect_correction(<<~RUBY)
        #: (Array[String]) { (String) -> void } -> Integer
        def process(items, &block)
        end
      RUBY
    end
  end
end
