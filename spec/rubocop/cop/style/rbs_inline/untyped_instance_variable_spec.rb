# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::UntypedInstanceVariable, :config do
  let(:config) { RuboCop::Config.new }

  context "when instance variable has no type annotation" do
    context "with an ivar read (may be defined in parent class)" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Foo
            def bar
              @baz
            end
          end
        RUBY
      end
    end

    context "with an ivar assignment inside a method" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class Foo
            def bar
              @baz = 1
              ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@baz` is not typed. Add `# @rbs @baz: Type` or use `attr_* :baz #: Type`.
            end
          end
        RUBY
      end
    end

    context "with multiple untyped ivar assignments" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class Foo
            def bar
              @baz = 1
              ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@baz` is not typed. Add `# @rbs @baz: Type` or use `attr_* :baz #: Type`.
              @qux = 2
              ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@qux` is not typed. Add `# @rbs @qux: Type` or use `attr_* :qux #: Type`.
            end
          end
        RUBY
      end
    end

    context "with an ivar assignment in a module" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          module Foo
            def bar
              @baz = 1
              ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@baz` is not typed. Add `# @rbs @baz: Type` or use `attr_* :baz #: Type`.
            end
          end
        RUBY
      end
    end

    context "with an ivar in ||= expression" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class Foo
            def bar
              @baz ||= 1
              ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@baz` is not typed. Add `# @rbs @baz: Type` or use `attr_* :baz #: Type`.
            end
          end
        RUBY
      end
    end

    context "with an ivar in initialize" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class Foo
            def initialize
              @baz = 1
              ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@baz` is not typed. Add `# @rbs @baz: Type` or use `attr_* :baz #: Type`.
            end
          end
        RUBY
      end
    end

    context "when an ivar is assigned in multiple methods" do
      it "reports each ivar only once" do
        expect_offense(<<~RUBY)
          class Foo
            def bar
              @baz = 1
              ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@baz` is not typed. Add `# @rbs @baz: Type` or use `attr_* :baz #: Type`.
            end

            def baz
              @baz = 2
            end
          end
        RUBY
      end
    end

    context "when ivar is only read (not assigned)" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Foo
            def bar
              @baz
            end

            def baz
              @baz
            end
          end
        RUBY
      end
    end

    context "when attr_reader has no inline type comment" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Foo
            attr_reader :baz

            def bar
              @baz
            end
          end
        RUBY
      end
    end
  end

  context "when instance variable has a @rbs annotation" do
    context "with @rbs @ivar annotation" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Foo
            # @rbs @baz: Integer

            def bar
              @baz
            end
          end
        RUBY
      end
    end

    context "with @rbs annotation for assignment" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Foo
            # @rbs @baz: Integer

            def initialize
              @baz = 1
            end
          end
        RUBY
      end
    end

    context "with multiple @rbs annotations" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Foo
            # @rbs @baz: Integer
            # @rbs @qux: String

            def initialize
              @baz = 1
              @qux = 'hello'
            end
          end
        RUBY
      end
    end
  end

  context "when instance variable is covered by typed attr_*" do
    context "with attr_reader and inline type" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Foo
            attr_reader :baz  #: Integer

            def bar
              @baz
            end
          end
        RUBY
      end
    end

    context "with attr_writer and inline type" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Foo
            attr_writer :baz  #: Integer

            def bar
              @baz = 1
            end
          end
        RUBY
      end
    end

    context "with attr_accessor and inline type" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Foo
            attr_accessor :baz  #: Integer

            def bar
              @baz
            end
          end
        RUBY
      end
    end

    context "with multiple attrs and inline types" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Foo
            attr_reader :baz, :qux  #: Integer

            def bar
              @baz
              @qux
            end
          end
        RUBY
      end
    end
  end

  context "with nested classes" do
    context "when only inner class annotates the ivar but outer assigns it" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class Outer
            class Inner
              # @rbs @baz: Integer
            end

            def foo
              @baz = 1
              ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@baz` is not typed. Add `# @rbs @baz: Type` or use `attr_* :baz #: Type`.
            end
          end
        RUBY
      end
    end

    context "when only outer is annotated but inner class assigns the ivar" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class Outer
            # @rbs @baz: Integer

            class Inner
              def bar
                @baz = 1
                ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@baz` is not typed. Add `# @rbs @baz: Type` or use `attr_* :baz #: Type`.
              end
            end

            def foo
              @baz = 1
            end
          end
        RUBY
      end
    end

    context "when each class annotates its own ivars" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Outer
            # @rbs @baz: Integer

            class Inner
              # @rbs @baz: String

              def bar
                @baz = 'hello'
              end
            end

            def foo
              @baz = 1
            end
          end
        RUBY
      end
    end

    context "when inner class ivar is typed and outer has none" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Outer
            class Inner
              # @rbs @baz: Integer

              def bar
                @baz = 1
              end
            end
          end
        RUBY
      end
    end

    context "with a read-only ivar in outer class" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Outer
            class Inner
              # @rbs @baz: Integer
            end

            def foo
              @baz
            end
          end
        RUBY
      end
    end
  end

  context "with top-level methods (no class)" do
    context "with ivar assignments outside any class" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          def bar
            @baz = 1
            ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@baz` is not typed. Add `# @rbs @baz: Type` or use `attr_* :baz #: Type`.
          end
        RUBY
      end
    end

    context "with ivar reads outside any class" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          def bar
            @baz
          end
        RUBY
      end
    end

    context "when top-level ivar has @rbs annotation" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          # @rbs @baz: Integer

          def bar
            @baz = 1
          end
        RUBY
      end
    end
  end

  context "with class-level (singleton) instance variables" do
    context "with @rbs self.@ivar annotation inside `class << self`" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Foo
            # @rbs self.@instance: Foo

            class << self
              def instance
                @instance ||= new
              end
            end
          end
        RUBY
      end
    end

    context "with @rbs self.@ivar annotation inside `def self.x`" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Foo
            # @rbs self.@instance: Foo

            def self.instance
              @instance ||= new
            end
          end
        RUBY
      end
    end

    context "with a class-level ivar assignment without annotation" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class Foo
            class << self
              def instance
                @instance ||= new
                ^^^^^^^^^ Style/RbsInline/UntypedInstanceVariable: Class instance variable `@instance` is not typed. Add `# @rbs self.@instance: Type` or use `attr_* :instance #: Type`.
              end
            end
          end
        RUBY
      end
    end

    context "with a class-level ivar assignment in `def self.x` without annotation" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class Foo
            def self.instance
              @instance ||= new
              ^^^^^^^^^ Style/RbsInline/UntypedInstanceVariable: Class instance variable `@instance` is not typed. Add `# @rbs self.@instance: Type` or use `attr_* :instance #: Type`.
            end
          end
        RUBY
      end
    end

    context "with an instance-level annotation and a class-level assignment" do
      it "distinguishes class-level from instance-level annotations" do
        expect_offense(<<~RUBY)
          class Foo
            # @rbs @instance: Foo

            def self.instance
              @instance ||= new
              ^^^^^^^^^ Style/RbsInline/UntypedInstanceVariable: Class instance variable `@instance` is not typed. Add `# @rbs self.@instance: Type` or use `attr_* :instance #: Type`.
            end
          end
        RUBY
      end
    end

    context "with a class-level annotation but an instance-level assignment" do
      it "does not confuse instance-level assignment inside instance methods with class-level annotation" do
        expect_offense(<<~RUBY)
          class Foo
            # @rbs self.@instance: Foo

            def initialize
              @instance = self
              ^^^^^^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@instance` is not typed. Add `# @rbs @instance: Type` or use `attr_* :instance #: Type`.
            end
          end
        RUBY
      end
    end

    context "when `class << self` attr_* declares the ivar" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Foo
            class << self
              attr_accessor :instance  #: Foo?

              def build
                @instance ||= new
              end
            end
          end
        RUBY
      end
    end

    context "with an instance-level attr_* and a class-level ivar assignment" do
      it "does not treat instance-level attr_* as covering a class-level ivar" do
        expect_offense(<<~RUBY)
          class Foo
            attr_accessor :instance  #: Foo?

            def self.build
              @instance ||= new
              ^^^^^^^^^ Style/RbsInline/UntypedInstanceVariable: Class instance variable `@instance` is not typed. Add `# @rbs self.@instance: Type` or use `attr_* :instance #: Type`.
            end
          end
        RUBY
      end
    end

    context "with a class-level attr_* and an instance-level ivar assignment" do
      it "does not treat class-level attr_* as covering an instance-level ivar" do
        expect_offense(<<~RUBY)
          class Foo
            class << self
              attr_accessor :instance  #: Foo?
            end

            def initialize
              @instance = self
              ^^^^^^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@instance` is not typed. Add `# @rbs @instance: Type` or use `attr_* :instance #: Type`.
            end
          end
        RUBY
      end
    end

    context "with a nested class inside `class << self`" do
      it "treats nested class inside `class << self` as a fresh (non-singleton) context" do
        expect_offense(<<~RUBY)
          class Foo
            class << self
              class Bar
                def initialize
                  @baz = 1
                  ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@baz` is not typed. Add `# @rbs @baz: Type` or use `attr_* :baz #: Type`.
                end
              end
            end
          end
        RUBY
      end
    end
  end

  context "with mixed typed and untyped ivars" do
    it "only reports the untyped ivar assignment" do
      expect_offense(<<~RUBY)
        class Foo
          # @rbs @baz: Integer

          def bar
            @baz = 1
            @qux = 2
            ^^^^ Style/RbsInline/UntypedInstanceVariable: Instance variable `@qux` is not typed. Add `# @rbs @qux: Type` or use `attr_* :qux #: Type`.
          end
        end
      RUBY
    end
  end
end
