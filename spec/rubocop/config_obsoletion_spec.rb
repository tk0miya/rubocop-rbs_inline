# frozen_string_literal: true

RSpec.describe RuboCop::ConfigObsoletion do
  describe "#warnings" do
    subject { obsoletion.warnings }

    let(:obsoletion) do
      config = RuboCop::Config.new({ "Style/RbsInline/RequireRbsInlineComment" => cop_config }, ".rubocop.yml")
      described_class.new(config).tap(&:reject_obsolete!)
    end

    context "when EnforcedStyle is configured" do
      let(:cop_config) { { "EnforcedStyle" => "always" } }

      it "warns about the deprecated parameter without rejecting the configuration" do
        expect(subject).to contain_exactly(
          a_string_matching(%r{obsolete parameter `EnforcedStyle` \(for `Style/RbsInline/RequireRbsInlineComment`\)})
            .and(a_string_matching(/Mode: opt_in/))
        )
      end
    end

    context "when EnforcedStyle is not configured" do
      let(:cop_config) { { "AllowMissingComment" => true } }

      it { is_expected.to be_empty }
    end
  end
end
