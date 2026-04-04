using SwiftShopper.Application.Abstractions;
using SwiftShopper.Application.Contracts.Requests;
using SwiftShopper.Application.Contracts.Responses;
using SwiftShopper.Domain.Entities;
using SwiftShopper.Domain.Enums;

namespace SwiftShopper.Infrastructure.Services;

public class InMemorySwiftShopperService : ISwiftShopperService
{
    private readonly Dictionary<string, (string otp, string email, string phone, UserRole role)> _pendingSignupOtps = new(StringComparer.OrdinalIgnoreCase);
    private readonly List<ShoppingRequest> _requests = [];
    private readonly List<Order> _orders = [];
    private readonly List<OrderItem> _orderItems = [];
    private readonly List<ChatMessage> _messages = [];

    // ── Admin seed data ───────────────────────────────────────────────────────
    private readonly List<AdminShopperSeed> _shoppers = [];
    private readonly List<AdminCustomerSeed> _customers = [];
    private readonly List<Market> _markets = [];
    private readonly List<AdminPayoutDto> _payouts = [];
    private readonly List<AdminUserDto> _adminUsers = [];

    // Internal seed records (not exposed via DTOs directly)
    private record AdminShopperSeed(
        string Id, string FullName, string Email, string Phone,
        bool IsOnline, bool IsVerified, bool IsActive,
        string Tier, decimal Rating, int CompletedOrders,
        int OrdersThisMonth, decimal EarningsThisMonth, DateTimeOffset JoinedAt);

    private record AdminCustomerSeed(
        string Id, string FullName, string Email,
        int TotalOrders, DateTimeOffset? LastOrderAt, decimal TotalSpend,
        string Membership, bool IsActive, DateTimeOffset JoinedAt);

    private const decimal DeliveryFeeFixed = 1200m;
    private const decimal ServiceFeeFixed = 350m;

    public InMemorySwiftShopperService()
    {
        SeedAdminData();
        var seedRequest = new ShoppingRequest
        {
            Id = "REQ-1001",
            CustomerId = "customer-demo",
            PreferredStore = "FreshMart",
            MarketType = MarketType.Supermarket,
            Budget = 12000m,
            DeliveryAddress = "12 Palm Avenue, Lagos",
            DeliveryNotes = "Call on arrival",
            Items =
            [
                new RequestItem { Name = "Tomatoes", Quantity = 4, MaxPrice = 500m, Unit = "pieces" },
                new RequestItem { Name = "Olive Oil", Quantity = 1, MaxPrice = 3500m, Unit = "bottle" }
            ],
            CreatedAt = DateTimeOffset.UtcNow.AddHours(-3)
        };
        _requests.Add(seedRequest);

        var seedOrder = new Order
        {
            Id = "ORD-9001",
            RequestId = seedRequest.Id,
            ShopperId = "shopper-demo",
            ShopperName = "Amina Yusuf",
            StoreName = "FreshMart Lekki",
            StoreAddress = "4 Admiralty Way, Lekki Phase 1",
            Status = OrderStatus.Shopping,
            ItemsSubtotal = 3800m,
            DeliveryFee = DeliveryFeeFixed,
            ServiceFee = ServiceFeeFixed,
            EstimatedDeliveryMinutes = 25,
            PickedItemsCount = 1,
            UpdatedAt = DateTimeOffset.UtcNow.AddMinutes(-10)
        };
        _orders.Add(seedOrder);

        _orderItems.AddRange(
        [
            new OrderItem
            {
                Id = 1,
                OrderId = seedOrder.Id,
                Name = "Tomatoes",
                Unit = "pieces",
                Quantity = 4,
                EstimatedPrice = 500m,
                FoundPrice = 450m,
                Status = OrderItemStatus.Found,
                UpdatedAt = DateTimeOffset.UtcNow.AddMinutes(-8)
            },
            new OrderItem
            {
                Id = 2,
                OrderId = seedOrder.Id,
                Name = "Olive Oil",
                Unit = "bottle",
                Quantity = 1,
                EstimatedPrice = 3500m,
                Status = OrderItemStatus.Pending,
                UpdatedAt = DateTimeOffset.UtcNow.AddMinutes(-10)
            }
        ]);

        _messages.AddRange(
        [
            new ChatMessage
            {
                Id = "MSG-1",
                OrderId = seedOrder.Id,
                Sender = "shopper",
                Type = "text",
                Text = "Hi! I started shopping for your request.",
                SentAt = DateTimeOffset.UtcNow.AddMinutes(-15)
            },
            new ChatMessage
            {
                Id = "MSG-2",
                OrderId = seedOrder.Id,
                Sender = "customer",
                Type = "text",
                Text = "Great, please prioritize fresh items.",
                SentAt = DateTimeOffset.UtcNow.AddMinutes(-13)
            }
        ]);
    }

    public Task<AuthenticatedUserDto?> LoginAsync(
        LoginUserDto request,
        CancellationToken cancellationToken)
    {
        var identity = request.EmailOrPhoneNumber.Trim();
        var normalizedEmail = identity.ToLowerInvariant();

        if (request.Password != "password123")
        {
            return Task.FromResult<AuthenticatedUserDto?>(null);
        }

        var role = normalizedEmail.Contains("shopper")
            ? UserRole.Shopper
            : UserRole.Customer;

        var user = new AuthenticatedUserDto
        {
            UserId = "USR-DEMO-LOGIN",
            FullName = role == UserRole.Shopper ? "Demo Shopper" : "Demo Customer",
            Email = normalizedEmail.Contains('@') ? normalizedEmail : "demo@swiftshopper.app",
            PhoneNumber = normalizedEmail.Contains('@') ? "+2348000000000" : identity,
            Role = role,
            CreatedAt = DateTimeOffset.UtcNow.AddDays(-1)
        };

        return Task.FromResult<AuthenticatedUserDto?>(user);
    }

    public Task<SignupOtpChallengeDto> RegisterCustomerAsync(
        RegisterUserDto request,
        CancellationToken cancellationToken)
    {
        var userId = $"USR-{Guid.NewGuid():N}"[..20];
        const string otpCode = "1234";
        _pendingSignupOtps[userId] = (otpCode, request.Email, request.PhoneNumber, UserRole.Customer);

        return Task.FromResult(new SignupOtpChallengeDto
        {
            UserId = userId,
            Email = request.Email,
            PhoneNumber = request.PhoneNumber,
            Role = UserRole.Customer,
            ExpiresAt = DateTimeOffset.UtcNow.AddMinutes(10),
            DevelopmentOtpCode = otpCode
        });
    }

