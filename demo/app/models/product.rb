class Product < ApplicationRecord
  include Herald::Agentable

  agent_description "Products in the store catalog"
  agent_actions only: [:index, :show, :create, :update]

  agent_action_description :index, "List all products, optionally filter by name or category"
  agent_action_description :show, "Look up a single product by its ID"
  agent_action_description :create, "Add a new product to the catalog"
  agent_action_description :update, "Update a product's name, price, or category"
end
