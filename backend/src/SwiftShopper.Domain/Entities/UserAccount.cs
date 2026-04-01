using SwiftShopper.Domain.Enums;

namespace SwiftShopper.Domain.Entities;

public class UserAccount
{
    public required string Id { get; init; }

    public required string FullName { get; init; }

    public required string Email { get; init; }

    public required string PhoneNumber { get; init; }

    public required string PasswordHash { get; init; }

    public required string PasswordSalt { get; init; }

    public UserRole Role { get; init; }

    public bool IsActive { get; set; }

    public string? AvatarUrl { get; set; }

    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    public DateTimeOffset CreatedAt { get; init; }
}
