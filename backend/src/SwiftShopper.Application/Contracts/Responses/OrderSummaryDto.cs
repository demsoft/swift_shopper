namespace SwiftShopper.Application.Contracts.Responses;

/// <summary>Full completed-order summary returned for the Order Summary screen.</summary>
public class OrderSummaryDto
{
    public required string OrderId { get; init; }

    public required string StoreName { get; init; }

    public required string StoreAddress { get; init; }

    public required string ShopperName { get; init; }

    public decimal ShopperRating { get; init; }

    public required string DeliveryAddress { get; init; }

    public DateTimeOffset DeliveredAt { get; init; }

    public required IReadOnlyList<OrderSummaryItemDto> Items { get; init; }

    public decimal ItemsSubtotal { get; init; }

    public decimal DeliveryFee { get; init; }

    public decimal ServiceFee { get; init; }

    public decimal TotalPaid { get; init; }
}

public class OrderSummaryItemDto
{
    public required string Name { get; init; }

    public string Unit { get; init; } = string.Empty;

    public int Quantity { get; init; }

    public decimal Price { get; init; }

    public string? PhotoUrl { get; init; }
}
