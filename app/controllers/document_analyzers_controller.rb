class DocumentAnalyzersController < ApplicationController
  
  before_action :load_document_params

   def extract
    prompt = AI::Prompts::Base.load("check_extract_identity", {
      expected_type: @expected_type,
      expected_values: @expected_values
    })

    result = DocumentAnalyzerService.new(:openai).extract(@image_path, prompt)

    render json: {
      approved: result['approved'],
      document: {
        expected: {
          type: @expected_type,
          values: @expected_values
        },
        got: {
          type: result['document_type'],
          matched: result['matches']
        }
      }
    }
  end


  def check
    prompt = AI::Prompts::Base.load("check_identity", {
      expected_type: @expected_type,
      expected_values: @expected_values
    })

    result = DocumentAnalyzerService.new(:openai).check?(@image_path, prompt)

    render json: result
  end

  private

  def load_document_params
    @image_path = "..."
    @expected_type = "..."
    @expected_values = [
      "name...",
      "cpf...",
      "rg...."
    ]
  end
end
