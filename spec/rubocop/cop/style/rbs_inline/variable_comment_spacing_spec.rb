# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::VariableCommentSpacing, :config do
  let(:config) { rbs_inline_config }

  context "when @rbs @ivar comment is directly followed by code" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs @ivar: Integer
        def method
        ^^^^^^^^^^ Style/RbsInline/VariableCommentSpacing: `@rbs` variable comment must be followed by a blank line.
        end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs @ivar: Integer

        def method
        end
      RUBY
    end
  end

  context "when @rbs @@cvar comment is directly followed by code" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs @@cvar: Float
        def method
        ^^^^^^^^^^ Style/RbsInline/VariableCommentSpacing: `@rbs` variable comment must be followed by a blank line.
        end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs @@cvar: Float

        def method
        end
      RUBY
    end
  end

  context "when @rbs self.@civar comment is directly followed by code" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs self.@civar: String
        def method
        ^^^^^^^^^^ Style/RbsInline/VariableCommentSpacing: `@rbs` variable comment must be followed by a blank line.
        end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs self.@civar: String

        def method
        end
      RUBY
    end
  end

  context "when multiple variable comments are directly followed by code" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs @ivar: Integer
        # @rbs @@cvar: Float
        # @rbs self.@civar: String
        def method
        ^^^^^^^^^^ Style/RbsInline/VariableCommentSpacing: `@rbs` variable comment must be followed by a blank line.
        end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs @ivar: Integer
        # @rbs @@cvar: Float
        # @rbs self.@civar: String

        def method
        end
      RUBY
    end
  end

  context "when @rbs @ivar comment is followed by a blank line" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs @ivar: Integer

        def method
        end
      RUBY
    end
  end

  context "when multiple variable comments are followed by a blank line" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs @ivar: Integer
        # @rbs @@cvar: Float
        # @rbs self.@civar: String

        def method
        end
      RUBY
    end
  end

  context "when @rbs variable comment is at the end of file" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs @ivar: Integer
      RUBY
    end
  end

  context "when @rbs variable comment is followed by a class definition" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs @ivar: Integer
        class Foo
        ^^^^^^^^^ Style/RbsInline/VariableCommentSpacing: `@rbs` variable comment must be followed by a blank line.
        end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs @ivar: Integer

        class Foo
        end
      RUBY
    end
  end

  context "with multiple variable comment blocks properly spaced" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs @ivar1: Integer

        def method1
        end

        # @rbs @ivar2: String

        def method2
        end
      RUBY
    end
  end

  context "with non-variable @rbs comments" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        # @rbs return: Integer
        def method
        end
      RUBY
    end
  end

  context "when variable comment is followed by module definition" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        # @rbs @@config: Hash[Symbol, untyped]
        module Config
        ^^^^^^^^^^^^^ Style/RbsInline/VariableCommentSpacing: `@rbs` variable comment must be followed by a blank line.
        end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs @@config: Hash[Symbol, untyped]

        module Config
        end
      RUBY
    end
  end

  context "with consecutive @rbs variable comments and other @rbs comments" do
    context "when @rbs variable is followed by method annotation without blank line" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          # @rbs @ivar: Integer
          # @rbs return: String
          ^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/VariableCommentSpacing: `@rbs` variable comment must be followed by a blank line.
          def bar; end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs @ivar: Integer

          # @rbs return: String
          def bar; end
        RUBY
      end
    end

    context "when @rbs variable is followed by blank line before method annotation" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          # @rbs @ivar: Integer

          # @rbs return: String
          def bar; end
        RUBY
      end
    end
  end

  context "with class definitions" do
    context "when variable comments inside class are directly followed by method" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class Foo
            # @rbs @ivar: Integer
            # @rbs @@cvar: Float
            def method
          ^^^^^^^^^^^^ Style/RbsInline/VariableCommentSpacing: `@rbs` variable comment must be followed by a blank line.
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          class Foo
            # @rbs @ivar: Integer
            # @rbs @@cvar: Float

            def method
            end
          end
        RUBY
      end
    end

    context "when properly spaced inside class" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Foo
            # @rbs @ivar: Integer
            # @rbs @@cvar: Float

            def method
            end
          end
        RUBY
      end
    end
  end
end
