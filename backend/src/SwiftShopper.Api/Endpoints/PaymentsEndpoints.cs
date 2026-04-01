using System.Security.Claims;
using SwiftShopper.Application.Abstractions;

namespace SwiftShopper.Api.Endpoints;

public static class PaymentsEndpoints
{
    public static RouteGroupBuilder MapPaymentsEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/payments").WithTags("Payments").RequireAuthorization();

        group.MapGet("/{orderId}/summary", async (
            string orderId,
            ClaimsPrincipal user,
            ISwiftShopperService service,
            CancellationToken cancellationToken) =>
        {
            var authenticatedCustomerId = GetAuthenticatedUserId(user);
            if (string.IsNullOrWhiteSpace(authenticatedCustomerId))
            {
                return Results.Unauthorized();
            }

            var isOwner = await service.IsOrderOwnedByCustomerAsync(
                orderId,
                authenticatedCustomerId,
                cancellationToken);

            if (!isOwner)
            {
                return Results.Forbid();
            }

            var summary = await service.GetPaymentSummaryAsync(orderId, cancellationToken);
            return summary is null ? Results.NotFound() : Results.Ok(summary);
        });

        return group;
    }

    private static string? GetAuthenticatedUserId(ClaimsPrincipal user)
    {
        return user.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? user.FindFirstValue("sub");
    }
}
