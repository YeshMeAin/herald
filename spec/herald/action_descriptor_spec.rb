require "spec_helper"

RSpec.describe Herald::ActionDescriptor do
  subject(:descriptor) do
    described_class.new(
      key: "widget.show",
      class_name: "Widget",
      action_name: :show,
      params: [{ name: "id", type: :integer, required: true }],
      description: "Find a widget"
    )
  end

  it "exposes key" do
    expect(descriptor.key).to eq("widget.show")
  end

  it "exposes class_name" do
    expect(descriptor.class_name).to eq("Widget")
  end

  it "exposes action_name" do
    expect(descriptor.action_name).to eq(:show)
  end

  it "exposes params" do
    expect(descriptor.params).to eq([{ name: "id", type: :integer, required: true }])
  end

  it "exposes description" do
    expect(descriptor.description).to eq("Find a widget")
  end

  it "defaults description to nil" do
    d = described_class.new(key: "a.b", class_name: "A", action_name: :b, params: [])
    expect(d.description).to be_nil
  end

  describe "#to_h" do
    it "returns a hash of all attributes" do
      expect(descriptor.to_h).to eq(
        key: "widget.show",
        class_name: "Widget",
        action_name: :show,
        params: [{ name: "id", type: :integer, required: true }],
        description: "Find a widget"
      )
    end
  end
end
