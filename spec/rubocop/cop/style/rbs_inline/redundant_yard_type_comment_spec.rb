# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::RedundantYardTypeComment, :config do
  let(:config) { RuboCop::Config.new }

  context 'when YARD @param and RBS type comments coexist' do
    it 'registers an offense for YARD @param with @rbs annotation (no descriptions)' do
      expect_offense(<<~RUBY)
        # @param name [String]
        ^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Use RBS inline annotation instead.
        # @rbs name: String
        def greet(name); end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs name: String
        def greet(name); end
      RUBY
    end

    it 'merges YARD description into RBS when RBS has no description' do
      expect_offense(<<~RUBY)
        # @param name [String] the user name
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Description merged into RBS annotation.
        # @rbs name: String
        def greet(name); end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs name: String -- the user name
        def greet(name); end
      RUBY
    end

    it 'removes YARD when both have descriptions (RBS description preserved)' do
      expect_offense(<<~RUBY)
        # @param name [String] the YARD description
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Use RBS inline annotation instead.
        # @rbs name: String -- the RBS description
        def greet(name); end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs name: String -- the RBS description
        def greet(name); end
      RUBY
    end

    it 'removes YARD when only RBS has description' do
      expect_offense(<<~RUBY)
        # @param name [String]
        ^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Use RBS inline annotation instead.
        # @rbs name: String -- already documented
        def greet(name); end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs name: String -- already documented
        def greet(name); end
      RUBY
    end

    it 'registers an offense for YARD @param with #: signature' do
      expect_offense(<<~RUBY)
        # @param name [String] the name
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Use RBS inline annotation instead.
        #: (String) -> void
        def greet(name); end
      RUBY

      expect_correction(<<~RUBY)
        #: (String) -> void
        def greet(name); end
      RUBY
    end

    it 'handles multiple YARD @params with merge' do
      expect_offense(<<~RUBY)
        # @param first [String] first name
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Description merged into RBS annotation.
        # @param last [String] last name
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Description merged into RBS annotation.
        # @rbs first: String
        # @rbs last: String
        def greet(first, last); end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs first: String -- first name
        # @rbs last: String -- last name
        def greet(first, last); end
      RUBY
    end
  end

  context 'when YARD @return and RBS type comments coexist' do
    it 'merges YARD @return description into RBS' do
      expect_offense(<<~RUBY)
        # @return [Integer] the total count
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Description merged into RBS annotation.
        # @rbs return: Integer
        def count; end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs return: Integer -- the total count
        def count; end
      RUBY
    end

    it 'removes YARD @return when no description' do
      expect_offense(<<~RUBY)
        # @return [Integer]
        ^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Use RBS inline annotation instead.
        # @rbs return: Integer
        def count; end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs return: Integer
        def count; end
      RUBY
    end

    it 'removes YARD @return with #: signature' do
      expect_offense(<<~RUBY)
        # @return [Integer] the count
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Use RBS inline annotation instead.
        #: () -> Integer
        def count; end
      RUBY

      expect_correction(<<~RUBY)
        #: () -> Integer
        def count; end
      RUBY
    end
  end

  context 'when YARD @yield and RBS type comments coexist' do
    it 'removes YARD @yield with @rbs &block annotation (no description)' do
      expect_offense(<<~RUBY)
        # @yield [Integer]
        ^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Use RBS inline annotation instead.
        # @rbs &block: (Integer) -> void
        def each(&block); end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs &block: (Integer) -> void
        def each(&block); end
      RUBY
    end

    it 'merges YARD @yield description into @rbs &block' do
      expect_offense(<<~RUBY)
        # @yield [Integer] yields the value
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Description merged into RBS annotation.
        # @rbs &block: (Integer) -> void
        def each(&block); end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs &block: (Integer) -> void -- yields the value
        def each(&block); end
      RUBY
    end

    it 'removes YARD @yieldparam with @rbs annotation' do
      expect_offense(<<~RUBY)
        # @yieldparam value [Integer] the value
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Use RBS inline annotation instead.
        # @rbs &block: (Integer) -> void
        def each(&block); end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs &block: (Integer) -> void
        def each(&block); end
      RUBY
    end

    it 'removes YARD @yieldreturn with @rbs annotation' do
      expect_offense(<<~RUBY)
        # @yieldreturn [Boolean] whether to continue
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Use RBS inline annotation instead.
        # @rbs &block: () -> bool
        def process(&block); end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs &block: () -> bool
        def process(&block); end
      RUBY
    end
  end

  context 'when both @param and @return are redundant' do
    it 'handles mixed merge and remove' do
      expect_offense(<<~RUBY)
        # @param name [String] the input name
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Description merged into RBS annotation.
        # @return [Integer]
        ^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Use RBS inline annotation instead.
        # @rbs name: String
        # @rbs return: Integer
        def count(name); end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs name: String -- the input name
        # @rbs return: Integer
        def count(name); end
      RUBY
    end
  end

  context 'when only YARD comments exist (no RBS)' do
    it 'does not register an offense for @param without RBS' do
      expect_no_offenses(<<~RUBY)
        # @param name [String] the name
        def greet(name); end
      RUBY
    end

    it 'does not register an offense for @return without RBS' do
      expect_no_offenses(<<~RUBY)
        # @return [Integer] the count
        def count; end
      RUBY
    end

    it 'does not register an offense for mixed YARD comments without RBS' do
      expect_no_offenses(<<~RUBY)
        # @param name [String] the name
        # @return [String] the greeting
        def greet(name); end
      RUBY
    end
  end

  context 'when only RBS comments exist (no YARD)' do
    it 'does not register an offense for @rbs annotations' do
      expect_no_offenses(<<~RUBY)
        # @rbs name: String -- the name
        # @rbs return: String
        def greet(name); end
      RUBY
    end

    it 'does not register an offense for #: signature' do
      expect_no_offenses(<<~RUBY)
        #: (String) -> String
        def greet(name); end
      RUBY
    end
  end

  context 'when YARD comments without type brackets exist with RBS' do
    it 'does not register an offense for @param without type' do
      expect_no_offenses(<<~RUBY)
        # @param name the name parameter
        # @rbs name: String
        def greet(name); end
      RUBY
    end

    it 'does not register an offense for @return without type' do
      expect_no_offenses(<<~RUBY)
        # @return the greeting message
        #: (String) -> String
        def greet(name); end
      RUBY
    end
  end

  context 'with singleton methods (defs)' do
    it 'merges description for YARD with RBS on class method' do
      expect_offense(<<~RUBY)
        # @param name [String] the class method param
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Description merged into RBS annotation.
        # @rbs name: String
        def self.greet(name); end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs name: String -- the class method param
        def self.greet(name); end
      RUBY
    end
  end

  context 'with indented code' do
    it 'registers an offense and merges properly' do
      expect_offense(<<~RUBY)
        class Foo
          # @param name [String] indented description
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Description merged into RBS annotation.
          # @rbs name: String
          def greet(name); end
        end
      RUBY

      expect_correction(<<~RUBY)
        class Foo
          # @rbs name: String -- indented description
          def greet(name); end
        end
      RUBY
    end
  end

  context 'when comments are not immediately preceding the method' do
    it 'does not register an offense for separated comments' do
      expect_no_offenses(<<~RUBY)
        # @param name [String]

        # @rbs name: String
        def greet(name); end
      RUBY
    end
  end

  context 'with complex RBS types' do
    it 'handles RBS with union types' do
      expect_offense(<<~RUBY)
        # @param value [String] the value
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Description merged into RBS annotation.
        # @rbs value: String | Integer
        def process(value); end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs value: String | Integer -- the value
        def process(value); end
      RUBY
    end

    it 'handles RBS with generic types' do
      expect_offense(<<~RUBY)
        # @param items [Array] the items
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/RedundantYardTypeComment: Redundant YARD type comment. Description merged into RBS annotation.
        # @rbs items: Array[String]
        def process(items); end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs items: Array[String] -- the items
        def process(items); end
      RUBY
    end
  end
end
