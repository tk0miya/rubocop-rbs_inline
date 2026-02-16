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
end
