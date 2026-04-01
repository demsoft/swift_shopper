using SwiftShopper.Domain.Enums;

namespace SwiftShopper.Application.Contracts.Responses;

/// <summary>Full active job payload returned to the shopper on the Active Job screen.</summary>
public class ActiveJobDto
{
    public required string OrderId { get; init; }

    public required string RequestId { get; init; }

    public required string StoreName { get; init; }

    public required string StoreAddress { get; init; }

    public required string CustomerName { get; init; }

    public required string DeliveryAddress { get; init; }

    public string DeliveryNotes { get; init; } = string.Empty;

    public OrderStatus Status { get; init; }

    public int PickedItemsCount { get; init; }

    public int TotalItemsCount { get; init; }

    public decimal EstimatedTotal { get; init; }

    public required IReadOnlyList<ActiveJobItemDto> Items { get; init; }
}

public class ActiveJobItemDto
{
    public int Id { get; init; }

    public required string Name { get; init; }

    public string Unit { get; init; } = string.Empty;

    public string Description { get; init; } = string.Empty;

    public int Quantity { get; init; }

    public decimal EstimatedPrice { get; init; }

    public decimal? FoundPrice { get; init; }

    public OrderItemStatus Status { get; init; }

    public string? PhotoUrl { get; init; }
}
