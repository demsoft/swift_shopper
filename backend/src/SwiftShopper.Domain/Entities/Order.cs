using SwiftShopper.Domain.Enums;

namespace SwiftShopper.Domain.Entities;

public class Order
{
    public required string Id { get; init; }

    public required string RequestId { get; init; }

    // Nullable until a shopper accepts the request
    public string? ShopperId { get; set; }

    public string ShopperName { get; set; } = "Pending Assignment";

    public string StoreName { get; set; } = string.Empty;

    public string StoreAddress { get; set; } = string.Empty;

    public OrderStatus Status { get; set; }

    public decimal ItemsSubtotal { get; set; }

    public decimal DeliveryFee { get; set; }

    public decimal ServiceFee { get; set; }

    public decimal TotalAmount => ItemsSubtotal + DeliveryFee + ServiceFee;

    public int EstimatedDeliveryMinutes { get; set; }

    public int PickedItemsCount { get; set; }

    public DateTimeOffset UpdatedAt { get; set; }
}
