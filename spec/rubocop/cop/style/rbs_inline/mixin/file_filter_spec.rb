# frozen_string_literal: true

# These specs exercise the shared `FileFilter` mixin using
# `Style/RbsInline/InvalidComment` as a vehicle cop (a simple cop that flags
# `# () -> void`-style comments). Every `context` here describes filter
# behavior, not the vehicle cop's own detection logic. Mode is set at the
# `Style/RbsInline` department level — the public interface for consumers.
RSpec.describe RuboCop::Cop::Style::RbsInline::FileFilter, :config do
  let(:cop_class) { RuboCop::Cop::Style::RbsInline::InvalidComment }

  before do
    described_class.instance_variable_set(:@warned_invalid_modes, {})
    allow(Kernel).to receive(:warn)
  end

  shared_examples "runs on the file" do
    it "reports offenses in the file" do
      expect_offense(<<~RUBY)
        # () -> void
        ^^^^^^^^^^^^ Invalid RBS annotation comment found.
      RUBY
    end
  end

  shared_examples "skips the file" do
    it "does not report offenses in the file" do
      expect_no_offenses(<<~RUBY)
        # () -> void
      RUBY
    end
  end

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
      it_behaves_like "skips the file"
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
      it_behaves_like "runs on the file"
    end
  end

  context "when Mode is unset (legacy default)" do
    let(:config) { RuboCop::Config.new("Style/RbsInline/InvalidComment" => {}) }

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
      it "reports offenses (no filter applied when Mode is unset)" do
        expect_offense(<<~RUBY)
          # rbs_inline: disabled
          # () -> void
          ^^^^^^^^^^^^ Invalid RBS annotation comment found.
        RUBY
      end
    end

    context "when the file has no magic comment" do
      it_behaves_like "runs on the file"
    end
  end

  context "when Mode is set to an invalid value" do
    context "with a typo string" do
      let(:config) { RuboCop::Config.new("Style/RbsInline" => { "Mode" => "opt-in" }) }

      it "warns and disables filtering for the run" do
        expect_offense(<<~RUBY)
          # () -> void
          ^^^^^^^^^^^^ Invalid RBS annotation comment found.
        RUBY

        expect(Kernel).to have_received(:warn).with(/Mode "opt-in" is not supported/)
      end
    end

    context "with a YAML-native non-string type" do
      let(:config) { RuboCop::Config.new("Style/RbsInline" => { "Mode" => 42 }) }

      it "does not raise (falls back to no filter)" do
        processed = parse_source("# () -> void\n", "example.rb")
        commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
        expect { commissioner.investigate(processed) }.not_to raise_error
      end
    end
  end
end
