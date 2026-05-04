class Widget < ApplicationRecord
  include Herald::Agentable

  agent_description "A warehouse widget"
  agent_actions only: [:index, :show, :create, :update]
  agent_action_description :show, "Find a widget by ID"
  agent_action_description :create, "Create a new widget"
end
