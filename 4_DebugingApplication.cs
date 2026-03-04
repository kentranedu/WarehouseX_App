void ProcessOrder(Order order)
{
	try
	{
		if (order is null)
		{
			throw new ArgumentNullException(nameof(order), "Order cannot be null.");
		}

		if (order.Quantity <= 0)
		{
			throw new ArgumentException("Order quantity must be greater than zero.", nameof(order));
		}

		if (db?.Products is null)
		{
			throw new InvalidOperationException("Product data source is not available.");
		}

		var product = db.Products.Find(order.ProductId);
		if (product is null)
		{
			throw new InvalidOperationException($"Product with ID {order.ProductId} was not found.");
		}

		if (product.Stock < order.Quantity)
		{
			throw new InvalidOperationException(
				$"Insufficient stock for product {product.Id}. Available: {product.Stock}, requested: {order.Quantity}.");
		}

		product.Stock -= order.Quantity;
		Console.WriteLine($"Order {order.Id} processed.");
	}
	catch (Exception ex)
	{
		Console.WriteLine($"Failed to process order: {ex.Message}");
		throw;
	}
}