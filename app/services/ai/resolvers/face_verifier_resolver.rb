module AI
  module Resolvers
    class FaceVerifierResolver
      def self.resolve(provider)
        case provider
        when :openai
          AI::Providers::OpenAI::FaceVerifier.new
        else
          raise AI::Providers::UnsupportedProvider, provider
        end
      end
    end
  end
end
