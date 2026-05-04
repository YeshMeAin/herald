class Order < ApplicationRecord
  include Herald::Agentable

  agent_description "Customer orders"
  agent_actions only: [:index, :show, :create]

  agent_action_description :index, "List all orders, optionally filter by status or customer_name"
  agent_action_description :show, "Look up a single order by its ID"
  agent_action_description :create, "Create a new order with customer_name, product_id, quantity, and status"
end
