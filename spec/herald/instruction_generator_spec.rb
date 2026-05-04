require "spec_helper"

RSpec.describe Herald::InstructionGenerator do
  let(:registry) { Herald::ActionRegistry.new }
  subject(:generator) { described_class.new(registry: registry) }

  before do
    Herald::Agentable.registered_classes << Widget
    Widget.agent_actions(only: [:index, :show, :create])
    Widget.agent_description("A warehouse widget")
    Widget.agent_action_description(:show, "Find a widget by ID")
    registry.build!
  end

  describe "#generate" do
    let(:output) { generator.generate }

    it "includes the header" do
      expect(output).to include("# Herald Agent Instructions")
      expect(output).to include("Respond with a JSON object")
    end

    it "includes class name as section header" do
      expect(output).to include("## Widget")
    end

    it "includes class description" do
      expect(output).to include("A warehouse widget")
    end

    it "includes action keys" do
      expect(output).to include("### `widget.index`")
      expect(output).to include("### `widget.show`")
      expect(output).to include("### `widget.create`")
    end

    it "includes action descriptions" do
      expect(output).to include("Find a widget by ID")
    end

    it "includes parameter details" do
      expect(output).to include("`id` (integer, required)")
      expect(output).to include("`name` (string, required)")
    end

    it "marks optional params" do
      expect(output).to include("`quantity` (integer, optional)")
    end

    it "includes the footer" do
      expect(output).to include("Only use the actions listed above")
    end

    it "shows 'No parameters.' for parameterless actions" do
      service_class = Class.new do
        include Herald::Agentable
        def self.name; "PingService"; end
        agent_actions only: [:ping]
        def ping; "pong"; end
      end
      stub_const("PingService", service_class)
      Herald::Agentable.registered_classes << service_class
      registry.build!

      expect(generator.generate).to include("No parameters.")
    end

    it "omits class description when not set" do
      Widget.agent_description(nil)
      registry.build!
      lines = output.split("\n")
      widget_idx = lines.index("## Widget")
      expect(lines[widget_idx + 1]).to eq("")
    end
  end

  describe "#write!" do
    it "writes to the configured path" do
      path = Rails.root.join("tmp", "test_instructions.md")
      Herald.configure { |c| c.instructions_path = path.to_s }

      result = generator.write!

      expect(result).to eq(path.to_s)
      expect(File.exist?(path)).to be true
      expect(File.read(path)).to include("Herald Agent Instructions")

      File.delete(path)
    end
  end
end
