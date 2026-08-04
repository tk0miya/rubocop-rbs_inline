# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::StructNewWithBlock, :config do
  let(:config) { rbs_inline_config }

  context "when Struct.new is called with a do...end block" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        User = Struct.new(:name, :role) do
               ^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/StructNewWithBlock: Do not use `Struct.new` with a block. RBS::Inline does not parse block contents, so methods defined in the block will not be recognized. Keep the `Struct.new` call and move the methods into `class User ... end` written after it.
          def admin?
            role == :admin
          end
        end
      RUBY
    end
  end

  context "when Struct.new is called with a brace block" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        User = Struct.new(:name, :role) { }
               ^^^^^^^^^^^^^^^^^^^^^^^^ Style/RbsInline/StructNewWithBlock: Do not use `Struct.new` with a block. RBS::Inline does not parse block contents, so methods defined in the block will not be recognized. Keep the `Struct.new` call and move the methods into `class User ... end` written after it.
      RUBY
    end
  end

  context "when Struct.new with no args is called with a block" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        Empty = Struct.new do
                ^^^^^^^^^^ Style/RbsInline/StructNewWithBlock: Do not use `Struct.new` with a block. RBS::Inline does not parse block contents, so methods defined in the block will not be recognized. Keep the `Struct.new` call and move the methods into `class Empty ... end` written after it.
          def foo
            42
          end
        end
      RUBY
    end
  end

  context "when Struct.new with a block is assigned to a namespaced constant" do
    it "names the namespaced class to reopen" do
      expect_offense(<<~RUBY)
        Foo::User = Struct.new(:name) { }
                    ^^^^^^^^^^^^^^^^^ Style/RbsInline/StructNewWithBlock: Do not use `Struct.new` with a block. RBS::Inline does not parse block contents, so methods defined in the block will not be recognized. Keep the `Struct.new` call and move the methods into `class Foo::User ... end` written after it.
      RUBY
    end
  end

  context "when Struct.new with a block is assigned under a dynamic namespace" do
    it "registers an offense without a class name" do
      expect_offense(<<~RUBY)
        self::Foo::User = Struct.new(:name) { }
                          ^^^^^^^^^^^^^^^^^ Style/RbsInline/StructNewWithBlock: Do not use `Struct.new` with a block. RBS::Inline does not parse block contents, so methods defined in the block will not be recognized. Keep the `Struct.new` call and move the methods into a `class` that reopens it.
      RUBY
    end
  end

  context "when Struct.new with a block is assigned to a constant at the root namespace" do
    it "keeps the leading `::` in the class name" do
      expect_offense(<<~RUBY)
        ::User = Struct.new(:name) { }
                 ^^^^^^^^^^^^^^^^^ Style/RbsInline/StructNewWithBlock: Do not use `Struct.new` with a block. RBS::Inline does not parse block contents, so methods defined in the block will not be recognized. Keep the `Struct.new` call and move the methods into `class ::User ... end` written after it.
      RUBY
    end
  end

  context "when Struct.new with a block is not assigned to a constant" do
    it "registers an offense without a class name" do
      expect_offense(<<~RUBY)
        user = Struct.new(:name) { }
               ^^^^^^^^^^^^^^^^^ Style/RbsInline/StructNewWithBlock: Do not use `Struct.new` with a block. RBS::Inline does not parse block contents, so methods defined in the block will not be recognized. Keep the `Struct.new` call and move the methods into a `class` that reopens it.
      RUBY
    end
  end

  context "when Struct.new is called without a block" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        User = Struct.new(:name, :role)
      RUBY
    end
  end

  context "when class is reopened separately" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        User = Struct.new(:name, :role)

        class User
          def admin?
            role == :admin
          end
        end
      RUBY
    end
  end

  context "with other new calls with a block" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        Foo.new(:name) do
        end
      RUBY
    end
  end

  context "with Data.define with a block" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        Foo = Data.define(:name) do
        end
      RUBY
    end
  end
end
