using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using SwiftShopper.Application.Abstractions;
using SwiftShopper.Application.Contracts.Requests;
using SwiftShopper.Application.Contracts.Responses;
using SwiftShopper.Domain.Entities;
using SwiftShopper.Domain.Enums;
using SwiftShopper.Infrastructure.Persistence;

namespace SwiftShopper.Infrastructure.Services;

public class DbSwiftShopperService : ISwiftShopperService
{
    private readonly SwiftShopperDbContext _dbContext;
    private readonly IEmailService _emailService;
    private static readonly TimeSpan OtpTtl = TimeSpan.FromMinutes(10);
    private const int MaxOtpVerificationAttempts = 5;
    private const decimal ServiceFeeFixed = 1500m;
    private const decimal DeliveryFeePerKm = 100m;
    private const decimal DeliveryFeeDefault = 1500m;
    private const decimal ShopperFeeRate = 0.12m;
    private const decimal ShopperFeeMin = 1000m;
    private const decimal ShopperFeeMax = 7000m;

    private static decimal CalculateShopperFee(decimal subtotal)
    {
        var fee = subtotal * ShopperFeeRate;
        if (fee < ShopperFeeMin) fee = ShopperFeeMin;
        if (fee > ShopperFeeMax) fee = ShopperFeeMax;
        return Math.Round(fee, 2);
    }

    private static decimal CalculateDeliveryFee(double? storeLat, double? storeLng, double? deliveryLat, double? deliveryLng)
    {
        if (storeLat is null || storeLng is null || deliveryLat is null || deliveryLng is null)
            return DeliveryFeeDefault;

        var distanceKm = HaversineKm(storeLat.Value, storeLng.Value, deliveryLat.Value, deliveryLng.Value);
        var fee = (decimal)distanceKm * DeliveryFeePerKm;
        return Math.Round(Math.Max(fee, 500m), 2); // minimum ₦500
    }

