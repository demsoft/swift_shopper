using SwiftShopper.Domain.Enums;

namespace SwiftShopper.Domain.Entities;

/// <summary>
/// Represents a single shopping list item within an active order.
/// Created from RequestItem when a shopper accepts the order.
/// The shopper updates Status, FoundPrice and PhotoUrl as they shop.
/// </summary>
public class OrderItem
{
    public int Id { get; init; }

    public required string OrderId { get; init; }

    public required string Name { get; init; }

    public string Unit { get; init; } = string.Empty;

    public string Description { get; init; } = string.Empty;

    public int Quantity { get; init; }

    /// <summary>Customer's estimated price from the request.</summary>
    public decimal EstimatedPrice { get; init; }

    /// <summary>Actual price found by shopper. Null until found.</summary>
    public decimal? FoundPrice { get; set; }

    public OrderItemStatus Status { get; set; } = OrderItemStatus.Pending;

    /// <summary>URL of photo taken by shopper as proof.</summary>
    public string? PhotoUrl { get; set; }

    public DateTimeOffset UpdatedAt { get; set; }
}
