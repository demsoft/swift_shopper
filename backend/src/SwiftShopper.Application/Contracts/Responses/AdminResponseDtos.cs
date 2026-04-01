using SwiftShopper.Domain.Enums;

namespace SwiftShopper.Application.Contracts.Responses;

// ── Shared ────────────────────────────────────────────────────────────────────

public record PagedResult<T>
{
    public IReadOnlyList<T> Items { get; init; } = [];
    public int TotalCount { get; init; }
    public int Page { get; init; }
    public int PageSize { get; init; }
    public int TotalPages => PageSize > 0 ? (int)Math.Ceiling((double)TotalCount / PageSize) : 0;
}

// ── Dashboard ─────────────────────────────────────────────────────────────────

public record AdminDashboardDto
{
    public int TotalOrdersToday { get; init; }
    public int ActiveOrders { get; init; }
    public int CompletedOrdersToday { get; init; }
    public int ActiveShoppers { get; init; }
    public int TotalShoppers { get; init; }
    public int TotalCustomers { get; init; }
    public decimal RevenueToday { get; init; }
    public decimal RevenueThisMonth { get; init; }
    public decimal PlatformFeesToday { get; init; }
    public double AvgWaitTimeMinutes { get; init; }
    public IReadOnlyList<AdminRecentOrderDto> RecentOrders { get; init; } = [];
    public IReadOnlyList<AdminMonthlyStatDto> MonthlyChart { get; init; } = [];
}

public record AdminRecentOrderDto
{
    public string OrderId { get; init; } = string.Empty;
    public string CustomerName { get; init; } = string.Empty;
    public string CustomerInitials { get; init; } = string.Empty;
    public string CustomerLocation { get; init; } = string.Empty;
    public string? ShopperName { get; init; }
    public string StoreName { get; init; } = string.Empty;
    public string MarketIcon { get; init; } = "storefront";
    public OrderStatus Status { get; init; }
    public decimal Total { get; init; }
    public DateTimeOffset UpdatedAt { get; init; }
}

public record AdminMonthlyStatDto
{
    public string Month { get; init; } = string.Empty;
    public decimal Revenue { get; init; }
    public decimal Payouts { get; init; }
}

// ── Orders ────────────────────────────────────────────────────────────────────

public record AdminOrderDto
{
    public string OrderId { get; init; } = string.Empty;
    public string CustomerName { get; init; } = string.Empty;
    public string CustomerInitials { get; init; } = string.Empty;
    public string CustomerLocation { get; init; } = string.Empty;
    public string? ShopperName { get; init; }
    public string? ShopperTier { get; init; }
    public string StoreName { get; init; } = string.Empty;
    public string MarketIcon { get; init; } = "storefront";
    public OrderStatus Status { get; init; }
    public decimal Total { get; init; }
    public DateTimeOffset UpdatedAt { get; init; }
}

// ── Shoppers ──────────────────────────────────────────────────────────────────

public record AdminShopperDto
{
    public string ShopperId { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string Initials { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;
    public bool IsOnline { get; init; }
    public bool IsVerified { get; init; }
    public bool IsActive { get; init; }

    /// <summary>PRO SHOPPER | BASIC</summary>
    public string Tier { get; init; } = "BASIC";

    public decimal Rating { get; init; }
    public int CompletedOrders { get; init; }
    public int OrdersThisMonth { get; init; }
    public decimal EarningsThisMonth { get; init; }
    public DateTimeOffset JoinedAt { get; init; }
    public DateTimeOffset? LastActiveAt { get; init; }
}

// ── Customers ─────────────────────────────────────────────────────────────────

public record AdminCustomerDto
{
    public string CustomerId { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string Initials { get; init; } = string.Empty;
    public string AvatarBg { get; init; } = "bg-neutral-200";
    public string AvatarText { get; init; } = "text-neutral-600";
    public string Email { get; init; } = string.Empty;
    public int TotalOrders { get; init; }
    public DateTimeOffset? LastOrderAt { get; init; }
    public decimal TotalSpend { get; init; }

    /// <summary>Premium | Basic</summary>
    public string Membership { get; init; } = "Basic";

    public bool IsActive { get; init; }
    public DateTimeOffset JoinedAt { get; init; }
}

// ── Earnings ──────────────────────────────────────────────────────────────────

public record AdminEarningsSummaryDto
{
    public decimal TotalRevenue { get; init; }
    public decimal ShopperPayouts { get; init; }
    public decimal PlatformFees { get; init; }
    public decimal PlatformMarginPercent { get; init; }
    public string NextPayoutCycle { get; init; } = string.Empty;
    public IReadOnlyList<AdminMonthlyStatDto> MonthlyChart { get; init; } = [];
}

public record AdminPayoutDto
{
    public string PayoutId { get; init; } = string.Empty;
    public string ShopperId { get; init; } = string.Empty;
    public string ShopperName { get; init; } = string.Empty;
    public string ShopperInitials { get; init; } = string.Empty;
    public DateTimeOffset Date { get; init; }
    public decimal Amount { get; init; }

    /// <summary>Paid | Processing | Failed</summary>
    public string Status { get; init; } = "Paid";

    public string ActionIcon { get; init; } = "receipt_long";
}

// ── Markets ───────────────────────────────────────────────────────────────────

public record AdminMarketDto
{
    public string MarketId { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string Type { get; init; } = string.Empty;
    public string Location { get; init; } = string.Empty;
    public string Zone { get; init; } = string.Empty;
    public string Address { get; init; } = string.Empty;
    public bool IsActive { get; init; }
    public IReadOnlyList<string> Categories { get; init; } = [];
    public string OpeningTime { get; init; } = string.Empty;
    public string ClosingTime { get; init; } = string.Empty;
    public double GeofenceRadiusKm { get; init; }
    public int ActiveShoppers { get; init; }
    public int OrdersToday { get; init; }
    public string? PhotoUrl { get; init; }
    public double? Latitude { get; init; }
    public double? Longitude { get; init; }
    public DateTimeOffset CreatedAt { get; init; }
}

// ── Admin Users ───────────────────────────────────────────────────────────────

public record AdminUserDto
{
    public string UserId { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string Initials { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;

    /// <summary>SuperAdmin | FleetManager | SupportLead | RegionalCoordinator</summary>
    public string AdminRole { get; init; } = "FleetManager";

    public bool IsActive { get; init; }
    public bool ForcePasswordReset { get; init; }
    public DateTimeOffset CreatedAt { get; init; }
}

// ── Shopper Order History ──────────────────────────────────────────────────

public record ShopperOrderHistoryDto
{
    public string OrderId { get; init; } = string.Empty;
    public string StoreName { get; init; } = string.Empty;
    public string CustomerName { get; init; } = string.Empty;
    public DateTimeOffset CompletedAt { get; init; }
    public decimal EarningsAmount { get; init; }
    public int Status { get; init; }
    public int ItemsCount { get; init; }
}

// ── Public Markets ─────────────────────────────────────────────────────────────

public record MarketDto
{
    public string MarketId { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string Type { get; init; } = string.Empty;
    public string Address { get; init; } = string.Empty;
    public string Location { get; init; } = string.Empty;
    public List<string> Categories { get; init; } = [];
    public string OpeningTime { get; init; } = string.Empty;
    public string ClosingTime { get; init; } = string.Empty;
    public double GeofenceRadiusKm { get; init; }
    public string? PhotoUrl { get; init; }
    public double? Latitude { get; init; }
    public double? Longitude { get; init; }
}
