# SwiftShopper Backend

Production-ready starter backend for the SwiftShopper Flutter app, built with ASP.NET Core Web API and clean architecture layering.

## Structure

- `src/SwiftShopper.Api` - HTTP API (minimal APIs + Swagger)
- `src/SwiftShopper.Application` - use-case contracts and DTOs
- `src/SwiftShopper.Domain` - core entities and enums
- `src/SwiftShopper.Infrastructure` - in-memory service implementation + DI wiring
- `SwiftShopper.Backend.sln` - solution file

## Run

```bash
cd backend
dotnet run --project src/SwiftShopper.Api
```

Swagger UI opens at:

- `https://localhost:7xxx/swagger`
- `http://localhost:5xxx/swagger`

## API Endpoints

### Health
- `GET /health`

### Requests
- `POST /api/requests`
- `GET /api/requests/recent/{customerId}`

### Orders
- `GET /api/orders/active/{customerId}`
- `GET /api/orders/{orderId}/tracking`

### Chat
- `GET /api/orders/{orderId}/chat`
- `POST /api/orders/{orderId}/chat/messages`
- `POST /api/orders/{orderId}/chat/price-decision`

### SignalR
- Hub route: `GET /hubs/chat`
- Join room method: `JoinOrderRoom(orderId)`
- Leave room method: `LeaveOrderRoom(orderId)`
- Broadcast event: `messageReceived`
- Broadcast event: `priceDecisionReceived`

### Payments
- `GET /api/payments/{orderId}/summary`

## Notes

- Current data store is in-memory for rapid development.
- Replace `InMemorySwiftShopperService` in `SwiftShopper.Infrastructure` with EF Core + PostgreSQL/MySQL when ready.
- The backend seeds demo data (`customer-demo`, `ORD-9001`) for immediate integration with the Flutter app.
- REST chat writes now also broadcast to SignalR clients subscribed to the same order room.
