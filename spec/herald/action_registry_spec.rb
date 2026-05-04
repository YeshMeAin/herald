require "spec_helper"

RSpec.describe Herald::ActionRegistry do
  subject(:registry) { described_class.new }

  before do
    Herald::Agentable.registered_classes << Widget
    Widget.agent_actions(only: [:index, :show, :create, :update])
    Widget.agent_action_description(:show, "Find a widget by ID")
    Widget.agent_action_description(:create, "Create a new widget")
  end

  describe "#build!" do
    it "registers actions from agentable classes" do
      registry.build!
      expect(registry.keys).to contain_exactly(
        "widget.index", "widget.show", "widget.create", "widget.update"
      )
    end

    it "creates ActionDescriptor for each action" do
      registry.build!
      descriptor = registry.lookup("widget.show")
      expect(descriptor).to be_a(Herald::ActionDescriptor)
      expect(descriptor.class_name).to eq("Widget")
      expect(descriptor.action_name).to eq(:show)
      expect(descriptor.description).to eq("Find a widget by ID")
    end

    it "freezes the registry after building" do
      registry.build!
      expect { registry.actions["new.key"] = "value" }.to raise_error(FrozenError)
    end

    it "rebuilds cleanly on subsequent calls" do
      registry.build!
      Widget.agent_actions(only: [:show])
      Herald::Agentable.registered_classes << Widget
      registry.build!
      expect(registry.keys).to eq(["widget.show"])
    end

    it "skips classes with no allowed actions" do
      empty_class = Class.new do
        include Herald::Agentable
        def self.name; "EmptyService"; end
      end
      Herald::Agentable.registered_classes << empty_class
      registry.build!
      expect(registry.keys).not_to include("empty_service.anything")
    end

    it "deduplicates registered classes" do
      Herald::Agentable.registered_classes << Widget
      Herald::Agentable.registered_classes << Widget
      registry.build!
      expect(registry.keys.count { |k| k.start_with?("widget.") }).to eq(4)
    end
  end

  describe "#lookup" do
    it "returns nil for unknown keys" do
      registry.build!
      expect(registry.lookup("unknown.action")).to be_nil
    end

    it "returns the descriptor for known keys" do
      registry.build!
      expect(registry.lookup("widget.index")).to be_a(Herald::ActionDescriptor)
    end
  end

  describe "#to_a" do
    it "returns all descriptors as an array" do
      registry.build!
      expect(registry.to_a).to all(be_a(Herald::ActionDescriptor))
      expect(registry.to_a.size).to eq(4)
    end
  end
end
