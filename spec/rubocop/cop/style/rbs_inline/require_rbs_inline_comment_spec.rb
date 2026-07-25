# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::RequireRbsInlineComment, :config do
  before do
    described_class.instance_variable_set(:@enforced_style_deprecation_warned, false)
    allow(Kernel).to receive(:warn)
  end

  # `Mode` is a department-level setting; everything else belongs to the cop.
  def config_for(mode, cop_params)
    RuboCop::Config.new(
      "Style/RbsInline" => mode ? { "Mode" => mode } : {},
      "Style/RbsInline/RequireRbsInlineComment" => cop_params
    )
  end

  shared_examples "opt_in behavior" do |mode, cop_params = {}|
    context "when AllowMissingComment is false (default)" do
      let(:config) { config_for(mode, cop_params) }

      context "when the file has `# rbs_inline: enabled`" do
        it "does not register an offense" do
          expect_no_offenses(<<~RUBY)
            # rbs_inline: enabled
            class Foo
            end
          RUBY
        end
      end

      context "when the file has `# rbs_inline: disabled`" do
        it "does not register an offense" do
          expect_no_offenses(<<~RUBY)
            # rbs_inline: disabled
            class Foo
            end
          RUBY
        end
      end

      context "when the file is empty" do
        it "does not register an offense" do
          expect_no_offenses("")
        end
      end

      context "when the file has no magic comment" do
        it "registers an offense and inserts the magic comment at the top" do
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
      end

      context "when code appears before any leading comment" do
        it "registers an offense and inserts the magic comment before the code" do
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
      end

      context "when the file has a leading comment block" do
        it "registers an offense and inserts the magic comment after the leading block" do
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

      context "when the leading comment block ends without a trailing newline" do
        it "registers an offense and inserts the magic comment on its own line" do
          expect_offense(<<~RUBY.chomp)
            # frozen_string_literal: true
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Missing `# rbs_inline:` magic comment.
            # encoding: utf-8
          RUBY

          expect_correction(<<~RUBY)
            # frozen_string_literal: true
            # encoding: utf-8
            # rbs_inline: enabled
          RUBY
        end
      end

      context "when the pragma has extra spaces (malformed)" do
        it "does not accept the malformed pragma and registers an offense" do
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
      end

      context "when the pragma has no spaces (malformed)" do
        it "does not accept the malformed pragma and registers an offense" do
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

    context "when AllowMissingComment is true" do
      let(:config) { config_for(mode, cop_params.merge("AllowMissingComment" => true)) }

      context "when the file has `# rbs_inline: enabled`" do
        it "does not register an offense" do
          expect_no_offenses(<<~RUBY)
            # rbs_inline: enabled
            class Foo
            end
          RUBY
        end
      end

      context "when the file has `# rbs_inline: disabled`" do
        it "does not register an offense" do
          expect_no_offenses(<<~RUBY)
            # rbs_inline: disabled
            class Foo
            end
          RUBY
        end
      end

      context "when the file has no magic comment" do
        it "does not register an offense" do
          expect_no_offenses(<<~RUBY)
            class Foo
            end
          RUBY
        end
      end
    end
  end

  shared_examples "opt_out behavior" do |mode, cop_params = {}|
    let(:config) { config_for(mode, cop_params) }

    context "when the file has `# rbs_inline: enabled`" do
      it "registers an offense and removes the magic comment" do
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
    end

    context "when the file has `# rbs_inline: disabled`" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          # rbs_inline: disabled
          class Foo
          end
        RUBY
      end
    end

    context "when the file has no magic comment" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          class Foo
          end
        RUBY
      end
    end
  end

  context "when Mode is opt_in" do
    it_behaves_like "opt_in behavior", "opt_in"
  end

  context "when Mode is opt_out" do
    it_behaves_like "opt_out behavior", "opt_out"
  end

  context "when Mode is not set (legacy default)" do
    it_behaves_like "opt_in behavior", nil
  end

  context "when only legacy EnforcedStyle is set" do
    context "with EnforcedStyle: always" do
      it_behaves_like "opt_in behavior", nil, { "EnforcedStyle" => "always" }
    end

    context "with EnforcedStyle: never" do
      it_behaves_like "opt_out behavior", nil, { "EnforcedStyle" => "never" }
    end

    describe "deprecation warning" do
      let(:config) { config_for(nil, { "EnforcedStyle" => "always" }) }

      it "emits a deprecation warning for EnforcedStyle" do
        expect_no_offenses("# rbs_inline: enabled\nclass Foo\nend\n")
        expect(Kernel).to have_received(:warn).with(/EnforcedStyle is deprecated/)
      end
    end
  end

  context "when Mode overrides EnforcedStyle" do
    it_behaves_like "opt_out behavior", "opt_out", { "EnforcedStyle" => "always" }
  end
end
