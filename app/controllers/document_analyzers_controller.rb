class DocumentAnalyzersController < ApplicationController
  
  before_action :load_document_params

   def extract
    prompt = AI::Prompts::Template.load("extract_identity_prompt", {
      expected_type: @expected_type,
      expected_values: @expected_values
    })

    result = AI::Service.new(provider: :openai).extract(prompt, @image_path)

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
    prompt = AI::Prompts::Template.load("check_identity_prompt", {
      expected_type: @expected_type,
      expected_values: @expected_values
    })

    result = AI::Service.new(provider: :openai).check?(prompt, @image_path)

    render json: result
  end

  private

  def load_document_params
    @image_path = ""
    @expected_type = ""
    @expected_values = [""]
  end
end
