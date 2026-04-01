namespace SwiftShopper.Api.Endpoints;

public static class HealthEndpoints
{
    public static IEndpointRouteBuilder MapHealthEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/health", () => Results.Ok(new
        {
            Status = "Healthy",
            Service = "SwiftShopper API",
            UtcTime = DateTimeOffset.UtcNow
        }))
        .WithTags("Health")
        .WithOpenApi();

        return app;
    }
}
