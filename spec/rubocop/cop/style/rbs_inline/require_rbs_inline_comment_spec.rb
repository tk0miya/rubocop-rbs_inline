# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::RequireRbsInlineComment, :config do
  before do
    described_class.instance_variable_set(:@enforced_style_deprecation_warned, false)
    allow(Kernel).to receive(:warn)
  end

  shared_examples "opt_in behavior" do
    it "registers an offense when rbs_inline comment is missing" do
      expect_offense(<<~RUBY)
        class Foo
        ^^^^^^^^^ Missing `# rbs_inline:` magic comment.
        end
      RUBY

      expect_correction(<<~RUBY)
        # rbs_inline: enabled
        class Foo
        end
      RUBY
    end

    it "does not register an offense when rbs_inline is enabled" do
      expect_no_offenses(<<~RUBY)
        # rbs_inline: enabled
        class Foo
        end
      RUBY
    end

    it "does not register an offense when rbs_inline is disabled" do
      expect_no_offenses(<<~RUBY)
        # rbs_inline: disabled
        class Foo
        end
      RUBY
    end

    it "does not register an offense for empty files" do
      expect_no_offenses("")
    end

    it "inserts magic comment at the beginning when code comes before comments" do
      expect_offense(<<~RUBY)
        puts "hello"
        ^^^^^^^^^^^^ Missing `# rbs_inline:` magic comment.

        # blah blah blah
        # blah blah blah
      RUBY

      expect_correction(<<~RUBY)
        # rbs_inline: enabled
        puts "hello"

        # blah blah blah
        # blah blah blah
      RUBY
    end

    it "inserts magic comment after leading comment block" do
      expect_offense(<<~RUBY)
        # frozen_string_literal: true
        # encoding: utf-8
        class Foo
        ^^^^^^^^^ Missing `# rbs_inline:` magic comment.
        end
      RUBY

      expect_correction(<<~RUBY)
        # frozen_string_literal: true
        # encoding: utf-8
        # rbs_inline: enabled
        class Foo
        end
      RUBY
    end
  end

  shared_examples "opt_out behavior" do
    it "registers an offense when rbs_inline is enabled" do
      expect_offense(<<~RUBY)
        # rbs_inline: enabled
        ^^^^^^^^^^^^^^^^^^^^^ Remove `# rbs_inline:` magic comment.
        class Foo
        end
      RUBY

      expect_correction(<<~RUBY)
        class Foo
        end
      RUBY
    end

    it "does not register an offense when rbs_inline is disabled" do
      expect_no_offenses(<<~RUBY)
        # rbs_inline: disabled
        class Foo
        end
      RUBY
    end

    it "does not register an offense when rbs_inline comment is missing" do
      expect_no_offenses(<<~RUBY)
        class Foo
        end
      RUBY
    end
  end

  context "when Mode is opt_in" do
    let(:config) do
      RuboCop::Config.new("Style/RbsInline/RequireRbsInlineComment" => {
                            "Mode" => "opt_in"
                          })
    end

    it_behaves_like "opt_in behavior"

    context "with AllowMissingComment: true" do
      let(:config) do
        RuboCop::Config.new("Style/RbsInline/RequireRbsInlineComment" => {
                              "Mode" => "opt_in",
                              "AllowMissingComment" => true
                            })
      end

      it "does not register an offense when rbs_inline comment is missing" do
        expect_no_offenses(<<~RUBY)
          class Foo
          end
        RUBY
      end

      it "does not register an offense when rbs_inline is enabled" do
        expect_no_offenses(<<~RUBY)
          # rbs_inline: enabled
          class Foo
          end
        RUBY
      end

      it "does not register an offense when rbs_inline is disabled" do
        expect_no_offenses(<<~RUBY)
          # rbs_inline: disabled
          class Foo
          end
        RUBY
      end
    end
  end

  context "when Mode is opt_out" do
    let(:config) do
      RuboCop::Config.new("Style/RbsInline/RequireRbsInlineComment" => {
                            "Mode" => "opt_out"
                          })
    end

    it_behaves_like "opt_out behavior"
  end

  context "when Mode is not set (legacy default behavior)" do
    let(:config) do
      RuboCop::Config.new("Style/RbsInline/RequireRbsInlineComment" => {})
    end

    it_behaves_like "opt_in behavior"
  end

  context "when only legacy EnforcedStyle is set" do
    context "with EnforcedStyle: always" do
      let(:config) do
        RuboCop::Config.new("Style/RbsInline/RequireRbsInlineComment" => {
                              "EnforcedStyle" => "always"
                            })
      end

      it_behaves_like "opt_in behavior"
    end

    context "with EnforcedStyle: never" do
      let(:config) do
        RuboCop::Config.new("Style/RbsInline/RequireRbsInlineComment" => {
                              "EnforcedStyle" => "never"
                            })
      end

      it_behaves_like "opt_out behavior"
    end

    describe "deprecation warning" do
      let(:config) do
        RuboCop::Config.new("Style/RbsInline/RequireRbsInlineComment" => {
                              "EnforcedStyle" => "always"
                            })
      end

      it "emits a deprecation warning for EnforcedStyle" do
        expect_no_offenses("# rbs_inline: enabled\nclass Foo\nend\n")
        expect(Kernel).to have_received(:warn).with(/EnforcedStyle is deprecated/)
      end
    end
  end

  context "when Mode overrides EnforcedStyle" do
    let(:config) do
      RuboCop::Config.new("Style/RbsInline/RequireRbsInlineComment" => {
                            "Mode" => "opt_out",
                            "EnforcedStyle" => "always"
                          })
    end

    it_behaves_like "opt_out behavior"
  end

  context "with different comment formats" do
    let(:config) do
      RuboCop::Config.new("Style/RbsInline/RequireRbsInlineComment" => {
                            "Mode" => "opt_in"
                          })
    end

    it "rejects comment with extra spaces" do
      expect_offense(<<~RUBY)
        #  rbs_inline:  enabled
        class Foo
        ^^^^^^^^^ Missing `# rbs_inline:` magic comment.
        end
      RUBY

      expect_correction(<<~RUBY)
        #  rbs_inline:  enabled
        # rbs_inline: enabled
        class Foo
        end
      RUBY
    end

    it "rejects comment without spaces" do
      expect_offense(<<~RUBY)
        #rbs_inline:enabled
        class Foo
        ^^^^^^^^^ Missing `# rbs_inline:` magic comment.
        end
      RUBY

      expect_correction(<<~RUBY)
        #rbs_inline:enabled
        # rbs_inline: enabled
        class Foo
        end
      RUBY
    end
  end
end
