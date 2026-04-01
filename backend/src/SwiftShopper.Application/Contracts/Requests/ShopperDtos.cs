using SwiftShopper.Domain.Enums;

namespace SwiftShopper.Application.Contracts.Requests;

public class AcceptRequestDto
{
    public string ShopperId { get; init; } = string.Empty;

    public required string StoreName { get; init; }

    public string StoreAddress { get; init; } = string.Empty;
}

public class UpdateOrderItemDto
{
    public OrderItemStatus Status { get; init; }

    public decimal? FoundPrice { get; init; }

    public string? PhotoUrl { get; init; }
}

public class SendPriceCardDto
{
    public required string ItemName { get; init; }

    public string Quantity { get; init; } = string.Empty;

    public decimal OldPrice { get; init; }

    public decimal NewPrice { get; init; }
}
