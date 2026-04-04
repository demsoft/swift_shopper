using SwiftShopper.Domain.Enums;

namespace SwiftShopper.Application.Contracts.Responses;

public class ActiveOrderDto
{
    public string Id { get; init; } = string.Empty;
    public string RequestId { get; init; } = string.Empty;
    public string ShopperName { get; set; } = "Pending Assignment";
    public string StoreName { get; set; } = string.Empty;
    public string StoreAddress { get; set; } = string.Empty;
    public OrderStatus Status { get; set; }
    public decimal ItemsSubtotal { get; set; }
    public decimal EstimatedItemsTotal { get; set; }
    public decimal DeliveryFee { get; set; }
    public decimal ServiceFee { get; set; }
    public int PickedItemsCount { get; set; }
    public int TotalItemsCount { get; set; }
    public int EstimatedDeliveryMinutes { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public string? StorePhotoUrl { get; set; }
    public string? ShopperAvatarUrl { get; set; }
}
