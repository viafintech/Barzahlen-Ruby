require "spec_helper"

module BarzahlenV2
  describe Configuration do
    describe "#sandbox" do
      it "has valid default values" do
        config = Configuration.new
        config.sandbox = false
        config.division_id = ""
      end
    end

    describe "setting values" do
      it "can set specific values" do
        config = Configuration.new
        config.sandbox = true
        config.division_id = "12345"
        config.payment_key = "12345"

        expect(config.sandbox).to be(true)
        expect(config.division_id).to eq("12345")
        expect(config.payment_key).to eq("12345")
      end
    end
  end
end
