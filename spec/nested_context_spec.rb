require "helper"

describe Thor::NestedContext do
  subject(:context) { described_class.new }

  describe "#enter" do
    it "is never empty within the entered block" do
      context.enter do
        context.enter {}

        expect(context).to be_entered
      end
    end

    it "is empty when outside of all blocks" do
      context.enter { context.enter {} }
      expect(context).not_to be_entered
    end
  end
end
