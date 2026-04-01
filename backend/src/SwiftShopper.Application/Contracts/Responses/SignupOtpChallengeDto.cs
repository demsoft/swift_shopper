using SwiftShopper.Domain.Enums;

namespace SwiftShopper.Application.Contracts.Responses;

public class SignupOtpChallengeDto
{
    public required string UserId { get; init; }

    public required string Email { get; init; }

    public required string PhoneNumber { get; init; }

    public required UserRole Role { get; init; }

    public required DateTimeOffset ExpiresAt { get; init; }

    public string? DevelopmentOtpCode { get; init; }
}
