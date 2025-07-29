require "rails_helper"

RSpec.describe AI::Service do
  let(:provider) { :openai }
  let(:prompt) { "Extract identity information from this document" }
  let(:file_path) { Rails.root.join("spec/fixtures/test_document.jpg") }
  let(:mock_document_analyzer) { instance_double(AI::Providers::OpenAI::DocumentAnalyzer) }

  subject(:service) { described_class.new(provider: provider) }

  before do
    allow(AI::Resolvers::DocumentAnalyzerResolver)
      .to receive(:resolve).with(provider).and_return(mock_document_analyzer)
  end

  describe "#initialize" do
    it "normalizes string provider to symbol" do
      instance = described_class.new(provider: "openai")
      expect(instance.provider).to eq(:openai)
    end

    it "keeps symbol provider as is" do
      instance = described_class.new(provider: :openai)
      expect(instance.provider).to eq(:openai)
    end
  end

  describe "#extract" do
    let(:expected_result) { { "name" => "John Doe", "document_type" => "ID" } }

    before do
      allow(mock_document_analyzer).to receive(:extract)
        .with(prompt: prompt, file_path: file_path)
        .and_return(expected_result)
    end

    it "delegates to document analyzer with correct parameters" do
      result = service.extract(prompt, file_path)

      expect(result).to eq(expected_result)
      expect(mock_document_analyzer).to have_received(:extract)
        .with(prompt: prompt, file_path: file_path)
    end

    include_examples "parameter validation", :extract
  end

  describe "#check?" do
    before do
      allow(mock_document_analyzer).to receive(:check?)
        .with(prompt: prompt, file_path: file_path)
        .and_return(true)
    end

    it "delegates to document analyzer with correct parameters" do
      result = service.check?(prompt, file_path)

      expect(result).to be true
      expect(mock_document_analyzer).to have_received(:check?)
        .with(prompt: prompt, file_path: file_path)
    end

    include_examples "parameter validation", :check?
  end

  describe "document resolver integration" do
    let(:resolver) { class_double(AI::Resolvers::DocumentAnalyzerResolver) }

    before do
      stub_const("AI::Resolvers::DocumentAnalyzerResolver", resolver)
      allow(resolver).to receive(:resolve).with(provider).and_return(mock_document_analyzer)
      allow(mock_document_analyzer).to receive(:extract).and_return({})
      allow(mock_document_analyzer).to receive(:check?).and_return(true)
    end

    it "resolves document analyzer only once and caches it" do
      service.extract(prompt, file_path)
      service.check?(prompt, file_path)

      expect(resolver).to have_received(:resolve).once
    end
  end

  describe "error propagation" do
    context "when document analyzer raises an error" do
      before do
        allow(mock_document_analyzer).to receive(:extract)
          .and_raise(StandardError, "API Error")
      end

      it "propagates the error" do
        expect { service.extract(prompt, file_path) }
          .to raise_error(StandardError, "API Error")
      end
    end
  end
end
