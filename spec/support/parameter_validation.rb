shared_examples "parameter validation" do |method_name|
  context "when prompt is blank or nil" do
    it "raises error for blank prompt" do
      expect { service.public_send(method_name, "", file_path) }
        .to raise_error(ArgumentError, "prompt is required and cannot be blank")
    end

    it "raises error for nil prompt" do
      expect { service.public_send(method_name, nil, file_path) }
        .to raise_error(ArgumentError, "prompt is required and cannot be blank")
    end
  end

  context "when file_path is blank or nil" do
    it "raises error for blank file_path" do
      expect { service.public_send(method_name, prompt, "") }
        .to raise_error(ArgumentError, "file_path is required and cannot be blank")
    end

    it "raises error for nil file_path" do
      expect { service.public_send(method_name, prompt, nil) }
        .to raise_error(ArgumentError, "file_path is required and cannot be blank")
    end
  end
end
