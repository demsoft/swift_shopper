using SwiftShopper.Domain.Enums;

namespace SwiftShopper.Application.Contracts.Responses;

public class OrderTrackingDto
{
    public required string OrderId { get; init; }

    public required string RequestId { get; init; }

    public required string ShopperName { get; init; }

    public string? ShopperAvatarUrl { get; init; }

    public string StoreName { get; init; } = string.Empty;

    public string StoreAddress { get; init; } = string.Empty;

    public OrderStatus CurrentStatus { get; init; }

    public required string StepLabel { get; init; }

    public int StepNumber { get; init; }

    public int TotalSteps { get; init; }

    public int ProgressPercent { get; init; }

    public int PickedItemsCount { get; init; }

    public int TotalItemsCount { get; init; }

    public int EstimatedDeliveryMinutes { get; init; }

    public required IReadOnlyList<OrderStatus> Timeline { get; init; }
}
