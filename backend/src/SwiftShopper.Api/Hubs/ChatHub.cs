using Microsoft.AspNetCore.SignalR;

namespace SwiftShopper.Api.Hubs;

public class ChatHub : Hub
{
    public static class Events
    {
        public const string MessageReceived = "messageReceived";
        public const string PriceDecisionReceived = "priceDecisionReceived";
    }

    public Task JoinOrderRoom(string orderId)
    {
        return Groups.AddToGroupAsync(Context.ConnectionId, orderId);
    }

    public Task LeaveOrderRoom(string orderId)
    {
        return Groups.RemoveFromGroupAsync(Context.ConnectionId, orderId);
    }
}
