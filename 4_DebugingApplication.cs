public void ProcessOrder(Order order)
{
    var product = db.Products.Find(order.ProductId);
    product.Stock -= order.Quantity;
    Console.WriteLine($"Order {order.Id} processed.");
}