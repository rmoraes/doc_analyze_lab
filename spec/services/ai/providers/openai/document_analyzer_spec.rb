require "rails_helper"

RSpec.describe AI::Providers::OpenAI::DocumentAnalyzer do
  subject(:analyzer) { described_class.new }

  let(:prompt) { "Extract identity information from this document" }
  let(:file_path) { Rails.root.join("spec/fixtures/test_document.jpg") }
  let(:payload) { "payload" }
  let(:mock_api_client) { instance_double(AI::Providers::OpenAI::ApiClient) }

  before do
    allow(AI::Providers::OpenAI::ApiClient).to receive(:new).and_return(mock_api_client)
    allow(mock_api_client).to receive(:prepare_payload)
      .with(model: described_class::MODEL, prompt: prompt, file_path: file_path)
      .and_return(payload)
  end

  describe "#extract" do
    subject(:result) { analyzer.extract(prompt: prompt, file_path: file_path) }

    let(:expected_result) { { "name" => "John Doe", "document_type" => "ID" } }

    context "when API returns valid JSON" do
      let(:api_response) do
        {
          "choices" => [
            { "message" => { "content" => '{"name": "John Doe", "document_type": "ID"}' } }
          ]
        }
      end

      before do
        allow(mock_api_client).to receive(:post)
          .with(described_class::API_URL, payload)
          .and_return(api_response)
      end

      it "sends request and parses JSON correctly" do
        expect(result).to eq(expected_result)
        expect(mock_api_client).to have_received(:prepare_payload).with(
          model: described_class::MODEL,
          prompt: prompt,
          file_path: file_path
        )
        expect(mock_api_client).to have_received(:post)
          .with(described_class::API_URL, payload)
      end
    end

    context "when JSON is wrapped in code block" do
      let(:api_response) do
        {
          "choices" => [
            { "message" => { "content" => "```json\n{\"name\": \"John Doe\", \"document_type\": \"ID\"}\n```" } }
          ]
        }
      end

      before { allow(mock_api_client).to receive(:post).and_return(api_response) }

      it "strips wrapper and parses JSON" do
        expect(result).to eq(expected_result)
      end
    end

    context "when response has invalid JSON" do
      let(:api_response) do
        {
          "choices" => [
            { "message" => { "content" => "Invalid JSON content" } }
          ]
        }
      end

      before { allow(mock_api_client).to receive(:post).and_return(api_response) }

      it "returns fallback response with raw content" do
        expect(result).to include("approved" => false, "raw_response" => "Invalid JSON content")
      end
    end

    context "when response content is nil" do
      let(:api_response) do
        {
          "choices" => [
            { "message" => { "content" => nil } }
          ]
        }
      end

      before { allow(mock_api_client).to receive(:post).and_return(api_response) }

      it "returns fallback response with raw response" do
        expect(result).to include("approved" => false, "raw_response" => api_response)
      end
    end

    context "when API client raises an error" do
      before { allow(mock_api_client).to receive(:prepare_payload).and_raise(StandardError, "API Error") }

      it "raises the error" do
        expect {
          analyzer.extract(prompt: prompt, file_path: file_path)
        }.to raise_error(StandardError, "API Error")
      end
    end
  end

  describe "#check?" do
    subject(:result) { analyzer.check?(prompt: prompt, file_path: file_path) }

    # Casos de sucesso com "true"
    context "when response content is 'true'" do
      let(:api_response) { { "choices" => [ { "message" => { "content" => "true" } } ] } }

      before { allow(mock_api_client).to receive(:post).and_return(api_response) }

      it { is_expected.to be true }
    end

    context "when response content is 'TRUE' (case-insensitive)" do
      let(:api_response) { { "choices" => [ { "message" => { "content" => "TRUE" } } ] } }

      before { allow(mock_api_client).to receive(:post).and_return(api_response) }

      it { is_expected.to be true }
    end

    # Casos de resposta negativa
    context "when response content is 'false'" do
      let(:api_response) { { "choices" => [ { "message" => { "content" => "false" } } ] } }

      before { allow(mock_api_client).to receive(:post).and_return(api_response) }

      it { is_expected.to be false }
    end

    context "when response content is 'FALSE'" do
      let(:api_response) { { "choices" => [ { "message" => { "content" => "FALSE" } } ] } }

      before { allow(mock_api_client).to receive(:post).and_return(api_response) }

      it { is_expected.to be false }
    end

    # Conteúdo inesperado
    context "when response content is unexpected" do
      let(:api_response) { { "choices" => [ { "message" => { "content" => "maybe" } } ] } }

      before { allow(mock_api_client).to receive(:post).and_return(api_response) }

      it { is_expected.to be false }
    end

    # Nil ou vazio
    context "when content is nil or empty" do
      [ "", nil ].each do |value|
        context "when content is #{value.inspect}" do
          let(:api_response) { { "choices" => [ { "message" => { "content" => value } } ] } }

          before { allow(mock_api_client).to receive(:post).and_return(api_response) }

          it { is_expected.to be false }
        end
      end
    end

    # Exceção no client
    context "when API client raises an error" do
      before do
        allow(mock_api_client).to receive(:prepare_payload).and_raise(StandardError, "API Error")
      end

      it "raises the error" do
        expect {
          analyzer.check?(prompt: prompt, file_path: file_path)
        }.to raise_error(StandardError, "API Error")
      end
    end
  end


  describe "constants" do
    it "defines the correct API_URL" do
      expect(described_class::API_URL).to eq("https://api.openai.com/v1/chat/completions")
    end

    it "defines the correct MODEL" do
      expect(described_class::MODEL).to eq("gpt-4o")
    end
  end
end
