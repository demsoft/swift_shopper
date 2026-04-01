namespace SwiftShopper.Application.Contracts.Responses;

public class PaymentSummaryDto
{
    public required string OrderId { get; init; }

    public decimal ItemsSubtotal { get; init; }

    public decimal DeliveryFee { get; init; }

    public decimal ServiceFee { get; init; }

    public decimal TotalAmount { get; init; }

    public decimal DepositAmount { get; init; }

    public decimal RemainingAmount { get; init; }
}