    private static double HaversineKm(double lat1, double lon1, double lat2, double lon2)
    {
        const double R = 6371.0;
        var dLat = (lat2 - lat1) * Math.PI / 180.0;
        var dLon = (lon2 - lon1) * Math.PI / 180.0;
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2)
              + Math.Cos(lat1 * Math.PI / 180.0) * Math.Cos(lat2 * Math.PI / 180.0)
              * Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return R * c;
    }

    public DbSwiftShopperService(SwiftShopperDbContext dbContext, IEmailService emailService)
    {
        _dbContext = dbContext;
        _emailService = emailService;
    }

    // ── Auth ─────────────────────────────────────────────────────────────────

    public async Task<AuthenticatedUserDto?> LoginAsync(
        LoginUserDto request, CancellationToken cancellationToken)
    {
        var identity = request.EmailOrPhoneNumber.Trim();
        var normalizedEmail = identity.ToLowerInvariant();

        var user = await _dbContext.UserAccounts.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Email == normalizedEmail || x.PhoneNumber == identity, cancellationToken);

        if (user is null || !user.IsActive) return null;

        var salt = Convert.FromBase64String(user.PasswordSalt);
        var attemptedHash = HashPassword(request.Password, salt);
        var storedHash = Convert.FromBase64String(user.PasswordHash);

        if (!CryptographicOperations.FixedTimeEquals(attemptedHash, storedHash)) return null;

        return MapToAuthDto(user);
    }

    public Task<SignupOtpChallengeDto> RegisterCustomerAsync(RegisterUserDto request, CancellationToken ct) =>
        RegisterAsync(request, UserRole.Customer, ct);

    public Task<SignupOtpChallengeDto> RegisterShopperAsync(RegisterUserDto request, CancellationToken ct) =>
        RegisterAsync(request, UserRole.Shopper, ct);

    public async Task<SignupOtpChallengeDto?> ResendSignupOtpAsync(
        ResendSignupOtpDto request, CancellationToken cancellationToken)
    {
        var userId = request.UserId.Trim();
        if (string.IsNullOrWhiteSpace(userId)) return null;

        var user = await _dbContext.UserAccounts.FirstOrDefaultAsync(x => x.Id == userId, cancellationToken);
        if (user is null || user.IsActive) return null;

        var active = await _dbContext.SignupOtpVerifications
            .Where(x => x.UserId == userId && x.ConsumedAt == null)
            .ToListAsync(cancellationToken);

        foreach (var v in active) v.ConsumedAt = DateTimeOffset.UtcNow;

        var challenge = await CreateOtpChallengeAsync(user, cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);
        await SendSignupOtpEmailAsync(user, challenge, cancellationToken);
        return challenge;
    }

    public async Task<AuthenticatedUserDto?> VerifySignupOtpAsync(
        VerifySignupOtpDto request, CancellationToken cancellationToken)
    {
        var userId = request.UserId.Trim();
        var otpCode = request.OtpCode.Trim();
        if (string.IsNullOrWhiteSpace(userId) || string.IsNullOrWhiteSpace(otpCode)) return null;

        var user = await _dbContext.UserAccounts.FirstOrDefaultAsync(x => x.Id == userId, cancellationToken);
        if (user is null) return null;
        if (user.IsActive) return MapToAuthDto(user);

        var verification = await _dbContext.SignupOtpVerifications
            .Where(x => x.UserId == userId && x.ConsumedAt == null)
            .OrderByDescending(x => x.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (verification is null || verification.ExpiresAt < DateTimeOffset.UtcNow) return null;

        if (verification.FailedAttempts >= MaxOtpVerificationAttempts)
        {
            verification.ConsumedAt = DateTimeOffset.UtcNow;
            await _dbContext.SaveChangesAsync(cancellationToken);
            return null;
        }

        var incomingHash = ComputeOtpHash(otpCode);
        if (!FixedTimeEqualsBase64(incomingHash, verification.CodeHash))
        {
            verification.FailedAttempts += 1;
            if (verification.FailedAttempts >= MaxOtpVerificationAttempts)
                verification.ConsumedAt = DateTimeOffset.UtcNow;
            await _dbContext.SaveChangesAsync(cancellationToken);
            return null;
        }

        verification.ConsumedAt = DateTimeOffset.UtcNow;
        user.IsActive = true;
        await _dbContext.SaveChangesAsync(cancellationToken);
        return MapToAuthDto(user);
    }

    // ── Customer: Requests ────────────────────────────────────────────────────

    public async Task<ShoppingRequest> CreateRequestAsync(
        CreateShoppingRequestDto request, CancellationToken cancellationToken)
    {
        var entity = new ShoppingRequest
        {
            Id = $"REQ-{Random.Shared.Next(1000, 9999)}",
            CustomerId = request.CustomerId,
            PreferredStore = request.PreferredStore,
            MarketType = request.MarketType,
            Budget = request.Budget,
            DeliveryAddress = request.DeliveryAddress,
            DeliveryNotes = request.DeliveryNotes,
            Items = request.Items.Select(i => new RequestItem
            {
                Name = i.Name,
                Unit = i.Unit,
                Description = i.Description,
                Price = i.Price,
                Quantity = i.Quantity,
                MaxPrice = i.MaxPrice
            }).ToList(),
            CreatedAt = DateTimeOffset.UtcNow
        };

        await _dbContext.ShoppingRequests.AddAsync(entity, cancellationToken);

        var order = new Order
        {
            Id = $"ORD-{Random.Shared.Next(1000, 9999)}",
            RequestId = entity.Id,
            Status = OrderStatus.Pending,
            ServiceFee = ServiceFeeFixed,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        await _dbContext.Orders.AddAsync(order, cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return entity;
    }

    public async Task<IReadOnlyList<RecentRequestDto>> GetRecentRequestsAsync(
        string customerId, CancellationToken cancellationToken)
    {
        var requests = await _dbContext.ShoppingRequests.AsNoTracking()
            .Where(x => x.CustomerId == customerId)
            .OrderByDescending(x => x.CreatedAt)
            .Take(10)
            .ToListAsync(cancellationToken);

        var requestIds = requests.Select(r => r.Id).ToList();
        var orders = await _dbContext.Orders.AsNoTracking()
            .Where(o => requestIds.Contains(o.RequestId))
            .ToDictionaryAsync(o => o.RequestId, cancellationToken);

        return requests.Select(r =>
        {
            orders.TryGetValue(r.Id, out var order);
            return new RecentRequestDto
            {
                Id = r.Id,
                PreferredStore = r.PreferredStore,
                DeliveryAddress = r.DeliveryAddress,
                Budget = r.Budget,
                ItemsCount = r.Items.Count,
                CreatedAt = r.CreatedAt,
                OrderId = order?.Id,
                OrderStatus = order != null ? (int)order.Status : null,
                ItemsSubtotal = order?.ItemsSubtotal,
                DeliveryFee = order?.DeliveryFee,
                ServiceFee = order?.ServiceFee,
            };
        }).ToList();
    }

    // ── Customer: Orders ──────────────────────────────────────────────────────

    public async Task<IReadOnlyList<ActiveOrderDto>> GetActiveOrdersAsync(
        string customerId, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(customerId))
            return Array.Empty<ActiveOrderDto>();

        // Find all request IDs belonging to this customer
        var requestIds = await _dbContext.ShoppingRequests.AsNoTracking()
            .Where(r => r.CustomerId == customerId)
            .Select(r => r.Id)
            .ToListAsync(cancellationToken);

        if (requestIds.Count == 0)
            return Array.Empty<ActiveOrderDto>();

        // Active = not yet Delivered (status < 5) and not Cancelled (6)
        var orders = await _dbContext.Orders.AsNoTracking()
            .Where(o => requestIds.Contains(o.RequestId)
                        && (int)o.Status < 5)
            .OrderByDescending(o => o.UpdatedAt)
            .ToListAsync(cancellationToken);

        if (orders.Count == 0)
            return Array.Empty<ActiveOrderDto>();

        // Gather request data for item counts and estimated totals
        var activeRequestIds = orders.Select(o => o.RequestId).Distinct().ToList();
        var requests = await _dbContext.ShoppingRequests.AsNoTracking()
            .Where(r => activeRequestIds.Contains(r.Id))
            .ToDictionaryAsync(r => r.Id, cancellationToken);

        // Gather item counts per order
        var orderIds = orders.Select(o => o.Id).ToList();
        var itemCounts = await _dbContext.OrderItems.AsNoTracking()
            .Where(i => orderIds.Contains(i.OrderId))
            .GroupBy(i => i.OrderId)
            .Select(g => new { OrderId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.OrderId, x => x.Count, cancellationToken);

        // Resolve store photos
        var storeNames = orders.Select(o => o.StoreName).Distinct().ToList();
        var markets = await _dbContext.Markets.AsNoTracking()
            .Where(m => storeNames.Contains(m.Name))
            .ToDictionaryAsync(m => m.Name, cancellationToken);

        return orders.Select(o =>
        {
            requests.TryGetValue(o.RequestId, out var req);
            itemCounts.TryGetValue(o.Id, out var totalItems);
            markets.TryGetValue(o.StoreName, out var market);

            var estimatedTotal = req?.Budget ?? 0m;

            return new ActiveOrderDto
            {
                Id = o.Id,
                RequestId = o.RequestId,
                ShopperName = o.ShopperName,
                StoreName = o.StoreName,
                StoreAddress = o.StoreAddress,
                Status = o.Status,
                ItemsSubtotal = o.ItemsSubtotal,
                EstimatedItemsTotal = estimatedTotal,
                DeliveryFee = o.DeliveryFee,
                ServiceFee = o.ServiceFee,
                PickedItemsCount = o.PickedItemsCount,
                TotalItemsCount = totalItems,
                EstimatedDeliveryMinutes = o.EstimatedDeliveryMinutes,
                UpdatedAt = o.UpdatedAt,
                StorePhotoUrl = market?.PhotoUrl,
            };
        }).ToList();
    }

    public async Task<bool> IsOrderOwnedByCustomerAsync(
        string orderId, string customerId, CancellationToken cancellationToken)
    {
        var requestId = await _dbContext.Orders.AsNoTracking()
            .Where(x => x.Id == orderId).Select(x => x.RequestId)
            .FirstOrDefaultAsync(cancellationToken);

        if (requestId is null) return false;

        return await _dbContext.ShoppingRequests.AsNoTracking()
            .AnyAsync(x => x.Id == requestId && x.CustomerId == customerId, cancellationToken);
    }

    public async Task<bool> CanAccessOrderChatAsync(
        string orderId, string userId, CancellationToken cancellationToken)
    {
        var order = await _dbContext.Orders.AsNoTracking()
            .Where(x => x.Id == orderId)
            .Select(x => new { x.ShopperId, x.RequestId })
            .FirstOrDefaultAsync(cancellationToken);

        if (order is null) return false;

        // Allow shopper assigned to the order
        if (order.ShopperId == userId) return true;

        // Allow the customer who owns the order
        return await _dbContext.ShoppingRequests.AsNoTracking()
            .AnyAsync(x => x.Id == order.RequestId && x.CustomerId == userId, cancellationToken);
    }

    public async Task<OrderTrackingDto?> GetOrderTrackingAsync(
        string orderId, CancellationToken cancellationToken)
    {
        var order = await _dbContext.Orders.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken);

        if (order is null) return null;

        var totalItems = await _dbContext.OrderItems.AsNoTracking()
            .CountAsync(x => x.OrderId == orderId, cancellationToken);

        var shopperAvatarUrl = order.ShopperId is not null
            ? await _dbContext.UserAccounts.AsNoTracking()
                .Where(x => x.Id == order.ShopperId)
                .Select(x => x.AvatarUrl)
                .FirstOrDefaultAsync(cancellationToken)
            : null;

        return BuildTrackingDto(order, totalItems, shopperAvatarUrl);
    }

    public async Task<IReadOnlyList<ActiveJobItemDto>> GetOrderItemsAsync(
        string orderId, CancellationToken cancellationToken)
    {
        var orderItems = await _dbContext.OrderItems.AsNoTracking()
            .Where(x => x.OrderId == orderId)
            .ToListAsync(cancellationToken);

        // Shopper has accepted — return live order items with pick status
        if (orderItems.Count > 0)
        {
            return orderItems.Select(i => new ActiveJobItemDto
            {
                Id = i.Id,
                Name = i.Name,
                Unit = i.Unit,
                Description = i.Description,
                Quantity = i.Quantity,
                EstimatedPrice = i.EstimatedPrice,
                FoundPrice = i.FoundPrice,
                Status = i.Status,
                PhotoUrl = i.PhotoUrl,
            }).ToList();
        }

        // No shopper yet — fall back to the original request items
        var requestId = await _dbContext.Orders.AsNoTracking()
            .Where(x => x.Id == orderId)
            .Select(x => x.RequestId)
            .FirstOrDefaultAsync(cancellationToken);

        if (requestId is null) return [];

        var request = await _dbContext.ShoppingRequests.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == requestId, cancellationToken);

        if (request is null) return [];

        return request.Items.Select((item, index) => new ActiveJobItemDto
        {
            Id = index,
            Name = item.Name,
            Unit = item.Unit,
            Description = item.Description,
            Quantity = item.Quantity,
            EstimatedPrice = item.Price,
            FoundPrice = null,
            Status = OrderItemStatus.Pending,
            PhotoUrl = null,
        }).ToList();
    }

    public async Task<OrderSummaryDto?> GetOrderSummaryAsync(
        string orderId, CancellationToken cancellationToken)
    {
        var order = await _dbContext.Orders.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken);

        if (order is null) return null;

        var request = await _dbContext.ShoppingRequests.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == order.RequestId, cancellationToken);

        var items = await _dbContext.OrderItems.AsNoTracking()
            .Where(x => x.OrderId == orderId && x.Status == OrderItemStatus.Found)
            .ToListAsync(cancellationToken);

        return new OrderSummaryDto
        {
            OrderId = order.Id,
            StoreName = order.StoreName,
            StoreAddress = order.StoreAddress,
            ShopperName = order.ShopperName,
            ShopperRating = 4.9m,
            DeliveryAddress = request?.DeliveryAddress ?? string.Empty,
            DeliveredAt = order.UpdatedAt,
            Items = items.Select(i => new OrderSummaryItemDto
            {
                Name = i.Name,
                Unit = i.Unit,
                Quantity = i.Quantity,
                Price = i.FoundPrice ?? i.EstimatedPrice,
                PhotoUrl = i.PhotoUrl
            }).ToList(),
            ItemsSubtotal = order.ItemsSubtotal,
            DeliveryFee = order.DeliveryFee,
            ServiceFee = order.ServiceFee,
            TotalPaid = order.ItemsSubtotal + order.DeliveryFee + order.ServiceFee
        };
    }

    public async Task<PaymentSummaryDto?> GetPaymentSummaryAsync(
        string orderId, CancellationToken cancellationToken)
    {
        var order = await _dbContext.Orders.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken);

        if (order is null) return null;

        var total = order.ItemsSubtotal + order.DeliveryFee + order.ServiceFee;
        var deposit = Math.Round(total * 0.3m, 2);

        return new PaymentSummaryDto
        {
            OrderId = order.Id,
            ItemsSubtotal = order.ItemsSubtotal,
            DeliveryFee = order.DeliveryFee,
            ServiceFee = order.ServiceFee,
            TotalAmount = total,
            DepositAmount = deposit,
            RemainingAmount = total - deposit
        };
    }

    // ── Shopper: Job management ───────────────────────────────────────────────

    public async Task<IReadOnlyList<ShoppingRequest>> GetAvailableRequestsAsync(
        CancellationToken cancellationToken)
    {
        var pendingRequestIds = await _dbContext.Orders.AsNoTracking()
            .Where(x => x.Status == OrderStatus.Pending && x.ShopperId == null)
            .Select(x => x.RequestId)
            .ToListAsync(cancellationToken);

        return await _dbContext.ShoppingRequests.AsNoTracking()
            .Where(x => pendingRequestIds.Contains(x.Id))
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync(cancellationToken);
    }

    public async Task<ActiveJobDto> AcceptRequestAsync(
        string requestId, AcceptRequestDto dto, CancellationToken cancellationToken)
    {
        var order = await _dbContext.Orders
            .FirstOrDefaultAsync(x => x.RequestId == requestId && x.Status == OrderStatus.Pending, cancellationToken)
            ?? throw new InvalidOperationException("Request is no longer available.");

        var request = await _dbContext.ShoppingRequests
            .FirstOrDefaultAsync(x => x.Id == requestId, cancellationToken)
            ?? throw new InvalidOperationException("Shopping request not found.");

        var shopper = await _dbContext.UserAccounts.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == dto.ShopperId, cancellationToken)
            ?? throw new InvalidOperationException("Shopper account not found.");

        order.ShopperId = dto.ShopperId;
        order.ShopperName = shopper.FullName;
        order.StoreName = dto.StoreName;
        order.StoreAddress = dto.StoreAddress;
        order.Status = OrderStatus.Accepted;
        order.EstimatedDeliveryMinutes = 45;
        order.UpdatedAt = DateTimeOffset.UtcNow;

        var customer = await _dbContext.UserAccounts.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == request.CustomerId, cancellationToken);

        // Delivery fee: distance from store to customer's saved location
        var market = await _dbContext.Markets.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Name.ToLower() == dto.StoreName.ToLower(), cancellationToken);
        order.DeliveryFee = CalculateDeliveryFee(
            market?.Latitude, market?.Longitude,
            customer?.Latitude, customer?.Longitude);

        var orderItems = request.Items.Select(item => new OrderItem
        {
            OrderId = order.Id,
            Name = item.Name,
            Unit = item.Unit,
            Description = item.Description,
            Quantity = item.Quantity,
            EstimatedPrice = item.Price,
            Status = OrderItemStatus.Pending,
            UpdatedAt = DateTimeOffset.UtcNow
        }).ToList();

        await _dbContext.OrderItems.AddRangeAsync(orderItems, cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return BuildActiveJobDto(order, request, shopper.FullName, customer?.FullName ?? string.Empty, customer?.AvatarUrl, orderItems);
    }

    public async Task<ActiveJobDto?> GetActiveJobAsync(
        string shopperId, CancellationToken cancellationToken)
    {
        var order = await _dbContext.Orders
            .Where(x =>
                x.ShopperId == shopperId &&
                x.Status != OrderStatus.Delivered &&
                x.Status != OrderStatus.Pending)
            .OrderByDescending(x => x.UpdatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (order is null) return null;

        var request = await _dbContext.ShoppingRequests.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == order.RequestId, cancellationToken);

        var customer = request is not null
            ? await _dbContext.UserAccounts.AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == request.CustomerId, cancellationToken)
            : null;

        var items = await _dbContext.OrderItems.AsNoTracking()
            .Where(x => x.OrderId == order.Id)
            .ToListAsync(cancellationToken);

        return BuildActiveJobDto(order, request, order.ShopperName, customer?.FullName ?? string.Empty, customer?.AvatarUrl, items);
    }

    public async Task<ActiveJobItemDto> UpdateOrderItemAsync(
        string orderId, int itemId, UpdateOrderItemDto dto, CancellationToken cancellationToken)
    {
        var item = await _dbContext.OrderItems
            .FirstOrDefaultAsync(x => x.OrderId == orderId && x.Id == itemId, cancellationToken)
            ?? throw new InvalidOperationException("Order item not found.");

        item.Status = dto.Status;
        item.FoundPrice = dto.FoundPrice;
        item.PhotoUrl = dto.PhotoUrl;
        item.UpdatedAt = DateTimeOffset.UtcNow;

        var order = await _dbContext.Orders.FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken);
        if (order is not null)
        {
            var allItems = await _dbContext.OrderItems
                .Where(x => x.OrderId == orderId)
                .ToListAsync(cancellationToken);

            order.ItemsSubtotal = allItems
                .Where(x => x.Status == OrderItemStatus.Found)
                .Sum(x => (x.FoundPrice ?? x.EstimatedPrice) * x.Quantity);

            order.PickedItemsCount = allItems.Count(x => x.Status == OrderItemStatus.Found);
            order.UpdatedAt = DateTimeOffset.UtcNow;
        }

        await _dbContext.SaveChangesAsync(cancellationToken);

        return new ActiveJobItemDto
        {
            Id = item.Id,
            Name = item.Name,
            Unit = item.Unit,
            Description = item.Description,
            Quantity = item.Quantity,
            EstimatedPrice = item.EstimatedPrice,
            FoundPrice = item.FoundPrice,
            Status = item.Status,
            PhotoUrl = item.PhotoUrl
        };
    }

    public async Task<Order> FinishShoppingAsync(
        string orderId, string shopperId, CancellationToken cancellationToken)
    {
        var order = await _dbContext.Orders
            .FirstOrDefaultAsync(x => x.Id == orderId && x.ShopperId == shopperId, cancellationToken)
            ?? throw new InvalidOperationException("Order not found or not assigned to this shopper.");

        // Calculate subtotal from actual found prices
        var items = await _dbContext.OrderItems.AsNoTracking()
            .Where(x => x.OrderId == orderId && x.Status == OrderItemStatus.Found)
            .ToListAsync(cancellationToken);

        var subtotal = items.Sum(i => i.FoundPrice ?? i.EstimatedPrice);
        order.ItemsSubtotal = subtotal;
        order.ShopperFee = CalculateShopperFee(subtotal);
        order.Status = OrderStatus.Purchased;
        order.UpdatedAt = DateTimeOffset.UtcNow;
        await _dbContext.SaveChangesAsync(cancellationToken);
        return order;
    }

    // ── Chat ──────────────────────────────────────────────────────────────────

    public async Task<IReadOnlyList<ChatMessage>> GetMessagesAsync(
        string orderId, CancellationToken cancellationToken)
    {
        return await _dbContext.ChatMessages.AsNoTracking()
            .Where(x => x.OrderId == orderId)
            .OrderBy(x => x.SentAt)
            .ToListAsync(cancellationToken);
    }

    public async Task<ChatMessage> SendMessageAsync(
        string orderId, SendChatMessageDto request, CancellationToken cancellationToken)
    {
        var message = new ChatMessage
        {
            Id = Guid.NewGuid().ToString("N"),
            OrderId = orderId,
            Sender = request.Sender,
            Type = request.Type,
            Text = request.Text,
            ImageUrl = request.ImageUrl,
            SentAt = DateTimeOffset.UtcNow
        };

        await _dbContext.ChatMessages.AddAsync(message, cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return message;
    }

    public async Task<ChatMessage> SendPriceCardAsync(
        string orderId, SendPriceCardDto dto, CancellationToken cancellationToken)
    {
        var message = new ChatMessage
        {
            Id = Guid.NewGuid().ToString("N"),
            OrderId = orderId,
            Sender = "shopper",
            Type = "price-card",
            Text = $"Price update for {dto.ItemName}: ₦{dto.NewPrice:N0} (was ₦{dto.OldPrice:N0})",
            PriceCard = new PriceCardData
            {
                ItemName = dto.ItemName,
                Quantity = dto.Quantity,
                OldPrice = dto.OldPrice,
                NewPrice = dto.NewPrice
            },
            SentAt = DateTimeOffset.UtcNow
        };

        await _dbContext.ChatMessages.AddAsync(message, cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return message;
    }

    public async Task<ChatMessage> ResolvePriceCardAsync(
        string orderId, ResolvePriceCardDto request, CancellationToken cancellationToken)
    {
        var note = request.Note?.Trim();
        var decisionText = request.Decision switch
        {
            PriceDecision.Accepted => "Accepted",
            PriceDecision.Negotiated => "Can we negotiate this price?",
            PriceDecision.Rejected => "Rejected",
            _ => "Pending"
        };

        var message = new ChatMessage
        {
            Id = Guid.NewGuid().ToString("N"),
            OrderId = orderId,
            Sender = "customer",
            Type = "text",
            Text = string.IsNullOrWhiteSpace(note) ? decisionText : $"{decisionText}: {note}",
            SentAt = DateTimeOffset.UtcNow
        };

        await _dbContext.ChatMessages.AddAsync(message, cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return message;
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private static OrderTrackingDto BuildTrackingDto(Order order, int totalItems, string? shopperAvatarUrl = null)
    {
        var (stepLabel, stepNumber) = order.Status switch
        {
            OrderStatus.Pending => ("Waiting for Shopper", 1),
            OrderStatus.Accepted => ("Shopper Assigned", 2),
            OrderStatus.Shopping => ("Picking Items", 3),
            OrderStatus.Purchased => ("Heading to You", 4),
            OrderStatus.OutForDelivery => ("Out for Delivery", 5),
            OrderStatus.Delivered => ("Delivered", 6),
            _ => ("Unknown", 1)
        };

        const int totalSteps = 6;
        var progress = (int)Math.Round((stepNumber / (double)totalSteps) * 100);

        return new OrderTrackingDto
        {
            OrderId = order.Id,
            RequestId = order.RequestId,
            ShopperName = order.ShopperName,
            ShopperAvatarUrl = shopperAvatarUrl,
            StoreName = order.StoreName,
            StoreAddress = order.StoreAddress,
            CurrentStatus = order.Status,
            StepLabel = stepLabel,
            StepNumber = stepNumber,
            TotalSteps = totalSteps,
            ProgressPercent = progress,
            PickedItemsCount = order.PickedItemsCount,
            TotalItemsCount = totalItems,
            EstimatedDeliveryMinutes = order.EstimatedDeliveryMinutes,
            Timeline =
            [
                OrderStatus.Pending, OrderStatus.Accepted, OrderStatus.Shopping,
                OrderStatus.Purchased, OrderStatus.OutForDelivery, OrderStatus.Delivered
            ]
        };
    }

    private static ActiveJobDto BuildActiveJobDto(
        Order order, ShoppingRequest? request, string shopperName, string customerName, string? customerAvatarUrl, IReadOnlyList<OrderItem> items)
    {
        return new ActiveJobDto
        {
            OrderId = order.Id,
            RequestId = order.RequestId,
            StoreName = order.StoreName,
            StoreAddress = order.StoreAddress,
            CustomerName = customerName,
            CustomerAvatarUrl = customerAvatarUrl,
            DeliveryAddress = request?.DeliveryAddress ?? string.Empty,
            DeliveryNotes = request?.DeliveryNotes ?? string.Empty,
            Status = order.Status,
            PickedItemsCount = items.Count(i => i.Status == OrderItemStatus.Found),
            TotalItemsCount = items.Count,
            EstimatedTotal = items.Sum(i => (i.FoundPrice ?? i.EstimatedPrice) * i.Quantity),
            ShopperFee = order.ShopperFee,
            DeliveryFee = order.DeliveryFee,
            ServiceFee = order.ServiceFee,
            Items = items.Select(i => new ActiveJobItemDto
            {
                Id = i.Id,
                Name = i.Name,
                Unit = i.Unit,
                Description = i.Description,
                Quantity = i.Quantity,
                EstimatedPrice = i.EstimatedPrice,
                FoundPrice = i.FoundPrice,
                Status = i.Status,
                PhotoUrl = i.PhotoUrl
            }).ToList()
        };
    }

    private static AuthenticatedUserDto MapToAuthDto(UserAccount user) => new()
    {
        UserId = user.Id,
        FullName = user.FullName,
        Email = user.Email,
        PhoneNumber = user.PhoneNumber,
        Role = user.Role,
        AvatarUrl = user.AvatarUrl,
        CreatedAt = user.CreatedAt
    };

    private async Task<SignupOtpChallengeDto> RegisterAsync(
        RegisterUserDto request, UserRole role, CancellationToken cancellationToken)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var normalizedPhone = request.PhoneNumber.Trim();

        if (await _dbContext.UserAccounts.AsNoTracking().AnyAsync(x => x.Email == normalizedEmail, cancellationToken))
            throw new InvalidOperationException("An account with this email already exists.");

        if (await _dbContext.UserAccounts.AsNoTracking().AnyAsync(x => x.PhoneNumber == normalizedPhone, cancellationToken))
            throw new InvalidOperationException("An account with this phone number already exists.");

        var salt = GenerateSalt();
        var hash = HashPassword(request.Password, salt);

        var user = new UserAccount
        {
            Id = $"USR-{Guid.NewGuid():N}"[..20],
            FullName = request.FullName.Trim(),
            Email = normalizedEmail,
            PhoneNumber = normalizedPhone,
            PasswordSalt = Convert.ToBase64String(salt),
            PasswordHash = Convert.ToBase64String(hash),
            Role = role,
            IsActive = false,
            CreatedAt = DateTimeOffset.UtcNow
        };

        await _dbContext.UserAccounts.AddAsync(user, cancellationToken);
        var challenge = await CreateOtpChallengeAsync(user, cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);
        await SendSignupOtpEmailAsync(user, challenge, cancellationToken);
        return challenge;
    }

    private async Task<SignupOtpChallengeDto> CreateOtpChallengeAsync(
        UserAccount user, CancellationToken cancellationToken)
    {
        var otpCode = GenerateOtpCode();
        var otpExpiresAt = DateTimeOffset.UtcNow.Add(OtpTtl);

        var verification = new SignupOtpVerification
        {
            Id = $"OTP-{Guid.NewGuid():N}"[..20],
            UserId = user.Id,
            CodeHash = ComputeOtpHash(otpCode),
            ExpiresAt = otpExpiresAt,
            CreatedAt = DateTimeOffset.UtcNow,
            FailedAttempts = 0
        };

        await _dbContext.SignupOtpVerifications.AddAsync(verification, cancellationToken);

        return new SignupOtpChallengeDto
        {
            UserId = user.Id,
            Email = user.Email,
            PhoneNumber = user.PhoneNumber,
            Role = user.Role,
            ExpiresAt = otpExpiresAt,
            DevelopmentOtpCode = otpCode
        };
    }

    private static byte[] GenerateSalt() => RandomNumberGenerator.GetBytes(16);

    private static byte[] HashPassword(string password, byte[] salt) =>
        Rfc2898DeriveBytes.Pbkdf2(password, salt, 100_000, HashAlgorithmName.SHA256, 32);

    private static string GenerateOtpCode() =>
        RandomNumberGenerator.GetInt32(1000, 10000).ToString();

    private static string ComputeOtpHash(string otpCode) =>
        Convert.ToBase64String(SHA256.HashData(Encoding.UTF8.GetBytes(otpCode)));

    private static bool FixedTimeEqualsBase64(string leftBase64, string rightBase64)
    {
        var left = Convert.FromBase64String(leftBase64);
        var right = Convert.FromBase64String(rightBase64);
        return CryptographicOperations.FixedTimeEquals(left, right);
    }

    private Task SendSignupOtpEmailAsync(
        UserAccount user, SignupOtpChallengeDto challenge, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(challenge.DevelopmentOtpCode))
            throw new InvalidOperationException("OTP code was not generated.");

        return _emailService.SendSignupOtpAsync(
            user.Email, user.FullName,
            challenge.DevelopmentOtpCode, challenge.ExpiresAt,
            cancellationToken);
    }

    // ── Admin ─────────────────────────────────────────────────────────────────

    public async Task<AdminDashboardDto> GetAdminDashboardAsync(CancellationToken ct)
    {
        var today = DateTimeOffset.UtcNow.Date;
        var todayStart = new DateTimeOffset(today, TimeSpan.Zero);
        var todayEnd = todayStart.AddDays(1);
        var monthStart = new DateTimeOffset(today.Year, today.Month, 1, 0, 0, 0, TimeSpan.Zero);

        var ordersToday = await _dbContext.Orders.AsNoTracking()
            .Where(x => x.UpdatedAt >= todayStart && x.UpdatedAt < todayEnd)
            .ToListAsync(ct);

        var activeOrders = await _dbContext.Orders.AsNoTracking()
            .CountAsync(x => x.Status != OrderStatus.Delivered, ct);

        var completedToday = ordersToday.Count(x => x.Status == OrderStatus.Delivered);

        var activeShoppers = await _dbContext.UserAccounts.AsNoTracking()
            .CountAsync(x => x.Role == UserRole.Shopper && x.IsActive, ct);

        var totalShoppers = await _dbContext.UserAccounts.AsNoTracking()
            .CountAsync(x => x.Role == UserRole.Shopper, ct);

        var totalCustomers = await _dbContext.UserAccounts.AsNoTracking()
            .CountAsync(x => x.Role == UserRole.Customer, ct);

        var revenueToday = ordersToday.Sum(x => x.ServiceFee);
        var ordersThisMonth = await _dbContext.Orders.AsNoTracking()
            .Where(x => x.UpdatedAt >= monthStart)
            .SumAsync(x => x.ServiceFee, ct);

        var recentOrders = await _dbContext.Orders.AsNoTracking()
            .OrderByDescending(x => x.UpdatedAt)
            .Take(10)
            .ToListAsync(ct);

        var requestIds = recentOrders.Select(x => x.RequestId).Distinct().ToList();
        var requests = await _dbContext.ShoppingRequests.AsNoTracking()
            .Where(x => requestIds.Contains(x.Id))
            .ToDictionaryAsync(x => x.Id, ct);

        var customerIds = requests.Values.Select(x => x.CustomerId).Distinct().ToList();
        var customers = await _dbContext.UserAccounts.AsNoTracking()
            .Where(x => customerIds.Contains(x.Id))
            .ToDictionaryAsync(x => x.Id, ct);

        var recentOrderDtos = recentOrders.Select(o =>
        {
            requests.TryGetValue(o.RequestId, out var req);
            var customerId = req?.CustomerId ?? "";
            customers.TryGetValue(customerId, out var cust);
            var name = cust?.FullName ?? "Unknown";
            return new AdminRecentOrderDto
            {
                OrderId = o.Id,
                CustomerName = name,
                CustomerInitials = ToInitials(name),
                CustomerLocation = req?.DeliveryAddress ?? "",
                ShopperName = o.ShopperId is not null ? o.ShopperName : null,
                StoreName = o.StoreName,
                MarketIcon = "storefront",
                Status = o.Status,
                Total = o.TotalAmount,
                UpdatedAt = o.UpdatedAt
            };
        }).ToList();

        // Build last-6-month chart
        var chart = new List<AdminMonthlyStatDto>();
        for (int i = 5; i >= 0; i--)
        {
            var mStart = monthStart.AddMonths(-i);
            var mEnd = mStart.AddMonths(1);
            var mOrders = await _dbContext.Orders.AsNoTracking()
                .Where(x => x.UpdatedAt >= mStart && x.UpdatedAt < mEnd)
                .ToListAsync(ct);
            chart.Add(new AdminMonthlyStatDto
            {
                Month = mStart.ToString("MMM"),
                Revenue = mOrders.Sum(x => x.TotalAmount),
                Payouts = mOrders.Sum(x => x.ItemsSubtotal + x.DeliveryFee)
            });
        }

        return new AdminDashboardDto
        {
            TotalOrdersToday = ordersToday.Count,
            ActiveOrders = activeOrders,
            CompletedOrdersToday = completedToday,
            ActiveShoppers = activeShoppers,
            TotalShoppers = totalShoppers,
            TotalCustomers = totalCustomers,
            RevenueToday = revenueToday,
            RevenueThisMonth = ordersThisMonth,
            PlatformFeesToday = revenueToday,
            AvgWaitTimeMinutes = 0,
            RecentOrders = recentOrderDtos,
            MonthlyChart = chart
        };
    }

    public async Task<PagedResult<AdminOrderDto>> GetAdminOrdersAsync(
        string? status, int page, int pageSize, CancellationToken ct)
    {
        var query = _dbContext.Orders.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(status) &&
            Enum.TryParse<OrderStatus>(status, ignoreCase: true, out var parsed))
        {
            query = query.Where(x => x.Status == parsed);
        }

        var total = await query.CountAsync(ct);
        var orders = await query
            .OrderByDescending(x => x.UpdatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        var requestIds = orders.Select(x => x.RequestId).Distinct().ToList();
        var requests = await _dbContext.ShoppingRequests.AsNoTracking()
            .Where(x => requestIds.Contains(x.Id))
            .ToDictionaryAsync(x => x.Id, ct);

        var customerIds = requests.Values.Select(x => x.CustomerId).Distinct().ToList();
        var customers = await _dbContext.UserAccounts.AsNoTracking()
            .Where(x => customerIds.Contains(x.Id))
            .ToDictionaryAsync(x => x.Id, ct);

        var dtos = orders.Select(o =>
        {
            requests.TryGetValue(o.RequestId, out var req);
            customers.TryGetValue(req?.CustomerId ?? "", out var cust);
            var name = cust?.FullName ?? "Unknown";
            return new AdminOrderDto
            {
                OrderId = o.Id,
                CustomerName = name,
                CustomerInitials = ToInitials(name),
                CustomerLocation = req?.DeliveryAddress ?? "",
                ShopperName = o.ShopperId is not null ? o.ShopperName : null,
                ShopperTier = null,
                StoreName = o.StoreName,
                MarketIcon = "storefront",
                Status = o.Status,
                Total = o.TotalAmount,
                UpdatedAt = o.UpdatedAt
            };
        }).ToList();

        return new PagedResult<AdminOrderDto>
        {
            Items = dtos,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<AdminOrderDto?> GetAdminOrderAsync(string orderId, CancellationToken ct)
    {
        var o = await _dbContext.Orders.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == orderId, ct);
        if (o is null) return null;

        var req = await _dbContext.ShoppingRequests.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == o.RequestId, ct);
        var cust = req is not null
            ? await _dbContext.UserAccounts.AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == req.CustomerId, ct)
            : null;

        var name = cust?.FullName ?? "Unknown";
        return new AdminOrderDto
        {
            OrderId = o.Id,
            CustomerName = name,
            CustomerInitials = ToInitials(name),
            CustomerLocation = req?.DeliveryAddress ?? "",
            ShopperName = o.ShopperId is not null ? o.ShopperName : null,
            ShopperTier = null,
            StoreName = o.StoreName,
            MarketIcon = "storefront",
            Status = o.Status,
            Total = o.TotalAmount,
            UpdatedAt = o.UpdatedAt
        };
    }

    public async Task<Order> UpdateAdminOrderStatusAsync(
        string orderId, UpdateOrderStatusDto dto, CancellationToken ct)
    {
        var order = await _dbContext.Orders.FirstOrDefaultAsync(x => x.Id == orderId, ct)
            ?? throw new KeyNotFoundException($"Order {orderId} not found.");
        order.Status = dto.Status;
        order.UpdatedAt = DateTimeOffset.UtcNow;
        await _dbContext.SaveChangesAsync(ct);
        return order;
    }

    public async Task<PagedResult<AdminShopperDto>> GetAdminShoppersAsync(
        string tab, int page, int pageSize, CancellationToken ct)
    {
        var query = _dbContext.UserAccounts.AsNoTracking()
            .Where(x => x.Role == UserRole.Shopper);

        if (tab == "pending")
            query = query.Where(x => !x.IsActive);

        var total = await query.CountAsync(ct);
        var shoppers = await query
            .OrderByDescending(x => x.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        var shopperIds = shoppers.Select(x => x.Id).ToList();
        var completedCounts = await _dbContext.Orders.AsNoTracking()
            .Where(x => shopperIds.Contains(x.ShopperId!) && x.Status == OrderStatus.Delivered)
            .GroupBy(x => x.ShopperId!)
            .Select(g => new { ShopperId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.ShopperId, x => x.Count, ct);

        var monthStart = new DateTimeOffset(DateTimeOffset.UtcNow.Year, DateTimeOffset.UtcNow.Month, 1, 0, 0, 0, TimeSpan.Zero);
        var monthCounts = await _dbContext.Orders.AsNoTracking()
            .Where(x => shopperIds.Contains(x.ShopperId!) && x.UpdatedAt >= monthStart)
            .GroupBy(x => x.ShopperId!)
            .Select(g => new { ShopperId = g.Key, Count = g.Count(), Earnings = g.Sum(o => o.DeliveryFee) })
            .ToDictionaryAsync(x => x.ShopperId, ct);

        var dtos = shoppers.Select(s =>
        {
            completedCounts.TryGetValue(s.Id, out var completed);
            monthCounts.TryGetValue(s.Id, out var month);
            return new AdminShopperDto
            {
                ShopperId = s.Id,
                FullName = s.FullName,
                Initials = ToInitials(s.FullName),
                Email = s.Email,
                PhoneNumber = s.PhoneNumber,
                IsOnline = false,
                IsVerified = s.IsActive,
                IsActive = s.IsActive,
                Tier = completed >= 50 ? "PRO SHOPPER" : "BASIC",
                Rating = 4.5m,
                CompletedOrders = completed,
                OrdersThisMonth = month?.Count ?? 0,
                EarningsThisMonth = month?.Earnings ?? 0m,
                JoinedAt = s.CreatedAt,
                LastActiveAt = null
            };
        }).ToList();

        return new PagedResult<AdminShopperDto>
        {
            Items = dtos,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task UpdateAdminShopperStatusAsync(
        string shopperId, UpdateUserStatusDto dto, CancellationToken ct)
    {
        var user = await _dbContext.UserAccounts
            .FirstOrDefaultAsync(x => x.Id == shopperId && x.Role == UserRole.Shopper, ct)
            ?? throw new KeyNotFoundException($"Shopper {shopperId} not found.");
        user.IsActive = dto.IsActive;
        await _dbContext.SaveChangesAsync(ct);
    }

    public async Task<PagedResult<AdminCustomerDto>> GetAdminCustomersAsync(
        string? membership, string? status, int page, int pageSize, CancellationToken ct)
    {
        var query = _dbContext.UserAccounts.AsNoTracking()
            .Where(x => x.Role == UserRole.Customer);

        if (!string.IsNullOrWhiteSpace(status))
        {
            var isActive = status.Equals("active", StringComparison.OrdinalIgnoreCase);
            query = query.Where(x => x.IsActive == isActive);
        }

        var total = await query.CountAsync(ct);
        var custs = await query
            .OrderByDescending(x => x.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        var custIds = custs.Select(x => x.Id).ToList();
        var orderStats = await _dbContext.ShoppingRequests.AsNoTracking()
            .Where(x => custIds.Contains(x.CustomerId))
            .GroupBy(x => x.CustomerId)
            .Select(g => new { CustomerId = g.Key, Count = g.Count(), Latest = g.Max(r => r.CreatedAt) })
            .ToDictionaryAsync(x => x.CustomerId, ct);

        var spend = await _dbContext.Orders.AsNoTracking()
            .Join(_dbContext.ShoppingRequests, o => o.RequestId, r => r.Id,
                (o, r) => new { r.CustomerId, Amount = o.ItemsSubtotal + o.DeliveryFee + o.ServiceFee })
            .Where(x => custIds.Contains(x.CustomerId))
            .GroupBy(x => x.CustomerId)
            .Select(g => new { CustomerId = g.Key, Total = g.Sum(x => x.Amount) })
            .ToDictionaryAsync(x => x.CustomerId, x => x.Total, ct);

        var avatarBgs = new[] { "bg-purple-100", "bg-blue-100", "bg-green-100", "bg-yellow-100", "bg-pink-100" };
        var avatarTexts = new[] { "text-purple-700", "text-blue-700", "text-green-700", "text-yellow-700", "text-pink-700" };

        var dtos = custs.Select((c, idx) =>
        {
            orderStats.TryGetValue(c.Id, out var stats);
            spend.TryGetValue(c.Id, out var totalSpend);
            return new AdminCustomerDto
            {
                CustomerId = c.Id,
                FullName = c.FullName,
                Initials = ToInitials(c.FullName),
                AvatarBg = avatarBgs[idx % avatarBgs.Length],
                AvatarText = avatarTexts[idx % avatarTexts.Length],
                Email = c.Email,
                TotalOrders = stats?.Count ?? 0,
                LastOrderAt = stats?.Latest,
                TotalSpend = totalSpend,
                Membership = "Basic",
                IsActive = c.IsActive,
                JoinedAt = c.CreatedAt
            };
        }).ToList();

        return new PagedResult<AdminCustomerDto>
        {
            Items = dtos,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task UpdateAdminCustomerStatusAsync(
        string customerId, UpdateUserStatusDto dto, CancellationToken ct)
    {
        var user = await _dbContext.UserAccounts
            .FirstOrDefaultAsync(x => x.Id == customerId && x.Role == UserRole.Customer, ct)
            ?? throw new KeyNotFoundException($"Customer {customerId} not found.");
        user.IsActive = dto.IsActive;
        await _dbContext.SaveChangesAsync(ct);
    }

    public async Task<AdminEarningsSummaryDto> GetAdminEarningsSummaryAsync(CancellationToken ct)
    {
        var allOrders = await _dbContext.Orders.AsNoTracking().ToListAsync(ct);
        var totalRevenue = allOrders.Sum(x => x.TotalAmount);
        var shopperPayouts = allOrders.Sum(x => x.ItemsSubtotal + x.DeliveryFee);
        var platformFees = allOrders.Sum(x => x.ServiceFee);
        var margin = totalRevenue > 0 ? Math.Round(platformFees / totalRevenue * 100, 1) : 0m;

        var now = DateTimeOffset.UtcNow;
        var chart = new List<AdminMonthlyStatDto>();
        for (int i = 5; i >= 0; i--)
        {
            var mStart = new DateTimeOffset(now.Year, now.Month, 1, 0, 0, 0, TimeSpan.Zero).AddMonths(-i);
            var mEnd = mStart.AddMonths(1);
            var mOrders = allOrders.Where(x => x.UpdatedAt >= mStart && x.UpdatedAt < mEnd).ToList();
            chart.Add(new AdminMonthlyStatDto
            {
                Month = mStart.ToString("MMM"),
                Revenue = mOrders.Sum(x => x.TotalAmount),
                Payouts = mOrders.Sum(x => x.ItemsSubtotal + x.DeliveryFee)
            });
        }

        return new AdminEarningsSummaryDto
        {
            TotalRevenue = totalRevenue,
            ShopperPayouts = shopperPayouts,
            PlatformFees = platformFees,
            PlatformMarginPercent = margin,
            NextPayoutCycle = "1st of next month",
            MonthlyChart = chart
        };
    }

    public Task<PagedResult<AdminPayoutDto>> GetAdminPayoutsAsync(int page, int pageSize, CancellationToken ct)
    {
        // Payouts are not tracked in the DB yet — return empty paged result
        return Task.FromResult(new PagedResult<AdminPayoutDto>
        {
            Items = [],
            TotalCount = 0,
            Page = page,
            PageSize = pageSize
        });
    }

    public async Task<PagedResult<AdminMarketDto>> GetAdminMarketsAsync(
        string? type, string? status, int page, int pageSize, CancellationToken ct)
    {
        var query = _dbContext.Markets.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(type))
            query = query.Where(x => x.Type == type);

        if (!string.IsNullOrWhiteSpace(status))
        {
            var isActive = status.Equals("active", StringComparison.OrdinalIgnoreCase);
            query = query.Where(x => x.IsActive == isActive);
        }

        var total = await query.CountAsync(ct);
        var markets = await query
            .OrderBy(x => x.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        var dtos = markets.Select(ToMarketDto).ToList();

        return new PagedResult<AdminMarketDto>
        {
            Items = dtos,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<AdminMarketDto> CreateAdminMarketAsync(CreateMarketDto dto, CancellationToken ct)
    {
        var market = new Market
        {
            Id = Guid.NewGuid().ToString("N")[..20],
            Name = dto.Name.Trim(),
            Type = dto.Type.Trim(),
            Address = dto.Address?.Trim() ?? "",
            Location = dto.Location?.Trim() ?? "",
            Zone = dto.Zone?.Trim() ?? "",
            IsActive = dto.IsActive,
            Categories = dto.Categories?.ToList() ?? [],
            OpeningTime = dto.OpeningTime ?? "08:00",
            ClosingTime = dto.ClosingTime ?? "20:00",
            GeofenceRadiusKm = dto.GeofenceRadiusKm,
            PhotoUrl = dto.PhotoUrl,
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };
        _dbContext.Markets.Add(market);
        await _dbContext.SaveChangesAsync(ct);
        return ToMarketDto(market);
    }

    public async Task<AdminMarketDto?> UpdateAdminMarketAsync(
        string marketId, CreateMarketDto dto, CancellationToken ct)
    {
        var market = await _dbContext.Markets.FirstOrDefaultAsync(x => x.Id == marketId, ct);
        if (market is null) return null;

        market.Name = dto.Name.Trim();
        market.Type = dto.Type.Trim();
        market.Address = dto.Address?.Trim() ?? market.Address;
        market.Location = dto.Location?.Trim() ?? market.Location;
        market.Zone = dto.Zone?.Trim() ?? market.Zone;
        market.IsActive = dto.IsActive;
        market.Categories = dto.Categories?.ToList() ?? market.Categories;
        market.OpeningTime = dto.OpeningTime ?? market.OpeningTime;
        market.ClosingTime = dto.ClosingTime ?? market.ClosingTime;
        market.GeofenceRadiusKm = dto.GeofenceRadiusKm;
        if (dto.PhotoUrl is not null) market.PhotoUrl = dto.PhotoUrl;
        if (dto.Latitude.HasValue) market.Latitude = dto.Latitude.Value;
        if (dto.Longitude.HasValue) market.Longitude = dto.Longitude.Value;
        market.UpdatedAt = DateTimeOffset.UtcNow;

        await _dbContext.SaveChangesAsync(ct);
        return ToMarketDto(market);
    }

    public async Task<bool> DeleteAdminMarketAsync(string marketId, CancellationToken ct)
    {
        var market = await _dbContext.Markets.FirstOrDefaultAsync(x => x.Id == marketId, ct);
        if (market is null) return false;
        _dbContext.Markets.Remove(market);
        await _dbContext.SaveChangesAsync(ct);
        return true;
    }

    public async Task<IReadOnlyList<AdminUserDto>> GetAdminUsersAsync(CancellationToken ct)
    {
        var admins = await _dbContext.UserAccounts.AsNoTracking()
            .Where(x => x.Role == UserRole.Admin)
            .OrderBy(x => x.FullName)
            .ToListAsync(ct);

        return admins.Select(u => new AdminUserDto
        {
            UserId = u.Id,
            FullName = u.FullName,
            Initials = ToInitials(u.FullName),
            Email = u.Email,
            PhoneNumber = u.PhoneNumber,
            AdminRole = "SuperAdmin",
            IsActive = u.IsActive,
            ForcePasswordReset = false,
            CreatedAt = u.CreatedAt
        }).ToList();
    }

    public async Task<AdminUserDto> CreateAdminUserAsync(CreateAdminUserDto dto, CancellationToken ct)
    {
        var salt = GenerateSalt();
        var hash = HashPassword(dto.TemporaryPassword, salt);

        var user = new UserAccount
        {
            Id = Guid.NewGuid().ToString("N")[..20],
            FullName = dto.FullName.Trim(),
            Email = dto.Email.Trim().ToLowerInvariant(),
            PhoneNumber = dto.PhoneNumber.Trim(),
            PasswordHash = Convert.ToBase64String(hash),
            PasswordSalt = Convert.ToBase64String(salt),
            Role = UserRole.Admin,
            IsActive = true,
            CreatedAt = DateTimeOffset.UtcNow
        };
        _dbContext.UserAccounts.Add(user);
        await _dbContext.SaveChangesAsync(ct);

        return new AdminUserDto
        {
            UserId = user.Id,
            FullName = user.FullName,
            Initials = ToInitials(user.FullName),
            Email = user.Email,
            PhoneNumber = user.PhoneNumber,
            AdminRole = dto.AdminRole ?? "SuperAdmin",
            IsActive = true,
            ForcePasswordReset = dto.ForcePasswordReset,
            CreatedAt = user.CreatedAt
        };
    }

    public async Task UpdateUserLocationAsync(string userId, double latitude, double longitude, CancellationToken cancellationToken)
    {
        var user = await _dbContext.UserAccounts.FindAsync([userId], cancellationToken);
        if (user is null) return;
        user.Latitude = latitude;
        user.Longitude = longitude;
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<MarketDto>> GetPublicMarketsAsync(string? type, CancellationToken cancellationToken)
    {
        var query = _dbContext.Markets.Where(m => m.IsActive);
        if (!string.IsNullOrWhiteSpace(type))
            query = query.Where(m => m.Type == type);

        var markets = await query.OrderBy(m => m.Name).ToListAsync(cancellationToken);
        return markets.Select(m => new MarketDto
        {
            MarketId = m.Id,
            Name = m.Name,
            Type = m.Type,
            Address = m.Address,
            Location = m.Location,
            Categories = m.Categories,
            OpeningTime = m.OpeningTime,
            ClosingTime = m.ClosingTime,
            GeofenceRadiusKm = m.GeofenceRadiusKm,
            PhotoUrl = m.PhotoUrl,
            Latitude = m.Latitude,
            Longitude = m.Longitude,
        }).ToList();
    }

    private static AdminMarketDto ToMarketDto(Market m) => new()
    {
        MarketId = m.Id,
        Name = m.Name,
        Type = m.Type,
        Location = m.Location,
        Zone = m.Zone,
        Address = m.Address,
        IsActive = m.IsActive,
        Categories = m.Categories,
        OpeningTime = m.OpeningTime,
        ClosingTime = m.ClosingTime,
        GeofenceRadiusKm = m.GeofenceRadiusKm,
        PhotoUrl = m.PhotoUrl,
        Latitude = m.Latitude,
        Longitude = m.Longitude,
        ActiveShoppers = 0,
        OrdersToday = 0,
        CreatedAt = m.CreatedAt
    };

    private static string ToInitials(string name)
    {
        var parts = name.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries);
        return parts.Length >= 2
            ? $"{parts[0][0]}{parts[^1][0]}".ToUpperInvariant()
            : name.Length >= 2 ? name[..2].ToUpperInvariant() : name.ToUpperInvariant();
    }

    public async Task<IReadOnlyList<ShopperOrderHistoryDto>> GetShopperOrderHistoryAsync(
        string shopperId, CancellationToken ct)
    {
        var orders = await _dbContext.Orders.AsNoTracking()
            .Where(o => o.ShopperId == shopperId &&
                        o.Status == OrderStatus.Delivered)
            .OrderByDescending(o => o.UpdatedAt)
            .Take(50)
            .ToListAsync(ct);

        if (orders.Count == 0) return [];

        var requestIds = orders.Select(o => o.RequestId).ToList();
        var requests = await _dbContext.ShoppingRequests.AsNoTracking()
            .Where(r => requestIds.Contains(r.Id))
            .ToListAsync(ct);

        var customerIds = requests.Select(r => r.CustomerId).Distinct().ToList();
        var customers = await _dbContext.UserAccounts.AsNoTracking()
            .Where(u => customerIds.Contains(u.Id))
            .Select(u => new { u.Id, u.FullName })
            .ToDictionaryAsync(u => u.Id, u => u.FullName, ct);

        var reqDict = requests.ToDictionary(r => r.Id);

        return orders.Select(o =>
        {
            var req = reqDict.GetValueOrDefault(o.RequestId);
            var customerName = req != null
                ? customers.GetValueOrDefault(req.CustomerId, "Customer")
                : "Customer";
            return new ShopperOrderHistoryDto
            {
                OrderId = o.Id,
                StoreName = o.StoreName,
                CustomerName = customerName,
                CompletedAt = o.UpdatedAt,
                EarningsAmount = o.DeliveryFee,
                Status = (int)o.Status,
                ItemsCount = req?.Items.Count ?? 0,
            };
        }).ToList();
    }
}
