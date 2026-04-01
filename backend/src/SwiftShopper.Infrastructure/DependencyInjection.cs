using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using SwiftShopper.Application.Abstractions;
using SwiftShopper.Infrastructure.Configuration;
using SwiftShopper.Infrastructure.Persistence;
using SwiftShopper.Infrastructure.Services;

namespace SwiftShopper.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("DefaultConnection is not configured.");

        services.AddDbContext<SwiftShopperDbContext>(options =>
            options.UseSqlServer(connectionString));

        var mailSection = configuration.GetSection(MailConfigurationViewModel.SectionName);
        var mailConfiguration = new MailConfigurationViewModel
        {
            SmtpClient = mailSection["SmtpClient"] ?? mailSection["smtpClient"] ?? string.Empty,
            EnableSsl = bool.TryParse(mailSection["EnableSsl"] ?? mailSection["enableSsl"], out var enableSsl)
                && enableSsl,
            SmtpPort = int.TryParse(mailSection["SmtpPort"] ?? mailSection["smtpPort"], out var smtpPort)
                ? smtpPort
                : 0,
            SenderEmail = mailSection["SenderEmail"] ?? string.Empty,
            MailCaption = mailSection["MailCaption"] ?? string.Empty,
            SenderUserName = mailSection["SenderUserName"] ?? string.Empty,
            SenderPassword = mailSection["SenderPassword"] ?? string.Empty,
            BaseFrontendURL = mailSection["BaseFrontendURL"] ?? mailSection["baseFrontendURL"] ?? string.Empty,
        };

        services.AddSingleton(mailConfiguration);
        services.AddScoped<IEmailService, SmtpEmailService>();
        services.AddScoped<ISwiftShopperService, DbSwiftShopperService>();
        services.AddScoped<IImageService, CloudinaryImageService>();

        return services;
    }
}
