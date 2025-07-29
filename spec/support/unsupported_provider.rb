shared_examples "unsupported provider" do |value|
  let(:provider) { value }

  it "raises UnsupportedProvider" do
    expect { resolve }.to raise_error(AI::Providers::UnsupportedProvider)
  end
end
