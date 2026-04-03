using System.Security.Claims;
using SwiftShopper.Application.Abstractions;
using SwiftShopper.Application.Contracts.Requests;

namespace SwiftShopper.Api.Endpoints;

public static class OrdersEndpoints
{
    public static RouteGroupBuilder MapOrdersEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/orders").WithTags("Orders").RequireAuthorization();

        // GET /api/orders/active/{customerId} — customer's active orders
        group.MapGet("/active/{customerId}", async (
            string customerId,
            ClaimsPrincipal user,
            ISwiftShopperService service,
            CancellationToken cancellationToken) =>
        {
            try
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

                var orders = await service.GetActiveOrdersAsync(customerId, cancellationToken);
                return Results.Ok(orders);
            }
            catch
            {
                return Results.StatusCode(500);
            }
        });

        // GET /api/orders/active — customer's active orders (simplified, uses auth context)
        group.MapGet("/active", async (
            ClaimsPrincipal user,
            ISwiftShopperService service,
            CancellationToken cancellationToken) =>
        {
            try
            {
                var authenticatedCustomerId = GetAuthenticatedUserId(user);
                if (string.IsNullOrWhiteSpace(authenticatedCustomerId))
                {
                    return Results.Unauthorized();
                }

                var orders = await service.GetActiveOrdersAsync(authenticatedCustomerId, cancellationToken);
                return Results.Ok(orders);
            }
            catch
            {
                return Results.StatusCode(500);
            }
        });

        // GET /api/orders/{orderId}/tracking — order tracking (customer)
        group.MapGet("/{orderId}/tracking", async (
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

            var tracking = await service.GetOrderTrackingAsync(orderId, cancellationToken);
            return tracking is null ? Results.NotFound() : Results.Ok(tracking);
        });

        // GET /api/orders/{orderId}/summary — completed order summary (customer)
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

            var summary = await service.GetOrderSummaryAsync(orderId, cancellationToken);
            return summary is null ? Results.NotFound() : Results.Ok(summary);
        });

        // GET /api/orders/{orderId}/items — customer views shopping list items for their order
        group.MapGet("/{orderId}/items", async (
            string orderId,
            ClaimsPrincipal user,
            ISwiftShopperService service,
            CancellationToken cancellationToken) =>
        {
            var authenticatedCustomerId = GetAuthenticatedUserId(user);
            if (string.IsNullOrWhiteSpace(authenticatedCustomerId))
                return Results.Unauthorized();

            var isOwner = await service.IsOrderOwnedByCustomerAsync(
                orderId, authenticatedCustomerId, cancellationToken);

            if (!isOwner)
                return Results.Forbid();

            var items = await service.GetOrderItemsAsync(orderId, cancellationToken);
            return Results.Ok(items);
        });

        // GET /api/orders/shopper/active-job — shopper's current active job
        group.MapGet("/shopper/active-job", async (
            ClaimsPrincipal user,
            ISwiftShopperService service,
            CancellationToken cancellationToken) =>
        {
            var authenticatedShopperId = GetAuthenticatedUserId(user);
            if (string.IsNullOrWhiteSpace(authenticatedShopperId))
            {
                return Results.Unauthorized();
            }

            var job = await service.GetActiveJobAsync(authenticatedShopperId, cancellationToken);
            return job is null ? Results.NoContent() : Results.Ok(job);
        });

        // PATCH /api/orders/{orderId}/items/{itemId} — shopper updates a single item
        group.MapPatch("/{orderId}/items/{itemId:int}", async (
            string orderId,
            int itemId,
            UpdateOrderItemDto dto,
            ClaimsPrincipal user,
            ISwiftShopperService service,
            CancellationToken cancellationToken) =>
        {
            var authenticatedShopperId = GetAuthenticatedUserId(user);
            if (string.IsNullOrWhiteSpace(authenticatedShopperId))
            {
                return Results.Unauthorized();
            }

            try
            {
                var updated = await service.UpdateOrderItemAsync(orderId, itemId, dto, cancellationToken);
                return Results.Ok(updated);
            }
            catch (KeyNotFoundException)
            {
                return Results.NotFound();
            }
            catch (InvalidOperationException ex)
            {
                return Results.NotFound(ex.Message);
            }
        });

        // POST /api/orders/{orderId}/finish — shopper finishes shopping
        group.MapPost("/{orderId}/finish", async (
            string orderId,
            ClaimsPrincipal user,
            ISwiftShopperService service,
            CancellationToken cancellationToken) =>
        {
            var authenticatedShopperId = GetAuthenticatedUserId(user);
            if (string.IsNullOrWhiteSpace(authenticatedShopperId))
            {
                return Results.Unauthorized();
            }

            try
            {
                var order = await service.FinishShoppingAsync(orderId, authenticatedShopperId, cancellationToken);
                return Results.Ok(order);
            }
            catch (KeyNotFoundException)
            {
                return Results.NotFound();
            }
        });

        // GET /api/orders/shopper/history — shopper's completed/cancelled order history
        group.MapGet("/shopper/history", async (
            ClaimsPrincipal user,
            ISwiftShopperService service,
            CancellationToken cancellationToken) =>
        {
            var authenticatedShopperId = GetAuthenticatedUserId(user);
            if (string.IsNullOrWhiteSpace(authenticatedShopperId))
            {
                return Results.Unauthorized();
            }

            var history = await service.GetShopperOrderHistoryAsync(authenticatedShopperId, cancellationToken);
            return Results.Ok(history);
        });

        return group;
    }

    private static string? GetAuthenticatedUserId(ClaimsPrincipal user)
    {
        return user.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? user.FindFirstValue("sub");
    }
}
