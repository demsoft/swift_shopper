using SwiftShopper.Domain.Enums;

namespace SwiftShopper.Domain.Entities;

public class ShoppingRequest
{
    public required string Id { get; init; }

    public required string CustomerId { get; init; }

    public required string PreferredStore { get; init; }

    /// <summary>Supermarket or open market — replaces the old IsFixedStore bool.</summary>
    public MarketType MarketType { get; init; }

    public decimal Budget { get; init; }

    public required string DeliveryAddress { get; init; }

    public string DeliveryNotes { get; init; } = string.Empty;

    public required IReadOnlyList<RequestItem> Items { get; init; }

    public DateTimeOffset CreatedAt { get; init; }
}
