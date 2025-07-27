module AI
  module Providers
    class UnsupportedProvider < StandardError
      def initialize(provider)
        super("Unsupported AI provider: #{provider.inspect}")
      end
    end
  end
end
