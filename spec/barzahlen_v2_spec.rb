require "spec_helper"

describe BarzahlenV2 do
  describe "#configure" do
    before do
      BarzahlenV2.configure do |config|
      end
    end

    it "returns the correct configuration values" do
      expect(BarzahlenV2.configuration.sandbox).to be(false)
      expect(BarzahlenV2.configuration.division_id).to eq("not_valid_division_id")
      expect(BarzahlenV2.configuration.payment_key).to eq("not_valid_payment_key")
    end

    it "returns the correct modified values" do
      BarzahlenV2.configure do |config|
        config.sandbox = true
        config.division_id = "123456789"
        config.payment_key = "12345678910"
      end

      expect(BarzahlenV2.configuration.sandbox).to be(true)
      expect(BarzahlenV2.configuration.division_id).to eq("123456789")
      expect(BarzahlenV2.configuration.payment_key).to eq("12345678910")
    end

    it "resets the values" do
      BarzahlenV2.reset

      config = BarzahlenV2.configuration

      expect(config.sandbox).to be(false)
      expect(BarzahlenV2.configuration.division_id).to eq("not_valid_division_id")
      expect(BarzahlenV2.configuration.payment_key).to eq("not_valid_payment_key")
    end
  end
end
