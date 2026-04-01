namespace SwiftShopper.Domain.Entities;

public class SignupOtpVerification
{
    public required string Id { get; init; }

    public required string UserId { get; init; }

    public required string CodeHash { get; init; }

    public required DateTimeOffset ExpiresAt { get; init; }

    public DateTimeOffset? ConsumedAt { get; set; }

    public int FailedAttempts { get; set; }

    public DateTimeOffset CreatedAt { get; init; }
}
