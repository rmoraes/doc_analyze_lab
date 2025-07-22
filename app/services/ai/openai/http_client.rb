module AI
  module OpenAI
    class HttpClient
      OPENAI_API_KEY = ENV["OPENAI_API_KEY"]

      def post(url, payload)
        response = RestClient.post(url, payload, headers)
        JSON.parse(response.body)
      rescue RestClient::ExceptionWithResponse => e
        { error: "Error OpenAI", status: e.response.code, details: e.response.body }
      end


      def prepare_payload(file_path, prompt, model)
        {
          model: model,
          messages: [
            {
              role: "user",
              content: [
                { type: "image_url", image_url: { url: "data:image/jpeg;base64,#{encode_image(file_path)}" } },
                { type: "text", text: prompt }
              ]
            }
          ],
          max_tokens: 1024
        }.to_json
      end

      private

      def headers
        {
          "Authorization" => "Bearer #{OPENAI_API_KEY}",
          "Content-Type" => "application/json"
        }
      end

      def encode_image(file_path)
        File.open(file_path, "rb") { |f| Base64.strict_encode64(f.read) }
      end
    end
  end
end
