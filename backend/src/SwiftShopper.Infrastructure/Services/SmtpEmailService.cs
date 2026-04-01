using System.Net;
using System.Net.Mail;
using SwiftShopper.Application.Abstractions;
using SwiftShopper.Infrastructure.Configuration;

namespace SwiftShopper.Infrastructure.Services;

public class SmtpEmailService : IEmailService
{
    private readonly MailConfigurationViewModel _config;

    public SmtpEmailService(MailConfigurationViewModel config)
    {
        _config = config;
    }

    public async Task SendSignupOtpAsync(
        string recipientEmail,
        string recipientName,
        string otpCode,
        DateTimeOffset expiresAt,
        CancellationToken cancellationToken)
    {
        using var message = new MailMessage
        {
            From = new MailAddress(_config.SenderUserName, _config.MailCaption),
            Subject = "Your SwiftShopper verification code",
            Body = BuildSignupOtpBody(recipientName, otpCode, expiresAt),
            IsBodyHtml = true
        };

        if (!string.IsNullOrWhiteSpace(_config.SenderEmail)
            && !string.Equals(_config.SenderEmail, _config.SenderUserName, StringComparison.OrdinalIgnoreCase))
        {
            message.ReplyToList.Add(new MailAddress(_config.SenderEmail, _config.MailCaption));
        }

        message.To.Add(recipientEmail);

        using var client = new SmtpClient(_config.SmtpClient, _config.SmtpPort)
        {
            EnableSsl = _config.EnableSsl,
            Credentials = new NetworkCredential(
                _config.SenderUserName,
                _config.SenderPassword)
        };

        cancellationToken.ThrowIfCancellationRequested();
        await client.SendMailAsync(message, cancellationToken);
    }

    private string BuildSignupOtpBody(
        string recipientName,
        string otpCode,
        DateTimeOffset expiresAt)
    {
        var expiryText = expiresAt.ToLocalTime().ToString("f");
        var frontendUrl = string.IsNullOrWhiteSpace(_config.BaseFrontendURL)
            ? string.Empty
            : $"<p>You can continue in the app or visit <a href=\"{_config.BaseFrontendURL}\">{_config.BaseFrontendURL}</a>.</p>";

        return $"""
            <div style=\"font-family:Arial,sans-serif;color:#1f2937;line-height:1.6;\">
              <h2 style=\"color:#0CAF60;\">{_config.MailCaption}</h2>
              <p>Hello {WebUtility.HtmlEncode(recipientName)},</p>
              <p>Your one-time verification code is:</p>
              <p style=\"font-size:28px;font-weight:700;letter-spacing:6px;\">{WebUtility.HtmlEncode(otpCode)}</p>
              <p>This code expires at {WebUtility.HtmlEncode(expiryText)}.</p>
              <p>If you did not request this code, you can ignore this email.</p>
              {frontendUrl}
            </div>
            """;
    }
}
