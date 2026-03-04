foreach (var order in orders)
{
    var product = db.Products.FirstOrDefault(p => p.Id == order.ProductId);
    Console.WriteLine($"Order {order.Id}: {product.Name} - {order.Quantity}");
}