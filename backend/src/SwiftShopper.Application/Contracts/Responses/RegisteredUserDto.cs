using SwiftShopper.Domain.Enums;

namespace SwiftShopper.Application.Contracts.Responses;

public class RegisteredUserDto
{
    public required string UserId { get; init; }

    public required string FullName { get; init; }

    public required string Email { get; init; }

    public required string PhoneNumber { get; init; }

    public required UserRole Role { get; init; }

    public DateTimeOffset CreatedAt { get; init; }
}
