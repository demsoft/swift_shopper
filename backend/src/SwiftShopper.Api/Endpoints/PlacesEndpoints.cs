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

        // ── Google Places proxy endpoints ──────────────────────────────────

        group.MapGet("/google/autocomplete", async (
            string query,
            string? sessiontoken,
            IConfiguration config,
            CancellationToken ct = default) =>
        {
            if (string.IsNullOrWhiteSpace(query) || query.Length < 3)
                return Results.Ok(new { predictions = new List<object>() });

            var apiKey = config["GooglePlaces:ApiKey"] ?? string.Empty;
            if (string.IsNullOrEmpty(apiKey))
                return Results.Ok(new { predictions = new List<object>() });

            try
            {
                var qs = new Dictionary<string, string?>
                {
                    ["input"]        = query,
                    ["key"]          = apiKey,
                    ["components"]   = "country:ng",
                    ["language"]     = "en",
                    ["location"]     = "6.5244,3.3792",
                    ["radius"]       = "50000",
                };
                if (!string.IsNullOrEmpty(sessiontoken))
                    qs["sessiontoken"] = sessiontoken;

                var url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?" +
                          string.Join("&", qs.Select(kv =>
                              $"{Uri.EscapeDataString(kv.Key)}={Uri.EscapeDataString(kv.Value ?? "")}"));

                var response = await HttpClient.GetAsync(url, ct);
                if (!response.IsSuccessStatusCode)
                    return Results.Ok(new { predictions = new List<object>() });

                var json = await response.Content.ReadFromJsonAsync<GoogleAutocompleteResponse>(ct);
                if (json is null || (json.Status != "OK" && json.Status != "ZERO_RESULTS"))
                    return Results.Ok(new { predictions = new List<object>() });

                var predictions = json.Predictions.Select(p => new
                {
                    placeId     = p.PlaceId,
                    description = p.Description,
                }).ToList();

                return Results.Ok(new { predictions });
            }
            catch
            {
                return Results.Ok(new { predictions = new List<object>() });
            }
        })
        .WithSummary("Proxy: Google Places Autocomplete (Nigeria).")
        .WithName("googleAutocomplete")
        .WithOpenApi();

        group.MapGet("/google/details", async (
            string placeid,
            string? sessiontoken,
            IConfiguration config,
            CancellationToken ct = default) =>
        {
            var apiKey = config["GooglePlaces:ApiKey"] ?? string.Empty;
            if (string.IsNullOrEmpty(apiKey) || string.IsNullOrEmpty(placeid))
                return Results.BadRequest();

            try
            {
                var qs = new Dictionary<string, string?>
                {
                    ["place_id"] = placeid,
                    ["key"]      = apiKey,
                    ["fields"]   = "geometry,formatted_address",
                };
                if (!string.IsNullOrEmpty(sessiontoken))
                    qs["sessiontoken"] = sessiontoken;

                var url = "https://maps.googleapis.com/maps/api/place/details/json?" +
                          string.Join("&", qs.Select(kv =>
                              $"{Uri.EscapeDataString(kv.Key)}={Uri.EscapeDataString(kv.Value ?? "")}"));

                var response = await HttpClient.GetAsync(url, ct);
                if (!response.IsSuccessStatusCode) return Results.BadRequest();

                var json = await response.Content.ReadFromJsonAsync<GoogleDetailsResponse>(ct);
                if (json?.Status != "OK" || json.Result?.Geometry?.Location is null)
                    return Results.BadRequest();

                return Results.Ok(new
                {
                    address = json.Result.FormattedAddress ?? placeid,
                    lat     = json.Result.Geometry.Location.Lat,
                    lng     = json.Result.Geometry.Location.Lng,
                });
            }
            catch
            {
                return Results.BadRequest();
            }
        })
        .WithSummary("Proxy: Google Place Details (lat/lng).")
        .WithName("googlePlaceDetails")
        .WithOpenApi();

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

                var request = new HttpRequestMessage(HttpMethod.Get, url);
                request.Headers.Add("User-Agent", "SwiftShopperApp/1.0");
                var response = await HttpClient.SendAsync(request, ct);
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

#pragma warning disable CS8618
internal record NominatimResult
{
    [JsonPropertyName("display_name")] public string DisplayName { get; init; }
    [JsonPropertyName("lat")]          public string Lat { get; init; }
    [JsonPropertyName("lon")]          public string Lon { get; init; }
}

internal record GoogleAutocompleteResponse
{
    [JsonPropertyName("status")]      public string Status { get; init; }
    [JsonPropertyName("predictions")] public List<GooglePrediction> Predictions { get; init; } = [];
}

internal record GooglePrediction
{
    [JsonPropertyName("place_id")]    public string PlaceId { get; init; }
    [JsonPropertyName("description")] public string Description { get; init; }
}

internal record GoogleDetailsResponse
{
    [JsonPropertyName("status")] public string Status { get; init; }
    [JsonPropertyName("result")] public GoogleDetailsResult? Result { get; init; }
}

internal record GoogleDetailsResult
{
    [JsonPropertyName("formatted_address")] public string? FormattedAddress { get; init; }
    [JsonPropertyName("geometry")]          public GoogleGeometry? Geometry { get; init; }
}

internal record GoogleGeometry
{
    [JsonPropertyName("location")] public GoogleLatLng? Location { get; init; }
}

internal record GoogleLatLng
{
    [JsonPropertyName("lat")] public double Lat { get; init; }
    [JsonPropertyName("lng")] public double Lng { get; init; }
}
#pragma warning restore CS8618
