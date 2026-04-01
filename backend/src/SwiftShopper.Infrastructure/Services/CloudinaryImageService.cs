using CloudinaryDotNet;
using CloudinaryDotNet.Actions;
using Microsoft.Extensions.Configuration;
using SwiftShopper.Application.Abstractions;

namespace SwiftShopper.Infrastructure.Services;

public class CloudinaryImageService : IImageService
{
    private readonly Cloudinary _cloudinary;

    public CloudinaryImageService(IConfiguration configuration)
    {
        var cloudName = configuration["CloudinarySettings:CloudName"]
            ?? throw new InvalidOperationException("CloudinarySettings:CloudName is not configured.");
        var apiKey = configuration["CloudinarySettings:ApiKey"]
            ?? throw new InvalidOperationException("CloudinarySettings:ApiKey is not configured.");
        var apiSecret = configuration["CloudinarySettings:ApiSecret"]
            ?? throw new InvalidOperationException("CloudinarySettings:ApiSecret is not configured.");

        _cloudinary = new Cloudinary(new Account(cloudName, apiKey, apiSecret))
        {
            Api = { Secure = true }
        };
    }

    public async Task<string> UploadImageAsync(
        Stream stream, string fileName, string folder = "swift-shopper", CancellationToken ct = default)
    {
        var uploadParams = new ImageUploadParams
        {
            File = new FileDescription(fileName, stream),
            Folder = folder,
            UseFilename = false,
            UniqueFilename = true,
            Overwrite = false,
        };

        var result = await _cloudinary.UploadAsync(uploadParams, ct);

        if (result.Error is not null)
            throw new InvalidOperationException($"Cloudinary upload failed: {result.Error.Message}");

        return result.SecureUrl.ToString();
    }
}