    public Task<SignupOtpChallengeDto> RegisterShopperAsync(
        RegisterUserDto request,
        CancellationToken cancellationToken)
    {
        var userId = $"USR-{Guid.NewGuid():N}"[..20];
        const string otpCode = "1234";
        _pendingSignupOtps[userId] = (otpCode, request.Email, request.PhoneNumber, UserRole.Shopper);

        return Task.FromResult(new SignupOtpChallengeDto
        {
            UserId = userId,
            Email = request.Email,
            PhoneNumber = request.PhoneNumber,
            Role = UserRole.Shopper,
            ExpiresAt = DateTimeOffset.UtcNow.AddMinutes(10),
            DevelopmentOtpCode = otpCode
        });
    }

    public Task<SignupOtpChallengeDto?> ResendSignupOtpAsync(
        ResendSignupOtpDto request,
        CancellationToken cancellationToken)
    {
        if (!_pendingSignupOtps.TryGetValue(request.UserId, out var pending))
        {
            return Task.FromResult<SignupOtpChallengeDto?>(null);
        }

        const string otpCode = "1234";
        _pendingSignupOtps[request.UserId] = (otpCode, pending.email, pending.phone, pending.role);

        return Task.FromResult<SignupOtpChallengeDto?>(new SignupOtpChallengeDto
        {
            UserId = request.UserId,
            Email = pending.email,
            PhoneNumber = pending.phone,
            Role = pending.role,
            ExpiresAt = DateTimeOffset.UtcNow.AddMinutes(10),
            DevelopmentOtpCode = otpCode
        });
    }

    public Task<AuthenticatedUserDto?> VerifySignupOtpAsync(
        VerifySignupOtpDto request,
        CancellationToken cancellationToken)
    {
        if (!_pendingSignupOtps.TryGetValue(request.UserId, out var pending))
        {
            return Task.FromResult<AuthenticatedUserDto?>(null);
        }

        if (!string.Equals(pending.otp, request.OtpCode, StringComparison.Ordinal))
        {
            return Task.FromResult<AuthenticatedUserDto?>(null);
        }

        _pendingSignupOtps.Remove(request.UserId);

        return Task.FromResult<AuthenticatedUserDto?>(new AuthenticatedUserDto
        {
            UserId = request.UserId,
            FullName = "Verified Demo User",
            Email = pending.email,
            PhoneNumber = pending.phone,
            Role = pending.role,
            CreatedAt = DateTimeOffset.UtcNow
        });
    }

    public Task<ShoppingRequest> CreateRequestAsync(CreateShoppingRequestDto request, CancellationToken cancellationToken)
    {
        var entity = new ShoppingRequest
        {
            Id = $"REQ-{Random.Shared.Next(1000, 9999)}",
            CustomerId = request.CustomerId,
            PreferredStore = request.PreferredStore,
            MarketType = request.MarketType,
            Budget = request.Budget,
            DeliveryAddress = request.DeliveryAddress,
            DeliveryNotes = request.DeliveryNotes ?? string.Empty,
            Items = request.Items
                .Select(item => new RequestItem
                {
                    Name = item.Name,
                    Quantity = item.Quantity,
                    MaxPrice = item.MaxPrice,
                    Unit = item.Unit ?? string.Empty,
                    Description = item.Description ?? string.Empty,
                    Price = item.Price
                })
                .ToList(),
            CreatedAt = DateTimeOffset.UtcNow
        };

        _requests.Insert(0, entity);

        var newOrder = new Order
        {
            Id = $"ORD-{Random.Shared.Next(1000, 9999)}",
            RequestId = entity.Id,
            Status = OrderStatus.Pending,
            DeliveryFee = DeliveryFeeFixed,
            ServiceFee = ServiceFeeFixed,
            UpdatedAt = DateTimeOffset.UtcNow
        };
        _orders.Insert(0, newOrder);

        return Task.FromResult(entity);
    }

