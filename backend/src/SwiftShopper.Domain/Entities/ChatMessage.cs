namespace SwiftShopper.Domain.Entities;

public class ChatMessage
{
    public required string Id { get; init; }

    public required string OrderId { get; init; }

    public required string Sender { get; init; }

    public required string Type { get; init; }

    public string? Text { get; init; }

    public string? ImageUrl { get; init; }

    /// <summary>Populated when Type == "price-card".</summary>
    public PriceCardData? PriceCard { get; init; }

    public DateTimeOffset SentAt { get; init; }
}

/// <summary>
/// Structured payload attached to price-card chat messages.
/// Allows the customer to see exactly what the shopper is proposing.
/// </summary>
public class PriceCardData
{
    public required string ItemName { get; init; }

    public string Quantity { get; init; } = string.Empty;

    public decimal OldPrice { get; init; }

    public decimal NewPrice { get; init; }
}
