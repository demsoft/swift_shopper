namespace SwiftShopper.Application.Contracts.Responses;

public class RecentRequestDto
{
    public string Id { get; init; } = string.Empty;
    public string PreferredStore { get; init; } = string.Empty;
    public string DeliveryAddress { get; init; } = string.Empty;
    public int ItemsCount { get; init; }
    public DateTimeOffset CreatedAt { get; init; }
    // Populated if a shopper has accepted this request
    public string? OrderId { get; init; }
    public int? OrderStatus { get; init; }
}
