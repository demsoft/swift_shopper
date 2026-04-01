namespace SwiftShopper.Application.Abstractions;

public interface IImageService
{
    /// <summary>
    /// Uploads an image stream to Cloudinary and returns the secure URL.
    /// </summary>
    Task<string> UploadImageAsync(Stream stream, string fileName, string folder = "swift-shopper", CancellationToken ct = default);
}
