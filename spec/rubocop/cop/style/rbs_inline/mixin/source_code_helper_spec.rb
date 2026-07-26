# frozen_string_literal: true

# These specs exercise the shared `SourceCodeHelper` mixin through a bare host
# class, since the offset conversion it provides is independent of any cop.
RSpec.describe RuboCop::Cop::Style::RbsInline::SourceCodeHelper do
  let(:helper_class) do
    Class.new do
      include RuboCop::Cop::Style::RbsInline::SourceCodeHelper

      attr_reader :processed_source

      def initialize(processed_source)
        @processed_source = processed_source
      end
    end
  end
  let(:helper) { helper_class.new(parse_source(source, "example.rb")) }

  describe "#character_offset" do
    subject { helper.character_offset(byte_offset) }

    context "when the source is ASCII only" do
      let(:source) { "# @rbs foo: String\n" }
      let(:byte_offset) { 7 }

      it { is_expected.to eq(7) }
    end

    context "when the leading bytes contain multibyte characters" do
      # `"# コメント\n"` is 15 bytes but only 7 characters.
      let(:source) { "# コメント\n# @rbs foo: String\n" }
      let(:byte_offset) { 15 }

      it "counts characters rather than bytes" do
        expect(subject).to eq(7)
      end
    end
  end

  describe "#location_to_range" do
    subject { helper.location_to_range(location) }

    let(:location) { Prism.parse(source).value.statements.body.first.location }

    context "when the source contains multibyte characters before the node" do
      let(:source) { <<~RUBY }
        # コメント
        foo
      RUBY

      it "returns a range that points at the node" do
        expect(subject.source).to eq("foo")
      end
    end
  end
end
