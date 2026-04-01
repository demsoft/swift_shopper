using System.Security.Claims;
using Microsoft.AspNetCore.SignalR;
using SwiftShopper.Application.Abstractions;
using SwiftShopper.Application.Contracts.Requests;
using SwiftShopper.Api.Hubs;

namespace SwiftShopper.Api.Endpoints;

public static class ChatEndpoints
{
    public static RouteGroupBuilder MapChatEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/orders/{orderId}/chat").WithTags("Chat").RequireAuthorization();

        group.MapGet("", async (
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

            var messages = await service.GetMessagesAsync(orderId, cancellationToken);
            return Results.Ok(messages);
        });

        group.MapPost("/messages", async (
            string orderId,
            SendChatMessageDto request,
            ClaimsPrincipal user,
            ISwiftShopperService service,
            IHubContext<ChatHub> hubContext,
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

            var message = await service.SendMessageAsync(orderId, request, cancellationToken);
            await hubContext.Clients
                .Group(orderId)
                .SendAsync(ChatHub.Events.MessageReceived, message, cancellationToken);

            return Results.Ok(message);
        });

        group.MapPost("/price-decision", async (
            string orderId,
            ResolvePriceCardDto request,
            ClaimsPrincipal user,
            ISwiftShopperService service,
            IHubContext<ChatHub> hubContext,
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

            var message = await service.ResolvePriceCardAsync(orderId, request, cancellationToken);
            await hubContext.Clients
                .Group(orderId)
                .SendAsync(ChatHub.Events.PriceDecisionReceived, message, cancellationToken);

            return Results.Ok(message);
        });

        // POST /api/orders/{orderId}/chat/price-card — shopper sends a price-card message
        group.MapPost("/price-card", async (
            string orderId,
            SendPriceCardDto dto,
            ClaimsPrincipal user,
            ISwiftShopperService service,
            IHubContext<ChatHub> hubContext,
            CancellationToken cancellationToken) =>
        {
            var authenticatedShopperId = GetAuthenticatedUserId(user);
            if (string.IsNullOrWhiteSpace(authenticatedShopperId))
            {
                return Results.Unauthorized();
            }

            var message = await service.SendPriceCardAsync(orderId, dto, cancellationToken);
            await hubContext.Clients
                .Group(orderId)
                .SendAsync(ChatHub.Events.MessageReceived, message, cancellationToken);

            return Results.Ok(message);
        });

        return group;
    }

    private static string? GetAuthenticatedUserId(ClaimsPrincipal user)
    {
        return user.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? user.FindFirstValue("sub");
    }
}
