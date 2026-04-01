namespace SwiftShopper.Infrastructure.Configuration;

public class MailConfigurationViewModel
{
    public const string SectionName = "MailConfigurationViewModel";

    public string SmtpClient { get; init; } = string.Empty;

    public bool EnableSsl { get; init; }

    public int SmtpPort { get; init; }

    public string SenderEmail { get; init; } = string.Empty;

    public string MailCaption { get; init; } = string.Empty;

    public string SenderUserName { get; init; } = string.Empty;

    public string SenderPassword { get; init; } = string.Empty;

    public string BaseFrontendURL { get; init; } = string.Empty;
}
