using SwiftShopper.Domain.Enums;

namespace SwiftShopper.Application.Contracts.Requests;

public class SendChatMessageDto
{
    public required string Sender { get; init; }

    public required string Type { get; init; }

    public string? Text { get; init; }

    public string? ImageUrl { get; init; }
}

public class ResolvePriceCardDto
{
    public PriceDecision Decision { get; init; }

    public string? Note { get; init; }
}
