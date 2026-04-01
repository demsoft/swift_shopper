using SwiftShopper.Application.Abstractions;

namespace SwiftShopper.Api.Endpoints;

public static class MarketsEndpoints
{
    public static IEndpointRouteBuilder MapMarketsEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/markets");

        group.MapGet("/", async (
            string? type,
            ISwiftShopperService service,
            CancellationToken ct) =>
        {
            var markets = await service.GetPublicMarketsAsync(type, ct);
            return Results.Ok(markets);
        })
        .WithName("GetPublicMarkets");

        return app;
    }
}
