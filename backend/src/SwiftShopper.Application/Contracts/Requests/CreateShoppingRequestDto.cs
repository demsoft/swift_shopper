using SwiftShopper.Domain.Enums;

namespace SwiftShopper.Application.Contracts.Requests;

public class CreateShoppingRequestDto
{
    public required string CustomerId { get; init; }

    public required string PreferredStore { get; init; }

    public MarketType MarketType { get; init; }

    public decimal Budget { get; init; }

    public required string DeliveryAddress { get; init; }

    public string DeliveryNotes { get; init; } = string.Empty;

    public required List<RequestItemDto> Items { get; init; }
}

public class RequestItemDto
{
    public required string Name { get; init; }

    public string Unit { get; init; } = string.Empty;

    public string Description { get; init; } = string.Empty;

    public decimal Price { get; init; }

    public int Quantity { get; init; }

    public decimal? MaxPrice { get; init; }
}
