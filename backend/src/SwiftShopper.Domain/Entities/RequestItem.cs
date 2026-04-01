namespace SwiftShopper.Domain.Entities;

public class RequestItem
{
    public required string Name { get; init; }

    public string Unit { get; init; } = string.Empty;

    public string Description { get; init; } = string.Empty;

    public decimal Price { get; init; }

    public int Quantity { get; init; }

    public decimal? MaxPrice { get; init; }
}
