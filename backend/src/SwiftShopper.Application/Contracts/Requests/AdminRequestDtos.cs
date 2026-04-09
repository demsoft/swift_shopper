using SwiftShopper.Domain.Enums;

namespace SwiftShopper.Application.Contracts.Requests;

public record UpdateOrderStatusDto(OrderStatus Status);
public record AssignOrderShopperDto(string ShopperId);

public record UpdateUserStatusDto(bool IsActive);

public record CreateMarketDto
{
    public string Name { get; init; } = string.Empty;

    /// <summary>Supermarket | OpenMarket | Specialty | Mall</summary>
    public string Type { get; init; } = string.Empty;

    public string Address { get; init; } = string.Empty;
    public string Location { get; init; } = string.Empty;
    public string Zone { get; init; } = string.Empty;
    public bool IsActive { get; init; } = true;
    public List<string> Categories { get; init; } = [];
    public string OpeningTime { get; init; } = "08:00";
    public string ClosingTime { get; init; } = "20:00";
    public double GeofenceRadiusKm { get; init; } = 5.0;
    public string? PhotoUrl { get; init; }
    public double? Latitude { get; init; }
    public double? Longitude { get; init; }
}

public record CreateAdminUserDto
{
    public string FullName { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;

    /// <summary>SuperAdmin | FleetManager | SupportLead | RegionalCoordinator</summary>
    public string AdminRole { get; init; } = "FleetManager";

    public string TemporaryPassword { get; init; } = string.Empty;
    public bool ForcePasswordReset { get; init; } = true;
}

public record UpdateUserLocationDto
{
    public double Latitude { get; init; }
    public double Longitude { get; init; }
}
