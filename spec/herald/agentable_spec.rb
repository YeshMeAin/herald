require "spec_helper"

RSpec.describe Herald::Agentable do
  let(:service_class) do
    Class.new do
      include Herald::Agentable
      self.herald_allowed_actions = []
      self.herald_class_description = nil
      self.herald_action_descriptions = {}

      def self.name
        "TestService"
      end

      def greet(name)
        "Hello, #{name}"
      end

      def status
        "ok"
      end

      private

      def secret
        "hidden"
      end
    end
  end

  after do
    Herald::Agentable.registered_classes.delete(service_class)
  end

  describe ".agent_actions" do
    it "sets the allowed actions" do
      service_class.agent_actions(only: [:greet, :status])
      expect(service_class.herald_allowed_actions).to eq([:greet, :status])
    end

    it "converts strings to symbols" do
      service_class.agent_actions(only: ["greet"])
      expect(service_class.herald_allowed_actions).to eq([:greet])
    end

    it "wraps a single action in an array" do
      service_class.agent_actions(only: :greet)
      expect(service_class.herald_allowed_actions).to eq([:greet])
    end
  end

  describe ".agent_description" do
    it "sets the class description" do
      service_class.agent_description("A test service")
      expect(service_class.herald_class_description).to eq("A test service")
    end
  end

  describe ".agent_action_description" do
    it "sets a description for a specific action" do
      service_class.agent_action_description(:greet, "Greets a person")
      expect(service_class.herald_action_descriptions[:greet]).to eq("Greets a person")
    end

    it "merges with existing descriptions" do
      service_class.agent_action_description(:greet, "Greets")
      service_class.agent_action_description(:status, "Returns status")
      expect(service_class.herald_action_descriptions).to eq(greet: "Greets", status: "Returns status")
    end
  end

  describe ".herald_ar_model?" do
    it "returns false for non-AR classes" do
      expect(service_class.herald_ar_model?).to be false
    end

    it "returns true for AR models" do
      expect(Widget.herald_ar_model?).to be true
    end
  end

  describe ".herald_param_schema_for" do
    context "with a service class" do
      it "introspects method parameters" do
        params = service_class.herald_param_schema_for(:greet)
        expect(params).to eq([{ name: "name", type: :string, required: true }])
      end

      it "returns empty for parameterless methods" do
        params = service_class.herald_param_schema_for(:status)
        expect(params).to eq([])
      end

      it "returns empty for undefined methods" do
        params = service_class.herald_param_schema_for(:nonexistent)
        expect(params).to eq([])
      end
    end

    context "with an AR model" do
      it "returns filterable columns for index" do
        params = Widget.herald_param_schema_for(:index)
        names = params.map { |p| p[:name] }
        expect(names).to include("id", "name", "quantity")
        expect(params.all? { |p| p[:required] == false }).to be true
      end

      it "returns id for show" do
        params = Widget.herald_param_schema_for(:show)
        expect(params).to eq([{ name: "id", type: :integer, required: true }])
      end

      it "returns id for destroy" do
        params = Widget.herald_param_schema_for(:destroy)
        expect(params).to eq([{ name: "id", type: :integer, required: true }])
      end

      it "returns writable columns for create" do
        params = Widget.herald_param_schema_for(:create)
        names = params.map { |p| p[:name] }
        expect(names).to include("name", "quantity")
        expect(names).not_to include("id", "created_at", "updated_at")
      end

      it "marks non-null columns without defaults as required for create" do
        params = Widget.herald_param_schema_for(:create)
        name_param = params.find { |p| p[:name] == "name" }
        quantity_param = params.find { |p| p[:name] == "quantity" }
        expect(name_param[:required]).to be true
        expect(quantity_param[:required]).to be false
      end

      it "returns id + writable columns for update" do
        params = Widget.herald_param_schema_for(:update)
        names = params.map { |p| p[:name] }
        expect(names).to include("id", "name", "quantity")
        id_param = params.find { |p| p[:name] == "id" }
        name_param = params.find { |p| p[:name] == "name" }
        expect(id_param[:required]).to be true
        expect(name_param[:required]).to be false
      end

      it "falls through to method_params_for custom actions on AR models" do
        Widget.class_eval do
          def self.name; "Widget"; end
          define_method(:restock) { |quantity| quantity }
        end
        params = Widget.herald_param_schema_for(:restock)
        expect(params).to eq([{ name: "quantity", type: :string, required: true }])
      end
    end
  end

  describe "registration" do
    it "registers the class when included" do
      klass = Class.new do
        include Herald::Agentable
      end
      expect(Herald::Agentable.registered_classes).to include(klass)
    end
  end
end
