puts "Seeding demo data..."

products = [
  { name: "Wireless Mouse", category: "Electronics", price: 29.99, stock: 150 },
  { name: "Mechanical Keyboard", category: "Electronics", price: 89.99, stock: 75 },
  { name: "USB-C Hub", category: "Electronics", price: 45.00, stock: 200 },
  { name: "Standing Desk", category: "Furniture", price: 399.99, stock: 30 },
  { name: "Monitor Arm", category: "Furniture", price: 79.99, stock: 60 },
  { name: "Notebook (A5)", category: "Stationery", price: 12.99, stock: 500 },
  { name: "Fountain Pen", category: "Stationery", price: 34.99, stock: 100 }
]

products.each { |attrs| Product.create!(attrs) }

orders = [
  { customer_name: "Alice", product_id: 1, quantity: 2, total: 59.98, status: "shipped" },
  { customer_name: "Bob", product_id: 2, quantity: 1, total: 89.99, status: "delivered" },
  { customer_name: "Alice", product_id: 4, quantity: 1, total: 399.99, status: "pending" },
  { customer_name: "Charlie", product_id: 3, quantity: 3, total: 135.00, status: "shipped" },
  { customer_name: "Diana", product_id: 6, quantity: 10, total: 129.90, status: "delivered" },
  { customer_name: "Bob", product_id: 1, quantity: 1, total: 29.99, status: "pending" }
]

orders.each { |attrs| Order.create!(attrs) }

puts "Seeded #{Product.count} products and #{Order.count} orders."
