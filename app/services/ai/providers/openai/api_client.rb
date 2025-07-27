module AI
  module Providers
    module OpenAI
      class ApiClient
        API_KEY = ENV.fetch("OPENAI_API_KEY") { raise "Missing OPENAI_API_KEY" }

        HEADERS = {
          "Authorization" => "Bearer #{API_KEY}",
          "Content-Type" => "application/json"
        }.freeze

        def post(url, payload)
          response = RestClient.post(url, payload, HEADERS)
          parse_response(response)
        rescue RestClient::ExceptionWithResponse => e
          handle_http_error(e)
        rescue StandardError => e
          { error: "Unexpected OpenAI error", message: e.message }
        end

        def prepare_payload(model:, prompt:, file_path:)
          {
            model:,
            messages: [
              {
                role: "user",
                content: [
                  { type: "image_url", image_url: { url: image_data_url(file_path) } },
                  { type: "text", text: prompt }
                ]
              }
            ],
            max_tokens: 1024
          }.to_json
        end

        private

        def image_data_url(file_path)
          "data:image/jpeg;base64,#{Base64.strict_encode64(File.binread(file_path))}"
        end

        def parse_response(response)
          JSON.parse(response.body)
        rescue JSON::ParserError => e
          { error: "Invalid JSON response from OpenAI", raw: response.body, message: e.message }
        end

        def handle_http_error(error)
          {
            error: "OpenAI HTTP error",
            status: error.response&.code,
            details: error.response&.body
          }
        end
      end
    end
  end
end
