class StatsService
  include Herald::Agentable

  agent_description "Business statistics and reports"
  agent_actions only: [:summary, :top_products]

  agent_action_description :summary, "Returns a summary of total products, orders, and revenue"
  agent_action_description :top_products, "Returns the top N products by order count"

  def summary
    products = Product.count
    orders = Order.count
    revenue = Order.sum(:total)
    "Products: #{products}, Orders: #{orders}, Revenue: $#{"%.2f" % revenue}"
  end

  def top_products(limit: "5")
    Product
      .joins("INNER JOIN orders ON orders.product_id = products.id")
      .group("products.id", "products.name")
      .order("COUNT(orders.id) DESC")
      .limit(limit.to_i)
      .pluck("products.name", Arel.sql("COUNT(orders.id)"))
      .map { |name, count| "#{name}: #{count} orders" }
      .join(", ")
  end
end
