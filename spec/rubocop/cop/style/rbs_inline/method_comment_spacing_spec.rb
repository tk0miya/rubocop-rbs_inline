# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::MethodCommentSpacing, :config do
  let(:config) do
    RuboCop::Config.new("Style/RbsInline/MethodCommentSpacing" => { "Enabled" => true })
  end

  context "when method annotation has blank line before method definition" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs param x: Integer
        # @rbs return: String

        ^{} Remove blank line between method annotation and method definition.
        def method(x)
        end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs param x: Integer
        # @rbs return: String
        def method(x)
        end
      RUBY
    end
  end

  context "when method annotation is not followed by method definition" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs param x: Integer
        # @rbs return: String
        ^^^^^^^^^^^^^^^^^^^^^ Method-related `@rbs` annotation must be immediately before a method definition.
        puts "something"
      RUBY
    end
  end

  context "with a param annotation not followed by method" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs param x: Integer
        ^^^^^^^^^^^^^^^^^^^^^^^ Method-related `@rbs` annotation must be immediately before a method definition.
        x = 1
      RUBY
    end
  end

  context "with a return annotation not followed by method" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs return: String
        ^^^^^^^^^^^^^^^^^^^^^ Method-related `@rbs` annotation must be immediately before a method definition.
        y = 2
      RUBY
    end
  end

  context "when method annotation is immediately before method definition" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs param x: Integer
        # @rbs return: String
        def method(x)
        end
      RUBY
    end
  end

  context "with a single param annotation before method" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs param x: Integer
        def method(x)
        end
      RUBY
    end
  end

  context "with a single return annotation before method" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs return: String
        def method
        end
      RUBY
    end
  end

  context "with non-method @rbs annotations" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs @ivar: Integer
        # @rbs @@cvar: Float

        def method
        end
      RUBY
    end
  end

  context "with multiple method definitions" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs param x: Integer
        # @rbs return: String
        def method1(x)
        end

        # @rbs param y: Float

        ^{} Remove blank line between method annotation and method definition.
        def method2(y)
        end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs param x: Integer
        # @rbs return: String
        def method1(x)
        end

        # @rbs param y: Float
        def method2(y)
        end
      RUBY
    end
  end

  context "with annotation with colon after keyword" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs param: Integer
        # @rbs return: String

        ^{} Remove blank line between method annotation and method definition.
        def method
        end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs param: Integer
        # @rbs return: String
        def method
        end
      RUBY
    end
  end

  context "when annotation is immediately before method with arguments" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs param x: Integer
        # @rbs param y: String
        # @rbs return: Hash[Symbol, untyped]
        def method(x, y)
        end
      RUBY
    end
  end

  context "when method type signature has blank line before method definition" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        #: (Integer) -> String

        ^{} Remove blank line between method annotation and method definition.
        def method(x)
        end
      RUBY

      expect_correction(<<~RUBY)
        #: (Integer) -> String
        def method(x)
        end
      RUBY
    end
  end

  context "with a method type signature not followed by method" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        #: (Integer) -> String
        ^^^^^^^^^^^^^^^^^^^^^^ Method-related `@rbs` annotation must be immediately before a method definition.
        x = 1
      RUBY
    end
  end

  context "when method type signature is immediately before method" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        #: (Integer) -> String
        def method(x)
        end
      RUBY
    end
  end

  context "with mixed annotation styles" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs param x: Integer
        #: (Integer) -> String

        ^{} Remove blank line between method annotation and method definition.
        def method(x)
        end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs param x: Integer
        #: (Integer) -> String
        def method(x)
        end
      RUBY
    end
  end

  context "with a @rbs block annotation not followed by method" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs &block: (Integer) -> void
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Method-related `@rbs` annotation must be immediately before a method definition.
        x = 1
      RUBY
    end
  end

  context "with a @rbs override annotation not followed by method" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs override
        ^^^^^^^^^^^^^^^ Method-related `@rbs` annotation must be immediately before a method definition.
        x = 1
      RUBY
    end
  end

  context "with a @rbs %a annotation not followed by method" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs %a{pure}
        ^^^^^^^^^^^^^^^ Method-related `@rbs` annotation must be immediately before a method definition.
        x = 1
      RUBY
    end
  end

  context "with a @rbs method signature not followed by method" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs (Integer) -> String
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ Method-related `@rbs` annotation must be immediately before a method definition.
        x = 1
      RUBY
    end
  end

  context "with a @rbs block annotation before method" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs &block: (Integer) -> void
        def method
        end
      RUBY
    end
  end

  context "with a @rbs override annotation before method" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs override
        def method
        end
      RUBY
    end
  end

  context "with a @rbs %a annotation before method" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs %a{pure}
        def method
        end
      RUBY
    end
  end

  context "with a @rbs method signature before method" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs (Integer) -> String
        def method(x)
        end
      RUBY
    end
  end

  context "with a @rbs skip annotation not followed by method" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs skip
        x = 1
      RUBY
    end
  end

  context "with a @rbs skip annotation before class definition" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs skip
        class Foo; end
      RUBY
    end
  end

  context "with a @rbs skip annotation before module definition" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs skip
        module Foo; end
      RUBY
    end
  end

  context "when @rbs skip annotation has blank line before class definition" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs skip
        ^^^^^^^^^^^ Method-related `@rbs` annotation must be immediately before a method definition.

        class Foo; end
      RUBY
    end
  end

  context "when @rbs skip annotation has blank line before method definition" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs skip

        ^{} Remove blank line between method annotation and method definition.
        def method
        end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs skip
        def method
        end
      RUBY
    end
  end

  context "with a @rbs skip annotation before method" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs skip
        def method(x)
        end
      RUBY
    end
  end

  context "with a trailing #: type assertion after attr_reader" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        attr_reader :foo #: Integer
      RUBY
    end
  end

  context "with a trailing #: method type assertion after method definition" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        def method(x) #: (Integer) -> String
        end
      RUBY
    end
  end

  context "with an annotation before private_class_method def" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs x: Integer
        private_class_method def self.method(x)
        end
      RUBY
    end
  end

  context "with an annotation before private def" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs x: Integer
        private def method(x)
        end
      RUBY
    end
  end

  context "with an annotation before protected def" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs x: Integer
        protected def method(x)
        end
      RUBY
    end
  end

  context "with an annotation before module_function def" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs x: Integer
        module_function def method(x)
        end
      RUBY
    end
  end

  context "with a blank line between annotation and private_class_method def" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs x: Integer

        ^{} Remove blank line between method annotation and method definition.
        private_class_method def self.method(x)
        end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs x: Integer
        private_class_method def self.method(x)
        end
      RUBY
    end
  end
end
