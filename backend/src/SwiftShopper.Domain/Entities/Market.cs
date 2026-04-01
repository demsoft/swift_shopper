namespace SwiftShopper.Domain.Entities;

public class Market
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;

    /// <summary>Supermarket | OpenMarket | Specialty | Mall</summary>
    public string Type { get; set; } = string.Empty;

    public string Location { get; set; } = string.Empty;
    public string Zone { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;

    /// <summary>Stored as a comma-separated string in the DB.</summary>
    public List<string> Categories { get; set; } = [];

    public string OpeningTime { get; set; } = "08:00";
    public string ClosingTime { get; set; } = "20:00";
    public double GeofenceRadiusKm { get; set; } = 5.0;

    public string? PhotoUrl { get; set; }

    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
}
