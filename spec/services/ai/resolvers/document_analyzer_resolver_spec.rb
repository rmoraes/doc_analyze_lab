require "rails_helper"

RSpec.describe AI::Resolvers::DocumentAnalyzerResolver do
  describe ".resolve" do
    subject(:resolve) { described_class.resolve(provider) }

    context "when provider is valid" do
      let(:provider) { :openai }

      it "returns an instance of OpenAI::DocumentAnalyzer" do
        expect(resolve).to be_an_instance_of(AI::Providers::OpenAI::DocumentAnalyzer)
      end
    end

    context "when provider is invalid" do
      include_examples "unsupported provider", :unknown_provider
      include_examples "unsupported provider", "openai"
      include_examples "unsupported provider", ""
      include_examples "unsupported provider", nil
    end
  end
end
