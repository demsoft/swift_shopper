using SwiftShopper.Application.Contracts.Requests;
using SwiftShopper.Application.Contracts.Responses;
using SwiftShopper.Domain.Entities;
using SwiftShopper.Domain.Enums;

namespace SwiftShopper.Application.Abstractions;

public interface ISwiftShopperService
{
    // ── Auth ─────────────────────────────────────────────────────────────────
    Task<AuthenticatedUserDto?> LoginAsync(LoginUserDto request, CancellationToken cancellationToken);
    Task<SignupOtpChallengeDto> RegisterCustomerAsync(RegisterUserDto request, CancellationToken cancellationToken);
    Task<SignupOtpChallengeDto> RegisterShopperAsync(RegisterUserDto request, CancellationToken cancellationToken);
    Task<SignupOtpChallengeDto?> ResendSignupOtpAsync(ResendSignupOtpDto request, CancellationToken cancellationToken);
    Task<AuthenticatedUserDto?> VerifySignupOtpAsync(VerifySignupOtpDto request, CancellationToken cancellationToken);

    // ── Customer: Requests ────────────────────────────────────────────────────
    Task<ShoppingRequest> CreateRequestAsync(CreateShoppingRequestDto request, CancellationToken cancellationToken);
    Task<IReadOnlyList<RecentRequestDto>> GetRecentRequestsAsync(string customerId, CancellationToken cancellationToken);

    // ── Customer: Orders ──────────────────────────────────────────────────────
    Task<IReadOnlyList<ActiveOrderDto>> GetActiveOrdersAsync(string customerId, CancellationToken cancellationToken);
    Task<bool> IsOrderOwnedByCustomerAsync(string orderId, string customerId, CancellationToken cancellationToken);
    Task<bool> CanAccessOrderChatAsync(string orderId, string userId, CancellationToken cancellationToken);
    Task<OrderTrackingDto?> GetOrderTrackingAsync(string orderId, CancellationToken cancellationToken);
    Task<IReadOnlyList<ActiveJobItemDto>> GetOrderItemsAsync(string orderId, CancellationToken cancellationToken);
    Task<OrderSummaryDto?> GetOrderSummaryAsync(string orderId, CancellationToken cancellationToken);
    Task<PaymentSummaryDto?> GetPaymentSummaryAsync(string orderId, CancellationToken cancellationToken);

    // ── Shopper: Job management ───────────────────────────────────────────────
    /// <summary>Returns all open requests not yet accepted by a shopper.</summary>
    Task<IReadOnlyList<ShoppingRequest>> GetAvailableRequestsAsync(CancellationToken cancellationToken);

    /// <summary>Shopper accepts an open request, creating their active job.</summary>
    Task<ActiveJobDto> AcceptRequestAsync(string requestId, AcceptRequestDto dto, CancellationToken cancellationToken);

    /// <summary>Returns the shopper's current active job.</summary>
    Task<ActiveJobDto?> GetActiveJobAsync(string shopperId, CancellationToken cancellationToken);

    /// <summary>Shopper marks a single item as found or unavailable.</summary>
    Task<ActiveJobItemDto> UpdateOrderItemAsync(string orderId, int itemId, UpdateOrderItemDto dto, CancellationToken cancellationToken);

    /// <summary>Shopper completes shopping — moves order to Purchased status.</summary>
    Task<Order> FinishShoppingAsync(string orderId, string shopperId, CancellationToken cancellationToken);

    /// <summary>Shopper confirms the receipt and starts delivery — moves order to OutForDelivery.</summary>
    Task<Order> StartDeliveryAsync(string orderId, string shopperId, CancellationToken cancellationToken);

    /// <summary>Customer confirms they received the order — moves order to Delivered.</summary>
    Task<Order> ConfirmDeliveryAsync(string orderId, string customerId, CancellationToken cancellationToken);

    /// <summary>Returns the shopper's completed/cancelled order history.</summary>
    Task<IReadOnlyList<ShopperOrderHistoryDto>> GetShopperOrderHistoryAsync(string shopperId, CancellationToken cancellationToken);

    // ── Chat ──────────────────────────────────────────────────────────────────
    Task<IReadOnlyList<ChatMessage>> GetMessagesAsync(string orderId, CancellationToken cancellationToken);
    Task<ChatMessage> SendMessageAsync(string orderId, SendChatMessageDto request, CancellationToken cancellationToken);

    /// <summary>Shopper sends a price-card message proposing a new price for an item.</summary>
    Task<ChatMessage> SendPriceCardAsync(string orderId, SendPriceCardDto dto, CancellationToken cancellationToken);
    Task<ChatMessage> ResolvePriceCardAsync(string orderId, ResolvePriceCardDto request, CancellationToken cancellationToken);

    // ── Admin: Dashboard ──────────────────────────────────────────────────────
    Task<AdminDashboardDto> GetAdminDashboardAsync(CancellationToken cancellationToken);

    // ── Admin: Orders ─────────────────────────────────────────────────────────
    Task<PagedResult<AdminOrderDto>> GetAdminOrdersAsync(string? status, int page, int pageSize, CancellationToken cancellationToken);
    Task<AdminOrderDto?> GetAdminOrderAsync(string orderId, CancellationToken cancellationToken);
    Task<Order> UpdateAdminOrderStatusAsync(string orderId, UpdateOrderStatusDto dto, CancellationToken cancellationToken);

    // ── Admin: Shoppers ───────────────────────────────────────────────────────
    Task<PagedResult<AdminShopperDto>> GetAdminShoppersAsync(string tab, int page, int pageSize, CancellationToken cancellationToken);
    Task UpdateAdminShopperStatusAsync(string shopperId, UpdateUserStatusDto dto, CancellationToken cancellationToken);

    // ── Admin: Customers ──────────────────────────────────────────────────────
    Task<PagedResult<AdminCustomerDto>> GetAdminCustomersAsync(string? membership, string? status, int page, int pageSize, CancellationToken cancellationToken);
    Task UpdateAdminCustomerStatusAsync(string customerId, UpdateUserStatusDto dto, CancellationToken cancellationToken);

    // ── Admin: Earnings ───────────────────────────────────────────────────────
    Task<AdminEarningsSummaryDto> GetAdminEarningsSummaryAsync(CancellationToken cancellationToken);
    Task<PagedResult<AdminPayoutDto>> GetAdminPayoutsAsync(int page, int pageSize, CancellationToken cancellationToken);

    // ── Admin: Markets ────────────────────────────────────────────────────────
    Task<IReadOnlyList<MarketDto>> GetPublicMarketsAsync(string? type, CancellationToken cancellationToken);
    Task<PagedResult<AdminMarketDto>> GetAdminMarketsAsync(string? type, string? status, int page, int pageSize, CancellationToken cancellationToken);
    Task<AdminMarketDto> CreateAdminMarketAsync(CreateMarketDto dto, CancellationToken cancellationToken);
    Task<AdminMarketDto?> UpdateAdminMarketAsync(string marketId, CreateMarketDto dto, CancellationToken cancellationToken);
    Task<bool> DeleteAdminMarketAsync(string marketId, CancellationToken cancellationToken);

    // ── Admin: Users ──────────────────────────────────────────────────────────
    Task<IReadOnlyList<AdminUserDto>> GetAdminUsersAsync(CancellationToken cancellationToken);
    Task<AdminUserDto> CreateAdminUserAsync(CreateAdminUserDto dto, CancellationToken cancellationToken);

    // ── User: Location ────────────────────────────────────────────────────────
    Task UpdateUserLocationAsync(string userId, double latitude, double longitude, CancellationToken cancellationToken);
}
