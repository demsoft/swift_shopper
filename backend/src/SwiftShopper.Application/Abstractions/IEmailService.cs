namespace SwiftShopper.Application.Abstractions;

public interface IEmailService
{
    Task SendSignupOtpAsync(
        string recipientEmail,
        string recipientName,
        string otpCode,
        DateTimeOffset expiresAt,
        CancellationToken cancellationToken);
}
