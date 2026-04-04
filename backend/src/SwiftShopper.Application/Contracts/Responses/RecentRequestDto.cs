namespace SwiftShopper.Application.Contracts.Responses;

public class RecentRequestDto
{
    public string Id { get; init; } = string.Empty;
    public string PreferredStore { get; init; } = string.Empty;
    public string DeliveryAddress { get; init; } = string.Empty;
    public decimal Budget { get; init; }
    public int ItemsCount { get; init; }
    public DateTimeOffset CreatedAt { get; init; }
    // Populated if a shopper has accepted this request
    public string? OrderId { get; init; }
    public int? OrderStatus { get; init; }
    public decimal? ItemsSubtotal { get; init; }
    public decimal? DeliveryFee { get; init; }
    public decimal? ServiceFee { get; init; }
    public string? StorePhotoUrl { get; init; }
}
