require "erb"

module AI
  module Prompts
    class Template
      PROMPTS_PATH = Rails.root.join("app/services/ai/prompts")

      def self.load(name, args = {})
        if args[:expected_values].is_a?(Array)
          args[:expected_values_formatted] = args[:expected_values].map { |v| "- #{v}" }.join("\n")
        end

        template = File.read(PROMPTS_PATH.join("#{name}.erb"))
        ERB.new(template).result_with_hash(args)
      end
    end
  end
end
