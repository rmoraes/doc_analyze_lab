require "rails_helper"

RSpec.describe "AI Service Integration", type: :service do
  let(:prompt) { "Extract identity information from this document" }
  let(:file_path) { Rails.root.join("spec/fixtures/test_document.jpg") }

  before { create_test_image_file(file_path) }
  after  { cleanup_test_files(file_path) }

  describe "complete flow with OpenAI provider" do
    let(:service) { AI::Service.new(provider: :openai) }

    let(:mock_api_response) do
      {
        "choices" => [
          {
            "message" => {
              "content" => '{"name": "John Doe", "document_type": "ID", "approved": true}'
            }
          }
        ]
      }
    end

    let(:mock_api_client) { instance_double(AI::Providers::OpenAI::ApiClient) }

    before do
      allow(AI::Providers::OpenAI::ApiClient).to receive(:new).and_return(mock_api_client)
      allow(mock_api_client).to receive(:prepare_payload).and_return("payload")
      allow(mock_api_client).to receive(:post).and_return(mock_api_response)
    end

    describe "#extract" do
      subject(:result) { service.extract(prompt, file_path) }

      it "returns parsed document data" do
        expect(result).to include(
          "name" => "John Doe",
          "document_type" => "ID",
          "approved" => true
        )
      end
    end

    describe "#check?" do
      subject(:result) { service.check?(prompt, file_path) }

      before do
        allow_any_instance_of(AI::Providers::OpenAI::DocumentAnalyzer)
          .to receive(:check?).and_return(true)
      end

      it { is_expected.to be true }
    end
  end

  describe "error handling" do
    context "when API client raises an exception" do
      let(:service) { AI::Service.new(provider: :openai) }
      let(:mock_api_client) { instance_double(AI::Providers::OpenAI::ApiClient) }

      before do
        allow(AI::Providers::OpenAI::ApiClient).to receive(:new).and_return(mock_api_client)
        allow(mock_api_client).to receive(:prepare_payload).and_raise(StandardError, "API Unavailable")
      end

      it "propagates the exception from the client" do
        expect { service.extract(prompt, file_path) }
          .to raise_error(StandardError, "API Unavailable")
      end
    end

    context "when parameters are invalid" do
      let(:service) { AI::Service.new(provider: :openai) }

      it "raises error if prompt is blank" do
        expect { service.extract("", file_path) }
          .to raise_error(ArgumentError, "prompt is required and cannot be blank")
      end

      it "raises error if file_path is blank" do
        expect { service.extract(prompt, "") }
          .to raise_error(ArgumentError, "file_path is required and cannot be blank")
      end
    end
  end

  describe "provider resolution" do
    context "with supported provider" do
      let(:service) { AI::Service.new(provider: :openai) }

      it "assigns the provider correctly" do
        expect(service.instance_variable_get(:@provider)).to eq(:openai)
      end
    end

    context "with unsupported provider" do
      it "raises UnsupportedProvider error" do
        service = AI::Service.new(provider: :unsupported)

        expect { service.extract("test", "test.jpg") }
          .to raise_error(AI::Providers::UnsupportedProvider)
      end
    end
  end
end
