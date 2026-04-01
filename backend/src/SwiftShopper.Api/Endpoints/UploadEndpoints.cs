using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using SwiftShopper.Application.Abstractions;
using SwiftShopper.Application.Contracts.Requests;
using SwiftShopper.Infrastructure.Persistence;

namespace SwiftShopper.Api.Endpoints;

public static class UploadEndpoints
{
    public static void MapUploadEndpoints(this IEndpointRouteBuilder app)
    {
        // POST /api/upload/image — upload any image, returns the Cloudinary URL
        app.MapPost("/api/upload/image", async (
            IFormFile file,
            IImageService imageService,
            CancellationToken ct) =>
        {
            if (file.Length == 0)
                return Results.BadRequest("No file provided.");

            var allowedTypes = new[] { "image/jpeg", "image/png", "image/webp", "image/gif" };
            if (!allowedTypes.Contains(file.ContentType.ToLower()))
                return Results.BadRequest("Only JPEG, PNG, WebP, or GIF images are accepted.");

            await using var stream = file.OpenReadStream();
            var url = await imageService.UploadImageAsync(stream, file.FileName, "swift-shopper", ct);
            return Results.Ok(new { url });
        })
        .RequireAuthorization()
        .DisableAntiforgery()
        .WithTags("Upload")
        .WithSummary("Upload an image to Cloudinary and return the secure URL.");

        // PATCH /api/users/me/avatar — update the authenticated user's profile picture
        app.MapPatch("/api/users/me/avatar", async (
            IFormFile file,
            ClaimsPrincipal principal,
            IImageService imageService,
            SwiftShopperDbContext db,
            CancellationToken ct) =>
        {
            var userId = principal.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(userId))
                return Results.Unauthorized();

            if (file.Length == 0)
                return Results.BadRequest("No file provided.");

            var allowedTypes = new[] { "image/jpeg", "image/png", "image/webp" };
            if (!allowedTypes.Contains(file.ContentType.ToLower()))
                return Results.BadRequest("Only JPEG, PNG, or WebP images are accepted.");

            var user = await db.UserAccounts.FirstOrDefaultAsync(x => x.Id == userId, ct);
            if (user is null)
                return Results.NotFound();

            await using var stream = file.OpenReadStream();
            var url = await imageService.UploadImageAsync(stream, file.FileName, "swift-shopper/avatars", ct);

            user.AvatarUrl = url;
            await db.SaveChangesAsync(ct);

            return Results.Ok(new { avatarUrl = url });
        })
        .RequireAuthorization()
        .DisableAntiforgery()
        .WithTags("Upload")
        .WithSummary("Upload a profile picture for the current user and store the URL.");

        // PATCH /api/users/me/location — update the authenticated user's GPS coordinates
        app.MapPatch("/api/users/me/location", async (
            UpdateUserLocationDto dto,
            ClaimsPrincipal principal,
            ISwiftShopperService service,
            CancellationToken ct) =>
        {
            var userId = principal.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId)) return Results.Unauthorized();

            await service.UpdateUserLocationAsync(userId, dto.Latitude, dto.Longitude, ct);
            return Results.Ok(new { latitude = dto.Latitude, longitude = dto.Longitude });
        })
        .RequireAuthorization()
        .WithName("UpdateUserLocation");
    }
}
