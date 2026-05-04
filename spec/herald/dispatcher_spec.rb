require "spec_helper"

RSpec.describe Herald::Dispatcher do
  let(:registry) { Herald::ActionRegistry.new }
  subject(:dispatcher) { described_class.new(registry: registry) }

  before do
    Herald::Agentable.registered_classes << Widget
    Widget.agent_actions(only: [:index, :show, :create, :update, :destroy])
    registry.build!
  end

  describe "#dispatch" do
    it "raises for unknown actions" do
      expect { dispatcher.dispatch("unknown.action", {}) }
        .to raise_error(Herald::Error, /Unknown action/)
    end

    it "raises for missing required params" do
      expect { dispatcher.dispatch("widget.show", {}) }
        .to raise_error(Herald::Error, /Missing required params: id/)
    end

    context "CRUD actions" do
      describe "index" do
        it "returns all records" do
          Widget.create!(name: "Bolt")
          Widget.create!(name: "Nut")
          result = dispatcher.dispatch("widget.index", {})
          expect(result).to include("Bolt")
          expect(result).to include("Nut")
        end

        it "filters by params" do
          Widget.create!(name: "Bolt")
          Widget.create!(name: "Nut")
          result = dispatcher.dispatch("widget.index", { "name" => "Bolt" })
          expect(result).to include("Bolt")
          expect(result).not_to include("Nut")
        end
      end

      describe "show" do
        it "returns the record attributes" do
          widget = Widget.create!(name: "Bolt", quantity: 10)
          result = dispatcher.dispatch("widget.show", { "id" => widget.id })
          expect(result).to include("Bolt")
          expect(result).to include("10")
        end
      end

      describe "create" do
        it "creates a record and returns confirmation" do
          result = dispatcher.dispatch("widget.create", { "name" => "Gear", "quantity" => 5 })
          expect(result).to match(/Created Widget #\d+/)
          expect(Widget.find_by(name: "Gear").quantity).to eq(5)
        end
      end

      describe "update" do
        it "updates a record and returns confirmation" do
          widget = Widget.create!(name: "Bolt", quantity: 10)
          result = dispatcher.dispatch("widget.update", { "id" => widget.id, "quantity" => 20 })
          expect(result).to eq("Updated Widget ##{widget.id}")
          expect(widget.reload.quantity).to eq(20)
        end
      end

      describe "destroy" do
        it "destroys a record and returns confirmation" do
          widget = Widget.create!(name: "Bolt")
          result = dispatcher.dispatch("widget.destroy", { "id" => widget.id })
          expect(result).to eq("Destroyed Widget ##{widget.id}")
          expect(Widget.find_by(id: widget.id)).to be_nil
        end
      end
    end

    context "service methods" do
      let(:service_class) do
        Class.new do
          include Herald::Agentable
          def self.name; "ReportService"; end

          agent_actions only: [:generate, :health]
          agent_action_description :generate, "Generate a report"

          def generate(type:)
            "Report: #{type}"
          end

          def health
            "healthy"
          end
        end
      end

      before do
        stub_const("ReportService", service_class)
        Herald::Agentable.registered_classes << service_class
        registry.build!
      end

      it "calls the method with keyword args" do
        result = dispatcher.dispatch("report_service.generate", { "type" => "monthly" })
        expect(result).to eq("Report: monthly")
      end

      it "calls parameterless methods" do
        result = dispatcher.dispatch("report_service.health", {})
        expect(result).to eq("healthy")
      end
    end
  end
end
