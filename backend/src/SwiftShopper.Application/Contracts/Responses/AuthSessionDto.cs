namespace SwiftShopper.Application.Contracts.Responses;

public class AuthSessionDto
{
    public required string AccessToken { get; init; }

    public required DateTimeOffset ExpiresAt { get; init; }

    public required AuthenticatedUserDto User { get; init; }
}
