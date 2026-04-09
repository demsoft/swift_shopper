using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace SwiftShopper.Api.Endpoints;

public static class PlacesEndpoints
{
    private static readonly HttpClient HttpClient = new();

    public static void MapPlacesEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app
            .MapGroup("/api/places")
            .WithTags("Places");

        group.MapGet("/search", async (
            string query,
            int limit = 10,
            CancellationToken ct = default) =>
        {
            if (string.IsNullOrWhiteSpace(query) || query.Length < 3)
                return Results.Ok(new { results = new List<PlaceSuggestion>() });

            try
            {
                // Call Nominatim API
                var url = $"https://nominatim.openstreetmap.org/search?q={Uri.EscapeDataString(query)}&format=json&limit={limit}&addressdetails=1&countrycodes=NG";

                var response = await HttpClient.GetAsync(url, ct);
                if (!response.IsSuccessStatusCode)
                    return Results.Ok(new { results = new List<PlaceSuggestion>() });

                var jsonString = await response.Content.ReadAsStringAsync(ct);
                var nominatimResults = JsonSerializer.Deserialize<List<NominatimResult>>(jsonString);

                var suggestions = nominatimResults?
                    .Select(r => new PlaceSuggestion
                    {
                        Address = r.DisplayName,
                        Latitude = double.Parse(r.Lat),
                        Longitude = double.Parse(r.Lon),
                    })
                    .ToList() ?? [];

                return Results.Ok(new { results = suggestions });
            }
            catch
            {
                return Results.Ok(new { results = new List<PlaceSuggestion>() });
            }
        })
        .WithSummary("Search for addresses using OpenStreetMap Nominatim API (Nigeria only).")
        .WithName("searchPlaces")
        .WithOpenApi();
    }
}

public record PlaceSuggestion
{
    public string Address { get; init; } = string.Empty;
    public double Latitude { get; init; }
    public double Longitude { get; init; }
}

#pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor or declaring as nullable.
internal record NominatimResult
{
    [JsonPropertyName("display_name")]
    public string DisplayName { get; init; }

    [JsonPropertyName("lat")]
    public string Lat { get; init; }

    [JsonPropertyName("lon")]
    public string Lon { get; init; }
}
#pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor or declaring as nullable.