    public Task<IReadOnlyList<RecentRequestDto>> GetRecentRequestsAsync(string customerId, CancellationToken cancellationToken)
    {
        var requests = _requests
            .Where(x => x.CustomerId.Equals(customerId, StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(x => x.CreatedAt)
            .Take(10)
            .ToList();

        var dtos = requests.Select(r =>
        {
            var order = _orders.FirstOrDefault(o => o.RequestId == r.Id);
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

        return Task.FromResult<IReadOnlyList<RecentRequestDto>>(dtos);
    }

    public Task<IReadOnlyList<ActiveOrderDto>> GetActiveOrdersAsync(string customerId, CancellationToken cancellationToken)
    {
        var requestIds = _requests
            .Where(x => x.CustomerId.Equals(customerId, StringComparison.OrdinalIgnoreCase))
            .Select(x => x.Id)
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        var result = _orders
            .Where(x => requestIds.Contains(x.RequestId) && x.Status != OrderStatus.Delivered)
            .OrderByDescending(x => x.UpdatedAt)
            .Select(order =>
            {
                var orderItems = _orderItems.Where(i => i.OrderId == order.Id).ToList();
                decimal estimatedTotal;
                int totalItemsCount;

                if (orderItems.Count > 0)
                {
                    estimatedTotal = orderItems.Sum(i => i.EstimatedPrice * i.Quantity);
                    totalItemsCount = orderItems.Count;
                }
                else
                {
                    var request = _requests.FirstOrDefault(r => r.Id == order.RequestId);
                    estimatedTotal = request?.Items.Sum(i => i.Price * i.Quantity) ?? 0m;
                    totalItemsCount = request?.Items.Count ?? 0;
                }

                return new ActiveOrderDto
                {
                    Id = order.Id,
                    RequestId = order.RequestId,
                    ShopperName = order.ShopperName,
                    StoreName = order.StoreName,
                    StoreAddress = order.StoreAddress,
                    Status = order.Status,
                    ItemsSubtotal = order.ItemsSubtotal,
                    EstimatedItemsTotal = estimatedTotal,
                    DeliveryFee = order.DeliveryFee,
                    ServiceFee = order.ServiceFee,
                    PickedItemsCount = order.PickedItemsCount,
                    TotalItemsCount = totalItemsCount,
                    EstimatedDeliveryMinutes = order.EstimatedDeliveryMinutes,
                    UpdatedAt = order.UpdatedAt,
                    StorePhotoUrl = _markets.FirstOrDefault(m => m.Name == order.StoreName)?.PhotoUrl,
                };
            })
            .ToList();

        return Task.FromResult<IReadOnlyList<ActiveOrderDto>>(result);
    }

    public Task<bool> IsOrderOwnedByCustomerAsync(
        string orderId,
        string customerId,
        CancellationToken cancellationToken)
    {
        var order = _orders.FirstOrDefault(x => x.Id.Equals(orderId, StringComparison.OrdinalIgnoreCase));
        if (order is null) return Task.FromResult(false);

        var request = _requests.FirstOrDefault(x => x.Id.Equals(order.RequestId, StringComparison.OrdinalIgnoreCase));
        if (request is null) return Task.FromResult(false);

        return Task.FromResult(request.CustomerId.Equals(customerId, StringComparison.OrdinalIgnoreCase));
    }

    public Task<bool> CanAccessOrderChatAsync(string orderId, string userId, CancellationToken cancellationToken)
    {
        var order = _orders.FirstOrDefault(x => x.Id.Equals(orderId, StringComparison.OrdinalIgnoreCase));
        if (order is null) return Task.FromResult(false);
        if (order.ShopperId?.Equals(userId, StringComparison.OrdinalIgnoreCase) == true) return Task.FromResult(true);
        var request = _requests.FirstOrDefault(x => x.Id.Equals(order.RequestId, StringComparison.OrdinalIgnoreCase));
        return Task.FromResult(request?.CustomerId.Equals(userId, StringComparison.OrdinalIgnoreCase) ?? false);
    }

    public Task<IReadOnlyList<ActiveJobItemDto>> GetOrderItemsAsync(string orderId, CancellationToken cancellationToken)
    {
        var orderItems = _orderItems
            .Where(x => x.OrderId.Equals(orderId, StringComparison.OrdinalIgnoreCase))
            .ToList();

        if (orderItems.Count > 0)
        {
            var result = orderItems.Select(i => new ActiveJobItemDto
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
            return Task.FromResult<IReadOnlyList<ActiveJobItemDto>>(result);
        }

        // Fall back to request items if no shopper has accepted yet
        var order = _orders.FirstOrDefault(x => x.Id.Equals(orderId, StringComparison.OrdinalIgnoreCase));
        if (order is null) return Task.FromResult<IReadOnlyList<ActiveJobItemDto>>([]);

        var request = _requests.FirstOrDefault(x => x.Id.Equals(order.RequestId, StringComparison.OrdinalIgnoreCase));
        if (request is null) return Task.FromResult<IReadOnlyList<ActiveJobItemDto>>([]);

        var fallback = request.Items.Select((item, index) => new ActiveJobItemDto
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

        return Task.FromResult<IReadOnlyList<ActiveJobItemDto>>(fallback);
    }

    public Task<OrderTrackingDto?> GetOrderTrackingAsync(string orderId, CancellationToken cancellationToken)
    {
        var order = _orders.FirstOrDefault(x => x.Id.Equals(orderId, StringComparison.OrdinalIgnoreCase));
        if (order is null) return Task.FromResult<OrderTrackingDto?>(null);

        var items = _orderItems.Where(x => x.OrderId.Equals(orderId, StringComparison.OrdinalIgnoreCase)).ToList();
        var (stepLabel, stepNumber) = GetStepInfo(order.Status);
        const int totalSteps = 5;
        var progressPercent = (int)Math.Round((double)stepNumber / totalSteps * 100);

        var tracking = new OrderTrackingDto
        {
            OrderId = order.Id,
            RequestId = order.RequestId,
            ShopperName = order.ShopperName,
            StoreName = order.StoreName,
            StoreAddress = order.StoreAddress,
            CurrentStatus = order.Status,
            StepLabel = stepLabel,
            StepNumber = stepNumber,
            TotalSteps = totalSteps,
            ProgressPercent = progressPercent,
            PickedItemsCount = order.PickedItemsCount,
            TotalItemsCount = items.Count,
            EstimatedDeliveryMinutes = order.EstimatedDeliveryMinutes,
            Timeline =
            [
                OrderStatus.Pending,
                OrderStatus.Accepted,
                OrderStatus.Shopping,
                OrderStatus.Purchased,
                OrderStatus.OutForDelivery,
                OrderStatus.Delivered
            ]
        };

        return Task.FromResult<OrderTrackingDto?>(tracking);
    }

    public Task<OrderSummaryDto?> GetOrderSummaryAsync(string orderId, CancellationToken cancellationToken)
    {
        var order = _orders.FirstOrDefault(x => x.Id.Equals(orderId, StringComparison.OrdinalIgnoreCase));
        if (order is null) return Task.FromResult<OrderSummaryDto?>(null);

        var request = _requests.FirstOrDefault(x => x.Id.Equals(order.RequestId, StringComparison.OrdinalIgnoreCase));
        var items = _orderItems
            .Where(x => x.OrderId.Equals(orderId, StringComparison.OrdinalIgnoreCase) && x.Status == OrderItemStatus.Found)
            .ToList();

        var summary = new OrderSummaryDto
        {
            OrderId = order.Id,
            StoreName = order.StoreName,
            StoreAddress = order.StoreAddress,
            ShopperName = order.ShopperName,
            ShopperRating = 4.8m,
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
            TotalPaid = order.TotalAmount
        };

        return Task.FromResult<OrderSummaryDto?>(summary);
    }

    public Task<PaymentSummaryDto?> GetPaymentSummaryAsync(string orderId, CancellationToken cancellationToken)
    {
        var order = _orders.FirstOrDefault(x => x.Id.Equals(orderId, StringComparison.OrdinalIgnoreCase));
        if (order is null) return Task.FromResult<PaymentSummaryDto?>(null);

        var total = order.TotalAmount;
        var deposit = Math.Round(total * 0.3m, 2);
        var summary = new PaymentSummaryDto
        {
            OrderId = order.Id,
            ItemsSubtotal = order.ItemsSubtotal,
            DeliveryFee = order.DeliveryFee,
            ServiceFee = order.ServiceFee,
            TotalAmount = total,
            DepositAmount = deposit,
            RemainingAmount = total - deposit
        };

        return Task.FromResult<PaymentSummaryDto?>(summary);
    }

    // ── Shopper: Job management ───────────────────────────────────────────────

    public Task<IReadOnlyList<ShoppingRequest>> GetAvailableRequestsAsync(CancellationToken cancellationToken)
    {
        var acceptedRequestIds = _orders
            .Where(o => o.ShopperId != null)
            .Select(o => o.RequestId)
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        var available = _requests
            .Where(r => !acceptedRequestIds.Contains(r.Id))
            .OrderByDescending(r => r.CreatedAt)
            .ToList();

        return Task.FromResult<IReadOnlyList<ShoppingRequest>>(available);
    }

    public Task<ActiveJobDto> AcceptRequestAsync(string requestId, AcceptRequestDto dto, CancellationToken cancellationToken)
    {
        var request = _requests.FirstOrDefault(x => x.Id.Equals(requestId, StringComparison.OrdinalIgnoreCase))
            ?? throw new KeyNotFoundException($"Request {requestId} not found.");

        var order = _orders.FirstOrDefault(x => x.RequestId.Equals(requestId, StringComparison.OrdinalIgnoreCase))
            ?? throw new KeyNotFoundException($"Order for request {requestId} not found.");

        order.ShopperId = dto.ShopperId;
        order.ShopperName = dto.ShopperId; // placeholder until user lookup is wired
        order.StoreName = dto.StoreName;
        order.StoreAddress = dto.StoreAddress;
        order.Status = OrderStatus.Accepted;
        order.UpdatedAt = DateTimeOffset.UtcNow;

        // Materialise order items from request items
        var nextId = _orderItems.Count > 0 ? _orderItems.Max(x => x.Id) + 1 : 1;
        var newItems = request.Items.Select(ri => new OrderItem
        {
            Id = nextId++,
            OrderId = order.Id,
            Name = ri.Name,
            Unit = ri.Unit,
            Description = ri.Description,
            Quantity = ri.Quantity,
            EstimatedPrice = ri.Price > 0 ? ri.Price : ri.MaxPrice ?? 0m,
            Status = OrderItemStatus.Pending,
            UpdatedAt = DateTimeOffset.UtcNow
        }).ToList();

        _orderItems.AddRange(newItems);

        return Task.FromResult(BuildActiveJobDto(order, request, dto.ShopperId, newItems));
    }

    public Task<ActiveJobDto?> GetActiveJobAsync(string shopperId, CancellationToken cancellationToken)
    {
        var order = _orders
            .Where(o =>
                o.ShopperId != null &&
                o.ShopperId.Equals(shopperId, StringComparison.OrdinalIgnoreCase) &&
                o.Status != OrderStatus.Delivered &&
                o.Status != OrderStatus.Pending)
            .OrderByDescending(o => o.UpdatedAt)
            .FirstOrDefault();

        if (order is null) return Task.FromResult<ActiveJobDto?>(null);

        var request = _requests.FirstOrDefault(r => r.Id.Equals(order.RequestId, StringComparison.OrdinalIgnoreCase));
        var items = _orderItems.Where(i => i.OrderId.Equals(order.Id, StringComparison.OrdinalIgnoreCase)).ToList();

        return Task.FromResult<ActiveJobDto?>(BuildActiveJobDto(order, request, request?.CustomerId ?? string.Empty, items));
    }

    public Task<ActiveJobItemDto> UpdateOrderItemAsync(
        string orderId,
        int itemId,
        UpdateOrderItemDto dto,
        CancellationToken cancellationToken)
    {
        var item = _orderItems.FirstOrDefault(x =>
            x.OrderId.Equals(orderId, StringComparison.OrdinalIgnoreCase) && x.Id == itemId)
            ?? throw new KeyNotFoundException($"Item {itemId} not found in order {orderId}.");

        item.Status = dto.Status;
        item.FoundPrice = dto.FoundPrice;
        item.PhotoUrl = dto.PhotoUrl;
        item.UpdatedAt = DateTimeOffset.UtcNow;

        // Recalculate order subtotal
        var order = _orders.FirstOrDefault(x => x.Id.Equals(orderId, StringComparison.OrdinalIgnoreCase));
        if (order is not null)
        {
            order.PickedItemsCount = _orderItems.Count(x =>
                x.OrderId.Equals(orderId, StringComparison.OrdinalIgnoreCase) &&
                x.Status == OrderItemStatus.Found);

            order.ItemsSubtotal = _orderItems
                .Where(x => x.OrderId.Equals(orderId, StringComparison.OrdinalIgnoreCase) &&
                            x.Status == OrderItemStatus.Found)
                .Sum(x => x.FoundPrice ?? x.EstimatedPrice);

            order.UpdatedAt = DateTimeOffset.UtcNow;
        }

        return Task.FromResult(new ActiveJobItemDto
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
        });
    }

    public Task<Order> FinishShoppingAsync(string orderId, string shopperId, CancellationToken cancellationToken)
    {
        var order = _orders.FirstOrDefault(x => x.Id.Equals(orderId, StringComparison.OrdinalIgnoreCase))
            ?? throw new KeyNotFoundException($"Order {orderId} not found.");

        order.Status = OrderStatus.Purchased;
        order.UpdatedAt = DateTimeOffset.UtcNow;

        return Task.FromResult(order);
    }

    public Task<IReadOnlyList<ShopperOrderHistoryDto>> GetShopperOrderHistoryAsync(string shopperId, CancellationToken cancellationToken)
    {
        IReadOnlyList<ShopperOrderHistoryDto> result = [];
        return Task.FromResult(result);
    }

    // ── Chat ──────────────────────────────────────────────────────────────────

    public Task<IReadOnlyList<ChatMessage>> GetMessagesAsync(string orderId, CancellationToken cancellationToken)
    {
        var messages = _messages
            .Where(x => x.OrderId.Equals(orderId, StringComparison.OrdinalIgnoreCase))
            .OrderBy(x => x.SentAt)
            .ToList();

        return Task.FromResult<IReadOnlyList<ChatMessage>>(messages);
    }

    public Task<ChatMessage> SendMessageAsync(string orderId, SendChatMessageDto request, CancellationToken cancellationToken)
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

        _messages.Add(message);

        return Task.FromResult(message);
    }

    public Task<ChatMessage> SendPriceCardAsync(string orderId, SendPriceCardDto dto, CancellationToken cancellationToken)
    {
        var message = new ChatMessage
        {
            Id = Guid.NewGuid().ToString("N"),
            OrderId = orderId,
            Sender = "shopper",
            Type = "price_card",
            Text = $"Price update: {dto.ItemName}",
            SentAt = DateTimeOffset.UtcNow,
            PriceCard = new PriceCardData
            {
                ItemName = dto.ItemName,
                Quantity = dto.Quantity,
                OldPrice = dto.OldPrice,
                NewPrice = dto.NewPrice
            }
        };

        _messages.Add(message);

        return Task.FromResult(message);
    }

    public Task<ChatMessage> ResolvePriceCardAsync(string orderId, ResolvePriceCardDto request, CancellationToken cancellationToken)
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

        _messages.Add(message);

        return Task.FromResult(message);
    }

    // ── Admin: Dashboard ──────────────────────────────────────────────────────

    public Task<AdminDashboardDto> GetAdminDashboardAsync(CancellationToken cancellationToken)
    {
        var today = DateTimeOffset.UtcNow.Date;
        var todayOrders = _orders.Where(o => o.UpdatedAt.Date == today).ToList();

        var dto = new AdminDashboardDto
        {
            TotalOrdersToday    = todayOrders.Count,
            ActiveOrders        = _orders.Count(o => o.Status is not (OrderStatus.Delivered)),
            CompletedOrdersToday = todayOrders.Count(o => o.Status == OrderStatus.Delivered),
            ActiveShoppers      = _shoppers.Count(s => s.IsOnline && s.IsActive),
            TotalShoppers       = _shoppers.Count,
            TotalCustomers      = _customers.Count,
            RevenueToday        = todayOrders.Sum(o => o.TotalAmount),
            RevenueThisMonth    = 1_250_000m,
            PlatformFeesToday   = todayOrders.Sum(o => o.ServiceFee),
            AvgWaitTimeMinutes  = 18.4,
            RecentOrders = _orders
                .OrderByDescending(o => o.UpdatedAt)
                .Take(5)
                .Select(o =>
                {
                    var req = _requests.FirstOrDefault(r => r.Id == o.RequestId);
                    return new AdminRecentOrderDto
                    {
                        OrderId          = o.Id,
                        CustomerName     = req is not null ? "Customer" : "—",
                        CustomerInitials = "CU",
                        CustomerLocation = req?.DeliveryAddress ?? "—",
                        ShopperName      = o.ShopperName,
                        StoreName        = o.StoreName ?? "—",
                        MarketIcon       = "storefront",
                        Status           = o.Status,
                        Total            = o.TotalAmount,
                        UpdatedAt        = o.UpdatedAt
                    };
                }).ToList(),
            MonthlyChart =
            [
                new AdminMonthlyStatDto { Month = "Jun", Revenue = 820_000m, Payouts = 620_000m },
                new AdminMonthlyStatDto { Month = "Jul", Revenue = 940_000m, Payouts = 710_000m },
                new AdminMonthlyStatDto { Month = "Aug", Revenue = 750_000m, Payouts = 570_000m },
                new AdminMonthlyStatDto { Month = "Sep", Revenue = 1_100_000m, Payouts = 830_000m },
                new AdminMonthlyStatDto { Month = "Oct", Revenue = 1_200_000m, Payouts = 900_000m },
                new AdminMonthlyStatDto { Month = "Nov", Revenue = 1_250_000m, Payouts = 940_000m },
            ]
        };

        return Task.FromResult(dto);
    }

    // ── Admin: Orders ─────────────────────────────────────────────────────────

    public Task<PagedResult<AdminOrderDto>> GetAdminOrdersAsync(
        string? status, int page, int pageSize, CancellationToken cancellationToken)
    {
        var query = _orders.AsEnumerable();

        if (!string.IsNullOrWhiteSpace(status) &&
            Enum.TryParse<OrderStatus>(status, ignoreCase: true, out var parsedStatus))
        {
            query = query.Where(o => o.Status == parsedStatus);
        }

        var ordered = query.OrderByDescending(o => o.UpdatedAt).ToList();
        var total   = ordered.Count;
        var items   = ordered
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(o =>
            {
                var req     = _requests.FirstOrDefault(r => r.Id == o.RequestId);
                var shopper = _shoppers.FirstOrDefault(s => s.Id == o.ShopperId);
                return new AdminOrderDto
                {
                    OrderId          = o.Id,
                    CustomerName     = "Customer",
                    CustomerInitials = "CU",
                    CustomerLocation = req?.DeliveryAddress ?? "—",
                    ShopperName      = o.ShopperName,
                    ShopperTier      = shopper?.Tier,
                    StoreName        = o.StoreName ?? "—",
                    MarketIcon       = "storefront",
                    Status           = o.Status,
                    Total            = o.TotalAmount,
                    UpdatedAt        = o.UpdatedAt
                };
            }).ToList();

        return Task.FromResult(new PagedResult<AdminOrderDto>
        {
            Items = items, TotalCount = total, Page = page, PageSize = pageSize
        });
    }

    public Task<AdminOrderDto?> GetAdminOrderAsync(string orderId, CancellationToken cancellationToken)
    {
        var o = _orders.FirstOrDefault(x => x.Id.Equals(orderId, StringComparison.OrdinalIgnoreCase));
        if (o is null) return Task.FromResult<AdminOrderDto?>(null);

        var req     = _requests.FirstOrDefault(r => r.Id == o.RequestId);
        var shopper = _shoppers.FirstOrDefault(s => s.Id == o.ShopperId);
        return Task.FromResult<AdminOrderDto?>(new AdminOrderDto
        {
            OrderId          = o.Id,
            CustomerName     = "Customer",
            CustomerInitials = "CU",
            CustomerLocation = req?.DeliveryAddress ?? "—",
            ShopperName      = o.ShopperName,
            ShopperTier      = shopper?.Tier,
            StoreName        = o.StoreName ?? "—",
            MarketIcon       = "storefront",
            Status           = o.Status,
            Total            = o.TotalAmount,
            UpdatedAt        = o.UpdatedAt
        });
    }

    public Task<Order> UpdateAdminOrderStatusAsync(
        string orderId, UpdateOrderStatusDto dto, CancellationToken cancellationToken)
    {
        var order = _orders.FirstOrDefault(x => x.Id.Equals(orderId, StringComparison.OrdinalIgnoreCase))
            ?? throw new KeyNotFoundException($"Order {orderId} not found.");

        order.Status    = dto.Status;
        order.UpdatedAt = DateTimeOffset.UtcNow;
        return Task.FromResult(order);
    }

    // ── Admin: Shoppers ───────────────────────────────────────────────────────

    public Task<PagedResult<AdminShopperDto>> GetAdminShoppersAsync(
        string tab, int page, int pageSize, CancellationToken cancellationToken)
    {
        var query = tab.Equals("pending", StringComparison.OrdinalIgnoreCase)
            ? _shoppers.Where(s => !s.IsVerified)
            : _shoppers.AsEnumerable();

        var total = query.Count();
        var items = query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(ToShopperDto)
            .ToList();

        return Task.FromResult(new PagedResult<AdminShopperDto>
        {
            Items = items, TotalCount = total, Page = page, PageSize = pageSize
        });
    }

    public Task UpdateAdminShopperStatusAsync(
        string shopperId, UpdateUserStatusDto dto, CancellationToken cancellationToken)
    {
        var idx = _shoppers.FindIndex(s => s.Id.Equals(shopperId, StringComparison.OrdinalIgnoreCase));
        if (idx < 0) throw new KeyNotFoundException($"Shopper {shopperId} not found.");

        var s = _shoppers[idx];
        _shoppers[idx] = s with { IsActive = dto.IsActive };
        return Task.CompletedTask;
    }

    // ── Admin: Customers ──────────────────────────────────────────────────────

    public Task<PagedResult<AdminCustomerDto>> GetAdminCustomersAsync(
        string? membership, string? status, int page, int pageSize, CancellationToken cancellationToken)
    {
        var query = _customers.AsEnumerable();

        if (!string.IsNullOrWhiteSpace(membership))
            query = query.Where(c => c.Membership.Equals(membership, StringComparison.OrdinalIgnoreCase));

        if (!string.IsNullOrWhiteSpace(status))
        {
            var active = status.Equals("Active", StringComparison.OrdinalIgnoreCase);
            query = query.Where(c => c.IsActive == active);
        }

        var total = query.Count();
        var items = query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(ToCustomerDto)
            .ToList();

        return Task.FromResult(new PagedResult<AdminCustomerDto>
        {
            Items = items, TotalCount = total, Page = page, PageSize = pageSize
        });
    }

    public Task UpdateAdminCustomerStatusAsync(
        string customerId, UpdateUserStatusDto dto, CancellationToken cancellationToken)
    {
        var idx = _customers.FindIndex(c => c.Id.Equals(customerId, StringComparison.OrdinalIgnoreCase));
        if (idx < 0) throw new KeyNotFoundException($"Customer {customerId} not found.");

        var c = _customers[idx];
        _customers[idx] = c with { IsActive = dto.IsActive };
        return Task.CompletedTask;
    }

    // ── Admin: Earnings ───────────────────────────────────────────────────────

    public Task<AdminEarningsSummaryDto> GetAdminEarningsSummaryAsync(CancellationToken cancellationToken)
    {
        const decimal revenue = 1_250_000m;
        const decimal payouts = 940_000m;
        const decimal fees    = revenue - payouts;

        var dto = new AdminEarningsSummaryDto
        {
            TotalRevenue          = revenue,
            ShopperPayouts        = payouts,
            PlatformFees          = fees,
            PlatformMarginPercent = Math.Round(fees / revenue * 100, 1),
            NextPayoutCycle       = "Nov 24, 2023",
            MonthlyChart =
            [
                new AdminMonthlyStatDto { Month = "Jun", Revenue = 820_000m,   Payouts = 620_000m },
                new AdminMonthlyStatDto { Month = "Jul", Revenue = 940_000m,   Payouts = 710_000m },
                new AdminMonthlyStatDto { Month = "Aug", Revenue = 750_000m,   Payouts = 570_000m },
                new AdminMonthlyStatDto { Month = "Sep", Revenue = 1_100_000m, Payouts = 830_000m },
                new AdminMonthlyStatDto { Month = "Oct", Revenue = 1_200_000m, Payouts = 900_000m },
                new AdminMonthlyStatDto { Month = "Nov", Revenue = 1_250_000m, Payouts = 940_000m },
            ]
        };

        return Task.FromResult(dto);
    }

    public Task<PagedResult<AdminPayoutDto>> GetAdminPayoutsAsync(
        int page, int pageSize, CancellationToken cancellationToken)
    {
        var total = _payouts.Count;
        var items = _payouts
            .OrderByDescending(p => p.Date)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return Task.FromResult(new PagedResult<AdminPayoutDto>
        {
            Items = items, TotalCount = total, Page = page, PageSize = pageSize
        });
    }

    // ── Public: Markets ───────────────────────────────────────────────────────

    public Task<IReadOnlyList<MarketDto>> GetPublicMarketsAsync(string? type, CancellationToken cancellationToken)
        => Task.FromResult<IReadOnlyList<MarketDto>>(Array.Empty<MarketDto>());

    // ── Admin: Markets ────────────────────────────────────────────────────────

    public Task<PagedResult<AdminMarketDto>> GetAdminMarketsAsync(
        string? type, string? status, int page, int pageSize, CancellationToken cancellationToken)
    {
        var query = _markets.AsEnumerable();

        if (!string.IsNullOrWhiteSpace(type))
            query = query.Where(m => m.Type.Equals(type, StringComparison.OrdinalIgnoreCase));

        if (!string.IsNullOrWhiteSpace(status))
        {
            var active = status.Equals("Active", StringComparison.OrdinalIgnoreCase);
            query = query.Where(m => m.IsActive == active);
        }

        var total = query.Count();
        var items = query
            .OrderBy(m => m.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(ToMarketDto)
            .ToList();

        return Task.FromResult(new PagedResult<AdminMarketDto>
        {
            Items = items, TotalCount = total, Page = page, PageSize = pageSize
        });
    }

    public Task<AdminMarketDto> CreateAdminMarketAsync(CreateMarketDto dto, CancellationToken cancellationToken)
    {
        var market = new Market
        {
            Id               = $"MK-{Random.Shared.Next(1000, 9999)}-NEW",
            Name             = dto.Name,
            Type             = dto.Type,
            Location         = dto.Location,
            Zone             = dto.Zone,
            Address          = dto.Address,
            IsActive         = dto.IsActive,
            Categories       = dto.Categories,
            OpeningTime      = dto.OpeningTime,
            ClosingTime      = dto.ClosingTime,
            GeofenceRadiusKm = dto.GeofenceRadiusKm,
            CreatedAt        = DateTimeOffset.UtcNow,
            UpdatedAt        = DateTimeOffset.UtcNow
        };
        _markets.Add(market);
        return Task.FromResult(ToMarketDto(market));
    }

    public Task<AdminMarketDto?> UpdateAdminMarketAsync(
        string marketId, CreateMarketDto dto, CancellationToken cancellationToken)
    {
        var market = _markets.FirstOrDefault(m => m.Id.Equals(marketId, StringComparison.OrdinalIgnoreCase));
        if (market is null) return Task.FromResult<AdminMarketDto?>(null);

        market.Name             = dto.Name;
        market.Type             = dto.Type;
        market.Location         = dto.Location;
        market.Zone             = dto.Zone;
        market.Address          = dto.Address;
        market.IsActive         = dto.IsActive;
        market.Categories       = dto.Categories;
        market.OpeningTime      = dto.OpeningTime;
        market.ClosingTime      = dto.ClosingTime;
        market.GeofenceRadiusKm = dto.GeofenceRadiusKm;
        market.UpdatedAt        = DateTimeOffset.UtcNow;

        return Task.FromResult<AdminMarketDto?>(ToMarketDto(market));
    }

    public Task<bool> DeleteAdminMarketAsync(string marketId, CancellationToken cancellationToken)
    {
        var market = _markets.FirstOrDefault(m => m.Id.Equals(marketId, StringComparison.OrdinalIgnoreCase));
        if (market is null) return Task.FromResult(false);

        _markets.Remove(market);
        return Task.FromResult(true);
    }

    // ── Admin: Users ──────────────────────────────────────────────────────────

    public Task<IReadOnlyList<AdminUserDto>> GetAdminUsersAsync(CancellationToken cancellationToken)
        => Task.FromResult<IReadOnlyList<AdminUserDto>>(_adminUsers);

    public Task<AdminUserDto> CreateAdminUserAsync(CreateAdminUserDto dto, CancellationToken cancellationToken)
    {
        var initials = string.Concat(
            dto.FullName.Split(' ', StringSplitOptions.RemoveEmptyEntries)
                        .Take(2)
                        .Select(w => char.ToUpper(w[0])));

        var user = new AdminUserDto
        {
            UserId             = $"ADM-{Guid.NewGuid():N}"[..16],
            FullName           = dto.FullName,
            Initials           = initials,
            Email              = dto.Email,
            PhoneNumber        = dto.PhoneNumber,
            AdminRole          = dto.AdminRole,
            IsActive           = true,
            ForcePasswordReset = dto.ForcePasswordReset,
            CreatedAt          = DateTimeOffset.UtcNow
        };
        _adminUsers.Add(user);
        return Task.FromResult(user);
    }

    public Task UpdateUserLocationAsync(string userId, double latitude, double longitude, CancellationToken cancellationToken)
        => Task.CompletedTask;

    // ── Private: seed helpers ─────────────────────────────────────────────────

    private void SeedAdminData()
    {
        _shoppers.AddRange(
        [
            new("SHP-001", "Jadesola Sowole",  "jadesola@swift.ng", "+2348101234567", true,  true,  true,  "PRO SHOPPER", 4.9m, 124, 18, 56_400m, DateTimeOffset.UtcNow.AddMonths(-14)),
            new("SHP-002", "Musa Babangida",   "musa.b@swift.ng",   "+2347031234567", true,  true,  true,  "BASIC",        4.6m, 44,  7,  21_800m, DateTimeOffset.UtcNow.AddMonths(-6)),
            new("SHP-003", "Ola Ukpanah",      "ola.u@swift.ng",    "+2349021234567", false, true,  true,  "PRO SHOPPER", 4.8m, 98,  12, 42_300m, DateTimeOffset.UtcNow.AddMonths(-10)),
            new("SHP-004", "Blessing Adeyemi", "blessing@swift.ng", "+2348051234567", true,  false, true,  "BASIC",        4.2m, 11,  3,  8_500m,  DateTimeOffset.UtcNow.AddMonths(-2)),
            new("SHP-005", "Emeka Okonkwo",    "emeka.o@swift.ng",  "+2347061234567", false, false, false, "BASIC",        3.9m, 5,   0,  0m,      DateTimeOffset.UtcNow.AddMonths(-1)),
        ]);

        _customers.AddRange(
        [
            new("CUS-001", "Chinonye Okeke",  "chinonye.o@swift.ng", 42, DateTimeOffset.UtcNow.AddDays(-7),  120_500m, "Premium", true,  DateTimeOffset.UtcNow.AddMonths(-18)),
            new("CUS-002", "Babajide Sanusi", "j.sanusi@outlook.com", 12, DateTimeOffset.UtcNow.AddDays(-28), 45_200m,  "Basic",   true,  DateTimeOffset.UtcNow.AddMonths(-8)),
            new("CUS-003", "Amara Nwosu",     "amara.nw@gmail.com",   85, DateTimeOffset.UtcNow.AddDays(-1),  310_900m, "Premium", false, DateTimeOffset.UtcNow.AddMonths(-24)),
            new("CUS-004", "Tunde Adeyemi",   "t.adeyemi@yahoo.com",  24, DateTimeOffset.UtcNow.AddDays(-29), 88_400m,  "Basic",   true,  DateTimeOffset.UtcNow.AddMonths(-5)),
            new("CUS-005", "Fatima Yusuf",    "fatima.y@swift.ng",    5,  DateTimeOffset.UtcNow.AddDays(-26), 12_800m,  "Basic",   true,  DateTimeOffset.UtcNow.AddMonths(-1)),
        ]);

        _markets.AddRange(
        [
            new Market { Id = "MK-9901-LKI", Name = "Ebeano Supermarket", Type = "Supermarket", Location = "Lekki Phase 1",   Zone = "Lekki",    Address = "14 Admiralty Way, Lekki Phase 1",  IsActive = true,  Categories = ["Groceries", "Bakery"],           OpeningTime = "07:00", ClosingTime = "22:00", GeofenceRadiusKm = 4.0 },
            new Market { Id = "MK-2245-IKJ", Name = "Mile 12 Market",     Type = "OpenMarket",  Location = "Ketu, Ikeja",     Zone = "Mainland", Address = "Mile 12 Road, Ketu, Lagos",         IsActive = true,  Categories = ["Wholesale", "Fresh Produce"],     OpeningTime = "06:00", ClosingTime = "19:00", GeofenceRadiusKm = 7.0 },
            new Market { Id = "MK-4412-VI",  Name = "The Wine Shop",       Type = "Specialty",   Location = "Victoria Island",  Zone = "Island",   Address = "27 Adeola Odeku St, V/I",           IsActive = false, Categories = ["Beverages", "Gifts"],             OpeningTime = "10:00", ClosingTime = "21:00", GeofenceRadiusKm = 2.0 },
            new Market { Id = "MK-1108-IKJ", Name = "Spar Market",         Type = "Supermarket", Location = "Ikeja Mall",       Zone = "Mainland", Address = "Ikeja City Mall, Oba Akran Ave",    IsActive = true,  Categories = ["Electronics", "General"],         OpeningTime = "09:00", ClosingTime = "21:00", GeofenceRadiusKm = 3.5 },
            new Market { Id = "MK-3310-IS",  Name = "Balogun Market",      Type = "OpenMarket",  Location = "Lagos Island",     Zone = "Island",   Address = "Balogun St, Lagos Island",          IsActive = true,  Categories = ["Fabric", "Fashion", "Food"],      OpeningTime = "07:00", ClosingTime = "18:00", GeofenceRadiusKm = 5.0 },
            new Market { Id = "MK-5521-SU",  Name = "Shoprite Surulere",   Type = "Supermarket", Location = "Surulere",         Zone = "Mainland", Address = "Adeniran Ogunsanya Mall, Surulere", IsActive = true,  Categories = ["Groceries", "Home"],              OpeningTime = "09:00", ClosingTime = "21:00", GeofenceRadiusKm = 4.5 },
        ]);

        _payouts.AddRange(
        [
            new AdminPayoutDto { PayoutId = "PAY-001", ShopperId = "SHP-001", ShopperName = "Adeola Bakare",  ShopperInitials = "AB", Date = DateTimeOffset.UtcNow.AddHours(-10), Amount = 45_000m, Status = "Paid",       ActionIcon = "receipt_long" },
            new AdminPayoutDto { PayoutId = "PAY-002", ShopperId = "SHP-002", ShopperName = "Chima Eze",      ShopperInitials = "CE", Date = DateTimeOffset.UtcNow.AddHours(-13), Amount = 12_400m, Status = "Processing", ActionIcon = "receipt_long" },
            new AdminPayoutDto { PayoutId = "PAY-003", ShopperId = "SHP-003", ShopperName = "Musa Oladipo",   ShopperInitials = "MO", Date = DateTimeOffset.UtcNow.AddDays(-1),   Amount = 8_250m,  Status = "Failed",     ActionIcon = "refresh" },
            new AdminPayoutDto { PayoutId = "PAY-004", ShopperId = "SHP-004", ShopperName = "Fatima Farouk",  ShopperInitials = "FF", Date = DateTimeOffset.UtcNow.AddDays(-1).AddHours(-5), Amount = 67_800m, Status = "Paid", ActionIcon = "receipt_long" },
        ]);

        _adminUsers.AddRange(
        [
            new AdminUserDto { UserId = "ADM-001", FullName = "Oluwaseun Adeyemi",  Initials = "OA", Email = "seun.a@swiftshopper.ng",    PhoneNumber = "+2348101112233", AdminRole = "SuperAdmin",           IsActive = true,  ForcePasswordReset = false, CreatedAt = DateTimeOffset.UtcNow.AddMonths(-12) },
            new AdminUserDto { UserId = "ADM-002", FullName = "Ngozi Okafor",        Initials = "NO", Email = "ngozi.o@swiftshopper.ng",    PhoneNumber = "+2347031112233", AdminRole = "FleetManager",         IsActive = true,  ForcePasswordReset = false, CreatedAt = DateTimeOffset.UtcNow.AddMonths(-8) },
            new AdminUserDto { UserId = "ADM-003", FullName = "Damilola Akinwale",   Initials = "DA", Email = "dami.a@swiftshopper.ng",     PhoneNumber = "+2349021112233", AdminRole = "SupportLead",          IsActive = true,  ForcePasswordReset = true,  CreatedAt = DateTimeOffset.UtcNow.AddMonths(-3) },
            new AdminUserDto { UserId = "ADM-004", FullName = "Ibrahim Musa",         Initials = "IM", Email = "ibrahim.m@swiftshopper.ng",  PhoneNumber = "+2348051112233", AdminRole = "RegionalCoordinator",  IsActive = false, ForcePasswordReset = false, CreatedAt = DateTimeOffset.UtcNow.AddMonths(-6) },
        ]);
    }

    private static AdminShopperDto ToShopperDto(AdminShopperSeed s)
    {
        var initials = string.Concat(
            s.FullName.Split(' ', StringSplitOptions.RemoveEmptyEntries)
                      .Take(2).Select(w => char.ToUpper(w[0])));

        return new AdminShopperDto
        {
            ShopperId          = s.Id,
            FullName           = s.FullName,
            Initials           = initials,
            Email              = s.Email,
            PhoneNumber        = s.Phone,
            IsOnline           = s.IsOnline,
            IsVerified         = s.IsVerified,
            IsActive           = s.IsActive,
            Tier               = s.Tier,
            Rating             = s.Rating,
            CompletedOrders    = s.CompletedOrders,
            OrdersThisMonth    = s.OrdersThisMonth,
            EarningsThisMonth  = s.EarningsThisMonth,
            JoinedAt           = s.JoinedAt
        };
    }

    private static AdminCustomerDto ToCustomerDto(AdminCustomerSeed c)
    {
        var initials = string.Concat(
            c.FullName.Split(' ', StringSplitOptions.RemoveEmptyEntries)
                      .Take(2).Select(w => char.ToUpper(w[0])));

        var (bg, text) = c.Membership == "Premium"
            ? ("bg-emerald-100", "text-emerald-700")
            : ("bg-neutral-200", "text-neutral-600");

        return new AdminCustomerDto
        {
            CustomerId   = c.Id,
            FullName     = c.FullName,
            Initials     = initials,
            AvatarBg     = bg,
            AvatarText   = text,
            Email        = c.Email,
            TotalOrders  = c.TotalOrders,
            LastOrderAt  = c.LastOrderAt,
            TotalSpend   = c.TotalSpend,
            Membership   = c.Membership,
            IsActive     = c.IsActive,
            JoinedAt     = c.JoinedAt
        };
    }

    private static AdminMarketDto ToMarketDto(Market m) => new()
    {
        MarketId         = m.Id,
        Name             = m.Name,
        Type             = m.Type,
        Location         = m.Location,
        Zone             = m.Zone,
        Address          = m.Address,
        IsActive         = m.IsActive,
        Categories       = m.Categories,
        OpeningTime      = m.OpeningTime,
        ClosingTime      = m.ClosingTime,
        GeofenceRadiusKm = m.GeofenceRadiusKm,
        ActiveShoppers   = 0,   // would be computed from live data
        OrdersToday      = 0,
        CreatedAt        = m.CreatedAt
    };

    // ── Private helpers ───────────────────────────────────────────────────────

    private static (string label, int step) GetStepInfo(OrderStatus status) => status switch
    {
        OrderStatus.Pending => ("Order Placed", 1),
        OrderStatus.Accepted => ("Shopper Assigned", 2),
        OrderStatus.Shopping => ("Shopping in Progress", 3),
        OrderStatus.Purchased => ("Items Purchased", 4),
        OrderStatus.OutForDelivery => ("Out for Delivery", 5),
        OrderStatus.Delivered => ("Delivered", 5),
        _ => ("Unknown", 0)
    };

    private static ActiveJobDto BuildActiveJobDto(Order order, ShoppingRequest? request, string customerName, List<OrderItem> items)
    {
        return new ActiveJobDto
        {
            OrderId = order.Id,
            RequestId = order.RequestId,
            StoreName = order.StoreName,
            StoreAddress = order.StoreAddress,
            CustomerName = customerName,
            CustomerAvatarUrl = null,
            DeliveryAddress = request?.DeliveryAddress ?? string.Empty,
            DeliveryNotes = request?.DeliveryNotes ?? string.Empty,
            Status = order.Status,
            PickedItemsCount = order.PickedItemsCount,
            TotalItemsCount = items.Count,
            EstimatedTotal = order.TotalAmount,
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
}
