using SwiftShopper.Application.Abstractions;
using SwiftShopper.Application.Contracts.Requests;
using SwiftShopper.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using SwiftShopper.Domain.Enums;

namespace SwiftShopper.Api.Endpoints;

public static class AdminEndpoints
{
    public static void MapAdminEndpoints(this IEndpointRouteBuilder app)
    {
        // ── Seed first admin (no auth required — only works when no admin exists) ──

        app.MapPost("/api/admin/seed-first-admin", async (
            CreateAdminUserDto body,
            ISwiftShopperService svc,
            SwiftShopperDbContext db,
            CancellationToken ct) =>
        {
            var adminExists = await db.UserAccounts
                .AnyAsync(x => x.Role == UserRole.Admin, ct);

            if (adminExists)
                return Results.Conflict("An admin user already exists. Use the authenticated endpoint to add more.");

            var user = await svc.CreateAdminUserAsync(body, ct);
            return Results.Created($"/api/admin/users/{user.UserId}", user);
        })
        .WithTags("Admin")
        .WithSummary("Bootstrap: create the very first admin user (disabled once any admin exists).");

        var group = app
            .MapGroup("/api/admin")
            .WithTags("Admin")
            .RequireAuthorization("AdminOnly");

        // ── Dashboard ─────────────────────────────────────────────────────────

        group.MapGet("/dashboard", async (
            ISwiftShopperService svc,
            CancellationToken ct) =>
        {
            var dto = await svc.GetAdminDashboardAsync(ct);
            return Results.Ok(dto);
        })
        .WithSummary("Admin dashboard — key metrics and recent orders.");

        // ── Orders ────────────────────────────────────────────────────────────

        group.MapGet("/orders", async (
            ISwiftShopperService svc,
            string? status,
            int page = 1,
            int pageSize = 20,
            CancellationToken ct = default) =>
        {
            var result = await svc.GetAdminOrdersAsync(status, page, pageSize, ct);
            return Results.Ok(result);
        })
        .WithSummary("Paginated list of all orders with optional status filter.");

        group.MapGet("/orders/{orderId}", async (
            string orderId,
            ISwiftShopperService svc,
            CancellationToken ct) =>
        {
            var dto = await svc.GetAdminOrderAsync(orderId, ct);
            return dto is null ? Results.NotFound() : Results.Ok(dto);
        })
        .WithSummary("Single order detail for admin.");

        group.MapPatch("/orders/{orderId}/status", async (
            string orderId,
            UpdateOrderStatusDto body,
            ISwiftShopperService svc,
            CancellationToken ct) =>
        {
            try
            {
                var order = await svc.UpdateAdminOrderStatusAsync(orderId, body, ct);
                return Results.Ok(new { order.Id, order.Status, order.UpdatedAt });
            }
            catch (KeyNotFoundException)
            {
                return Results.NotFound();
            }
        })
        .WithSummary("Update the status of any order (admin override).");

        // ── Shoppers ──────────────────────────────────────────────────────────

        group.MapGet("/shoppers", async (
            ISwiftShopperService svc,
            string tab = "all",
            int page = 1,
            int pageSize = 20,
            CancellationToken ct = default) =>
        {
            var result = await svc.GetAdminShoppersAsync(tab, page, pageSize, ct);
            return Results.Ok(result);
        })
        .WithSummary("Paginated shopper list. tab=all|pending.");

        group.MapPatch("/shoppers/{shopperId}/status", async (
            string shopperId,
            UpdateUserStatusDto body,
            ISwiftShopperService svc,
            CancellationToken ct) =>
        {
            try
            {
                await svc.UpdateAdminShopperStatusAsync(shopperId, body, ct);
                return Results.NoContent();
            }
            catch (KeyNotFoundException)
            {
                return Results.NotFound();
            }
        })
        .WithSummary("Activate or suspend a shopper account.");

        // ── Customers ─────────────────────────────────────────────────────────

        group.MapGet("/customers", async (
            ISwiftShopperService svc,
            string? membership,
            string? status,
            int page = 1,
            int pageSize = 20,
            CancellationToken ct = default) =>
        {
            var result = await svc.GetAdminCustomersAsync(membership, status, page, pageSize, ct);
            return Results.Ok(result);
        })
        .WithSummary("Paginated customer list with optional membership/status filter.");

        group.MapPatch("/customers/{customerId}/status", async (
            string customerId,
            UpdateUserStatusDto body,
            ISwiftShopperService svc,
            CancellationToken ct) =>
        {
            try
            {
                await svc.UpdateAdminCustomerStatusAsync(customerId, body, ct);
                return Results.NoContent();
            }
            catch (KeyNotFoundException)
            {
                return Results.NotFound();
            }
        })
        .WithSummary("Activate or suspend a customer account.");

        // ── Earnings ──────────────────────────────────────────────────────────

        group.MapGet("/earnings/summary", async (
            ISwiftShopperService svc,
            CancellationToken ct) =>
        {
            var dto = await svc.GetAdminEarningsSummaryAsync(ct);
            return Results.Ok(dto);
        })
        .WithSummary("Platform earnings summary — revenue, payouts, fees, chart data.");

        group.MapGet("/earnings/payouts", async (
            ISwiftShopperService svc,
            int page = 1,
            int pageSize = 20,
            CancellationToken ct = default) =>
        {
            var result = await svc.GetAdminPayoutsAsync(page, pageSize, ct);
            return Results.Ok(result);
        })
        .WithSummary("Paginated shopper payout history.");

        // ── Markets ───────────────────────────────────────────────────────────

        group.MapGet("/markets", async (
            ISwiftShopperService svc,
            string? type,
            string? status,
            int page = 1,
            int pageSize = 20,
            CancellationToken ct = default) =>
        {
            var result = await svc.GetAdminMarketsAsync(type, status, page, pageSize, ct);
            return Results.Ok(result);
        })
        .WithSummary("Paginated market list with optional type/status filter.");

        group.MapPost("/markets", async (
            CreateMarketDto body,
            ISwiftShopperService svc,
            CancellationToken ct) =>
        {
            var dto = await svc.CreateAdminMarketAsync(body, ct);
            return Results.Created($"/api/admin/markets/{dto.MarketId}", dto);
        })
        .WithSummary("Register a new market hub.");

        group.MapPatch("/markets/{marketId}", async (
            string marketId,
            CreateMarketDto body,
            ISwiftShopperService svc,
            CancellationToken ct) =>
        {
            var dto = await svc.UpdateAdminMarketAsync(marketId, body, ct);
            return dto is null ? Results.NotFound() : Results.Ok(dto);
        })
        .WithSummary("Update an existing market hub.");

        group.MapDelete("/markets/{marketId}", async (
            string marketId,
            ISwiftShopperService svc,
            CancellationToken ct) =>
        {
            var deleted = await svc.DeleteAdminMarketAsync(marketId, ct);
            return deleted ? Results.NoContent() : Results.NotFound();
        })
        .WithSummary("Remove a market hub from the directory.");

        // ── Admin Users ───────────────────────────────────────────────────────

        group.MapGet("/users", async (
            ISwiftShopperService svc,
            CancellationToken ct) =>
        {
            var users = await svc.GetAdminUsersAsync(ct);
            return Results.Ok(users);
        })
        .WithSummary("List all admin portal users.");

        group.MapPost("/users", async (
            CreateAdminUserDto body,
            ISwiftShopperService svc,
            CancellationToken ct) =>
        {
            var user = await svc.CreateAdminUserAsync(body, ct);
            return Results.Created($"/api/admin/users/{user.UserId}", user);
        })
        .WithSummary("Create a new admin portal user with a role assignment.");
    }
}
