namespace SwiftShopper.Api.Authentication;

public class JwtTokenOptions
{
    public const string SectionName = "Jwt";

    public string Issuer { get; init; } = "SwiftShopper";

    public string Audience { get; init; } = "SwiftShopper.Mobile";

    public string SigningKey { get; init; } = "ChangeThisToALongSecureKeyAtLeast32Chars";

    public int AccessTokenLifetimeDays { get; init; } = 30;
}
