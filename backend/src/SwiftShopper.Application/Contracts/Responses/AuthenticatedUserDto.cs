using SwiftShopper.Domain.Enums;

namespace SwiftShopper.Application.Contracts.Responses;

public class AuthenticatedUserDto
{
    public required string UserId { get; init; }

    public required string FullName { get; init; }

    public required string Email { get; init; }

    public required string PhoneNumber { get; init; }

    public UserRole Role { get; init; }

    public string? AvatarUrl { get; init; }

    public DateTimeOffset CreatedAt { get; init; }
}
