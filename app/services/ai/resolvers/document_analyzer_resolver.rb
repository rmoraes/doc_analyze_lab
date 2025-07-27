module AI
  module Resolvers
    class DocumentAnalyzerResolver
      def self.resolve(provider)
        case provider
        when :openai
          AI::Providers::OpenAI::DocumentAnalyzer.new
        else
          raise AI::Providers::UnsupportedProvider, provider
        end
      end
    end
  end
end
