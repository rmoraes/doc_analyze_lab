require "erb"

module AI
  module Prompts
    class Base
      PROMPTS_PATH = Rails.root.join("app/services/ai/prompts")

      def self.load(name, locals = {})
        if locals[:expected_values].is_a?(Array)
          locals[:expected_values_formatted] = locals[:expected_values].map { |v| "- #{v}" }.join("\n")
        end

        template = File.read(PROMPTS_PATH.join("#{name}.erb"))
        ERB.new(template).result_with_hash(locals)
      end
    end
  end
end
