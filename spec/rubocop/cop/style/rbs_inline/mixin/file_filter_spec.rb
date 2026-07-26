# frozen_string_literal: true

# These specs exercise the shared `FileFilter` mixin using
# `Style/RbsInline/InvalidComment` as a vehicle cop (a simple cop that flags
# `# () -> void`-style comments). Every `context` here describes filter
# behavior, not the vehicle cop's own detection logic. Mode is set at the
# `Style/RbsInline` department level — the public interface for consumers.
RSpec.describe RuboCop::Cop::Style::RbsInline::FileFilter, :config do
  let(:cop_class) { RuboCop::Cop::Style::RbsInline::InvalidComment }

  context "when Mode is opt_in" do
    let(:config) { RuboCop::Config.new("Style/RbsInline" => { "Mode" => "opt_in" }) }

    context "when the file has `# rbs_inline: enabled`" do
      it "reports offenses" do
        expect_offense(<<~RUBY)
          # rbs_inline: enabled
          # () -> void
          ^^^^^^^^^^^^ Invalid RBS annotation comment found.
        RUBY
      end
    end

    context "when the file has `# rbs_inline: disabled`" do
      it "skips the file" do
        expect_no_offenses(<<~RUBY)
          # rbs_inline: disabled
          # () -> void
        RUBY
      end
    end

    context "when the file has no magic comment" do
      it "skips the file" do
        expect_no_offenses(<<~RUBY)
          # () -> void
        RUBY
      end
    end

    context "when the pragma is not at the top of the file" do
      it "recognizes the pragma" do
        expect_offense(<<~RUBY)
          # frozen_string_literal: true
          # encoding: utf-8

          # rbs_inline: enabled

          # () -> void
          ^^^^^^^^^^^^ Invalid RBS annotation comment found.
        RUBY
      end
    end

    context "when the pragma appears inside a string literal" do
      it "does not treat the string content as opt-in" do
        expect_no_offenses(<<~RUBY)
          code = <<~STR
            # rbs_inline: enabled
          STR
          # () -> void
        RUBY
      end
    end

    context "when the file uses CRLF line endings" do
      it "recognizes the pragma" do
        source = "# rbs_inline: enabled\r\n# () -> void\r\n"
        processed = parse_source(source, "example.rb")
        commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
        offenses = commissioner.investigate(processed).offenses
        expect(offenses).not_to be_empty
      end
    end
  end

  context "when Mode is opt_out" do
    let(:config) { RuboCop::Config.new("Style/RbsInline" => { "Mode" => "opt_out" }) }

    context "when the file has `# rbs_inline: enabled`" do
      it "reports offenses" do
        expect_offense(<<~RUBY)
          # rbs_inline: enabled
          # () -> void
          ^^^^^^^^^^^^ Invalid RBS annotation comment found.
        RUBY
      end
    end

    context "when the file has `# rbs_inline: disabled`" do
      it "skips the file" do
        expect_no_offenses(<<~RUBY)
          # rbs_inline: disabled
          # () -> void
        RUBY
      end
    end

    context "when the file has no magic comment" do
      it "reports offenses" do
        expect_offense(<<~RUBY)
          # () -> void
          ^^^^^^^^^^^^ Invalid RBS annotation comment found.
        RUBY
      end
    end
  end
end
