using System.Security.Claims;
using SwiftShopper.Application.Abstractions;
using SwiftShopper.Application.Contracts.Requests;

namespace SwiftShopper.Api.Endpoints;

public static class RequestsEndpoints
{
    public static RouteGroupBuilder MapRequestsEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/requests").WithTags("Requests").RequireAuthorization();

        // POST /api/requests — customer creates a shopping request
        group.MapPost("", async (
            CreateShoppingRequestDto request,
            ClaimsPrincipal user,
            ISwiftShopperService service,
            CancellationToken cancellationToken) =>
        {
            var authenticatedCustomerId = GetAuthenticatedUserId(user);
            if (string.IsNullOrWhiteSpace(authenticatedCustomerId))
            {
                return Results.Unauthorized();
            }

            if (request.Items.Count == 0)
            {
                return Results.BadRequest("At least one request item is required.");
            }

            var securedRequest = new CreateShoppingRequestDto
            {
                CustomerId = authenticatedCustomerId,
                PreferredStore = request.PreferredStore,
                MarketType = request.MarketType,
                Budget = request.Budget,
                DeliveryAddress = request.DeliveryAddress,
                DeliveryNotes = request.DeliveryNotes,
                Items = request.Items
            };

            var created = await service.CreateRequestAsync(securedRequest, cancellationToken);
            return Results.Created($"/api/requests/{created.Id}", created);
        });

        // GET /api/requests/recent/{customerId} — customer's recent requests
        group.MapGet("/recent/{customerId}", async (
            string customerId,
            ClaimsPrincipal user,
            ISwiftShopperService service,
            CancellationToken cancellationToken) =>
        {
            var authenticatedCustomerId = GetAuthenticatedUserId(user);
            if (string.IsNullOrWhiteSpace(authenticatedCustomerId))
            {
                return Results.Unauthorized();
            }

            if (!string.Equals(customerId, authenticatedCustomerId, StringComparison.OrdinalIgnoreCase))
            {
                return Results.Forbid();
            }

            var requests = await service.GetRecentRequestsAsync(customerId, cancellationToken);
            return Results.Ok(requests);
        });

        // GET /api/requests/available — shopper sees all open requests
        group.MapGet("/available", async (
            ISwiftShopperService service,
            CancellationToken cancellationToken) =>
        {
            var requests = await service.GetAvailableRequestsAsync(cancellationToken);
            return Results.Ok(requests);
        });

        // POST /api/requests/{requestId}/accept — shopper accepts a request
        group.MapPost("/{requestId}/accept", async (
            string requestId,
            AcceptRequestDto dto,
            ClaimsPrincipal user,
            ISwiftShopperService service,
            CancellationToken cancellationToken) =>
        {
            var authenticatedShopperId = GetAuthenticatedUserId(user);
            if (string.IsNullOrWhiteSpace(authenticatedShopperId))
            {
                return Results.Unauthorized();
            }

            // Bind the authenticated shopper id to prevent spoofing
            var securedDto = new AcceptRequestDto
            {
                ShopperId = authenticatedShopperId,
                StoreName = dto.StoreName,
                StoreAddress = dto.StoreAddress
            };

            try
            {
                var job = await service.AcceptRequestAsync(requestId, securedDto, cancellationToken);
                return Results.Ok(job);
            }
            catch (KeyNotFoundException)
            {
                return Results.NotFound();
            }
        });

        return group;
    }

    private static string? GetAuthenticatedUserId(ClaimsPrincipal user)
    {
        return user.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? user.FindFirstValue("sub");
    }
}
