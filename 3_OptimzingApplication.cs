var productIds = orders
	.Select(order => order.ProductId)
	.Distinct()
	.ToList();

var productLookup = db.Products
	.Where(product => productIds.Contains(product.Id))
	.Select(product => new { product.Id, product.Name })
	.ToDictionary(product => product.Id, product => product.Name);

var outputBuilder = new System.Text.StringBuilder();

foreach (var order in orders)
{
	productLookup.TryGetValue(order.ProductId, out var productName);
	outputBuilder.AppendLine($"Order {order.Id}: {productName ?? "Unknown Product"} - {order.Quantity}");
}

Console.Write(outputBuilder.ToString());