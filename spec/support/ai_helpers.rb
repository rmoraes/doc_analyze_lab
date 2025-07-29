# spec/support/ai_helpers.rb

module AIHelpers
  # Cria um arquivo de imagem fictício em um caminho específico
  def create_test_image_file(path, content = "fake image data")
    FileUtils.mkdir_p(File.dirname(path))
    File.binwrite(path, content)
  end

  # Remove os arquivos especificados se existirem
  def cleanup_test_files(*paths)
    paths.each { |path| FileUtils.rm_f(path.to_s) if File.exist?(path.to_s) }
  end

  # Gera uma resposta simulada da OpenAI com conteúdo de mensagem
  def build_openai_success_response(content)
    {
      "choices" => [
        {
          "message" => {
            "content" => content
          }
        }
      ]
    }
  end

  # Gera uma resposta de erro simulada da OpenAI
  def build_openai_error_response(status:, body:)
    {
      "error" => "OpenAI HTTP error",
      "status" => status,
      "details" => body
    }
  end
end

RSpec.configure do |config|
  config.include AIHelpers
end
