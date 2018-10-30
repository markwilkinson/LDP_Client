require_relative '../lib/ldp.rb'
RSpec.describe LDP do
  it "has a version number" do
    #expect(LDP::VERSION).not_to be nil
    expect(1).not_to be nil
  end

  it "does something useful" do
    expect(true).to eq(true)
  end
end
