module AI
  module Providers
    module OpenAI
      class DocumentAnalyzer
        API_URL = "https://api.openai.com/v1/chat/completions"
        MODEL   = "gpt-4o"

        def extract(prompt:, file_path:)
          response = post_to_openai(prompt:, file_path:)
          parse_data_response(response)
        end

        def check?(prompt:, file_path:)
          response = post_to_openai(prompt:, file_path:)
          parse_boolean_response(response)
        end

        private

        def post_to_openai(prompt:, file_path:)
          api = ApiClient.new

          payload = api.prepare_payload(
            model: MODEL,
            prompt:,
            file_path:
          )

          api.post(API_URL, payload)
        end

        def parse_boolean_response(response)
          raw = response.dig("choices", 0, "message", "content").to_s.strip.downcase

          return true  if raw == "true"
          return false if raw == "false"

          Rails.logger.warn("[OpenAI::DocumentAnalyzer] Unexpected boolean content: #{raw.inspect}")
          false
        rescue => e
          Rails.logger.error("[OpenAI::DocumentAnalyzer] Error parsing boolean response: #{e.class} - #{e.message}")
          false
        end

        def parse_data_response(response)
          raw = response.dig("choices", 0, "message", "content").to_s.strip
          cleaned = raw.gsub(/\A```(?:json)?|```\z/, "").strip

          JSON.parse(cleaned)
        rescue JSON::ParserError => e
          Rails.logger.warn("[OpenAI::DocumentAnalyzer] JSON parse error: #{e.message}")
          { "approved" => false, "raw_response" => raw.presence || response }
        rescue => e
          Rails.logger.error("[OpenAI::DocumentAnalyzer] Unexpected error: #{e.class} - #{e.message}")
          { "approved" => false, "raw_response" => response }
        end
      end
    end
  end
end
