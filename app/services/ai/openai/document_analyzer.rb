
module AI
  module OpenAI
    class DocumentAnalyzer
      API_URL = "https://api.openai.com/v1/chat/completions"
      MODEL = "gpt-4o"

      def initialize
        @httpClient = HttpClient.new
      end

      def extract(file_path, prompt)
        payload  = @httpClient.prepare_payload(file_path, prompt, MODEL)

        response = @httpClient.post(API_URL, payload)
        parse_response(response)
      end


      def check?(file_path, prompt)
        payload  = @httpClient.prepare_payload(file_path, prompt, MODEL)

        response = @httpClient.post(API_URL, payload)
        parse_response_check(response)
      end

      private

      def parse_response_check(response)
        raw = response.dig("choices", 0, "message", "content").to_s.strip.downcase

        case raw
        when "true"
          true
        when "false"
          false
        else
          Rails.logger.warn("[OpenAI] Unexpected response: #{raw.inspect}")
          false
        end
      rescue => e
        Rails.logger.error("[OpenAI] Error while parsing response: #{e.class} - #{e.message}")
        false
      end
      
     def parse_response(response)
        raw = response.dig("choices", 0, "message", "content").to_s.strip

        cleaned = raw.gsub(/\A```(?:json)?|```\z/, "").strip

        JSON.parse(cleaned)
      rescue JSON::ParserError => e
        Rails.logger.warn("[OpenAI] Unable to parse JSON response: #{e.message}")
        { "approved" => false, "raw_response" => raw.presence || response }
      rescue => e
        Rails.logger.error("[OpenAI] Unexpected error: #{e.class} - #{e.message}")
        { "approved" => false, "raw_response" => response }
      end
    end
  end
end
