module AI
  class Service
    attr_reader :provider

    def initialize(provider:)
      @provider = provider.to_sym
    end

    def extract(prompt, file_path)
      validate_presence_of!(prompt: prompt, file_path: file_path)

      document.extract(prompt:, file_path:)
    end

    def check?(prompt, file_path)
      validate_presence_of!(prompt: prompt, file_path: file_path)

      document.check?(prompt:, file_path:)
    end

    def verify_face(prompt, file_path)
      validate_presence_of!(prompt: prompt, file_path: file_path)

      face.verify(prompt, file_path)
    end

    private

    def document
      @document ||= Resolvers::DocumentAnalyzerResolver.resolve(@provider)
    end

    def face
      @face ||= Resolvers::FaceVerifierResolver.resolve(@provider)
    end

    def validate_presence_of!(**params)
      params.each do |key, value|
        raise ArgumentError, "#{key} is required and cannot be blank" if value.blank?
      end
    end
  end
end
