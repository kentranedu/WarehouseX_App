void ProcessOrder(Order order)
{
	if (order is null)
	{
		throw new ArgumentNullException(nameof(order), "Order cannot be null.");
	}

	if (order.Quantity <= 0)
	{
		throw new ArgumentException("Order quantity must be greater than zero.", nameof(order));
	}

	var products = db?.Products ?? throw new InvalidOperationException("Product data source is not available.");
	var product = products.Find(order.ProductId) ?? throw new InvalidOperationException("Product not found.");

	if (product.Stock < order.Quantity)
	{
		throw new InvalidOperationException("Insufficient stock.");
	}

	product.Stock -= order.Quantity;
	Console.WriteLine($"Order {order.Id} processed.");
}