class DocumentAnalyzerService
  PROVIDERS = {
    openai: AI::OpenAI::DocumentAnalyzer
  }.freeze

  def initialize(provider = :openai)
    @provider = provider.to_sym
  end

  def extract(file_path, prompt)
    provider_instance.extract(file_path, prompt)
  end

  def check?(file_path, prompt)
    provider_instance.check?(file_path, prompt)
  end


  private

  def provider_instance
    provider_class = PROVIDERS.fetch(@provider) do
      raise ArgumentError, "Invalid provider: #{@provider.inspect}"
    end

    provider_class.new
  end
end
