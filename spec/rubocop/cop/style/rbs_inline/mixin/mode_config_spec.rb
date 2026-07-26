# frozen_string_literal: true

# These specs exercise the shared `ModeConfig` mixin using
# `Style/RbsInline/InvalidComment` as a vehicle cop.
RSpec.describe RuboCop::Cop::Style::RbsInline::ModeConfig, :config do
  let(:cop_class) { RuboCop::Cop::Style::RbsInline::InvalidComment }

  describe "#validate_config" do
    subject { cop.validate_config }

    context "when Mode is supported" do
      let(:config) { RuboCop::Config.new("Style/RbsInline" => { "Mode" => "opt_out" }) }

      it "does not raise" do
        expect { subject }.not_to raise_error
      end
    end

    context "when Mode is not supported" do
      context "when Mode is unset" do
        # An empty hash rather than no argument: `RuboCop::Config.new` defaults to
        # the configuration `config/default.yml` is merged into.
        let(:config) { RuboCop::Config.new({}) }

        it "raises a validation error" do
          expect { subject }
            .to raise_error(RuboCop::ValidationError, %r{`Style/RbsInline: Mode: nil` is not supported})
        end
      end

      context "when Mode is a typo string" do
        let(:config) { RuboCop::Config.new("Style/RbsInline" => { "Mode" => "opt-in" }) }

        it "raises a validation error" do
          expect { subject }
            .to raise_error(RuboCop::ValidationError, %r{`Style/RbsInline: Mode: "opt-in"` is not supported})
        end
      end

      context "when Mode is a YAML-native non-string type" do
        let(:config) { RuboCop::Config.new("Style/RbsInline" => { "Mode" => 42 }) }

        it "raises a validation error" do
          expect { subject }
            .to raise_error(RuboCop::ValidationError, %r{`Style/RbsInline: Mode: 42` is not supported})
        end
      end
    end

    # Without the hook, the same error would be raised per file and reported as an
    # inspection error, which leaves the run green.
    context "when the cop is mobilized by RuboCop::Cop::Team" do
      subject { RuboCop::Cop::Team.mobilize([cop_class], config) }

      let(:config) { RuboCop::Config.new("Style/RbsInline" => { "Mode" => "opt-in" }) }

      it "is called before any file is inspected" do
        expect { subject }
          .to raise_error(RuboCop::ValidationError, %r{`Style/RbsInline: Mode: "opt-in"` is not supported})
      end
    end
  end
end
