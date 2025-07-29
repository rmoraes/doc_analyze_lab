require "rails_helper"

RSpec.describe AI::Providers::OpenAI::ApiClient do
  subject(:client) { described_class.new }

  let(:url) { "https://api.openai.com/v1/chat/completions" }
  let(:payload) { { model: "gpt-4o", messages: [] }.to_json }
  let(:file_path) { Rails.root.join("spec/fixtures/test_document.jpg") }

  before do
    FileUtils.mkdir_p(file_path.dirname)
    File.write(file_path, "fake image data")
  end

  after { FileUtils.rm_f(file_path) }

  describe "#post" do
    subject(:result) { client.post(url, payload) }

    context "when the response is successful" do
      let(:success_response) { instance_double(RestClient::Response, body: '{"result": "success"}') }

      before { allow(RestClient).to receive(:post).and_return(success_response) }

      it "sends a POST request with the correct headers and payload" do
        result

        expect(RestClient).to have_received(:post).with(
          url,
          payload,
          hash_including("Authorization" => /^Bearer /, "Content-Type" => "application/json")
        )
      end

      it "parses the JSON response correctly" do
        expect(result).to eq("result" => "success")
      end
    end

    context "when an HTTP error occurs" do
      let(:error_response) { instance_double(RestClient::Response, code: 400, body: "Bad Request") }
      let(:http_error)     { RestClient::ExceptionWithResponse.new(error_response) }

      before { allow(RestClient).to receive(:post).and_raise(http_error) }

      it "returns an error hash with status and details" do
        expect(result).to match(
          error: "OpenAI HTTP error",
          status: 400,
          details: "Bad Request"
        )
      end
    end

    context "when the response body is not valid JSON" do
      let(:invalid_response) { instance_double(RestClient::Response, body: "invalid json") }

      before { allow(RestClient).to receive(:post).and_return(invalid_response) }

      it "returns an error hash about JSON parsing" do
        expect(result).to include(
          error: "Invalid JSON response from OpenAI",
          raw: "invalid json"
        )
        expect(result).to have_key(:message)
      end
    end

    context "when an unexpected error occurs" do
      before { allow(RestClient).to receive(:post).and_raise(StandardError, "Network error") }

      it "returns a generic error hash" do
        expect(result).to match(
          error: "Unexpected OpenAI error",
          message: "Network error"
        )
      end
    end
  end

  describe "#prepare_payload" do
    let(:model) { "gpt-4o" }
    let(:prompt) { "Extract identity information from this document" }

    subject(:parsed_payload) do
      result = client.prepare_payload(model: model, prompt: prompt, file_path: file_path)
      JSON.parse(result)
    end

   it "generates the correct payload structure" do
      expect(parsed_payload).to include("model" => model, "max_tokens" => 1024)

      message = parsed_payload["messages"].first
      expect(message["role"]).to eq("user")

      content = message["content"]
      expect(content).to be_an(Array)
      expect(content.size).to eq(2)

      image_content = content.find { |item| item["type"] == "image_url" }
      expect(image_content["image_url"]["url"]).to start_with("data:image/jpeg;base64,")

      text_content = content.find { |item| item["type"] == "text" }
      expect(text_content).to eq({ "type" => "text", "text" => prompt })
    end

    it "encodes the image in base64 correctly" do
      image_url = parsed_payload["messages"].first["content"]
                  .find { |item| item["type"] == "image_url" }
                  .dig("image_url", "url")

      base64_data = image_url.sub("data:image/jpeg;base64,", "")
      decoded = Base64.strict_decode64(base64_data)

      expect(decoded).to eq("fake image data")
    end

    context "when using a PNG file" do
      let(:png_file_path) { Rails.root.join("spec/fixtures/test_document.png") }

      before { File.write(png_file_path, "fake png data") }
      after { FileUtils.rm_f(png_file_path) }

      it "still returns a base64-encoded jpeg image url" do
        result = client.prepare_payload(model: model, prompt: prompt, file_path: png_file_path)
        parsed = JSON.parse(result)
        image_url = parsed["messages"].first["content"]
                    .find { |item| item["type"] == "image_url" }
                    .dig("image_url", "url")

        expect(image_url).to start_with("data:image/jpeg;base64,")
      end
    end
  end

  describe "headers" do
    it "contains authorization and content-type keys" do
      headers = client.send(:headers)

      expect(headers["Authorization"]).to start_with("Bearer ")
      expect(headers["Content-Type"]).to eq("application/json")
    end
  end

  describe "API key validation" do
    it "raises if API key is nil" do
      expect {
        described_class.new(api_key: nil)
      }.to raise_error("Missing OPENAI_API_KEY")
    end

    it "raises if API key is blank" do
      expect {
        described_class.new(api_key: "")
      }.to raise_error("Missing OPENAI_API_KEY")

      expect {
        described_class.new(api_key: "   ")
      }.to raise_error("Missing OPENAI_API_KEY")
    end
  end
end
