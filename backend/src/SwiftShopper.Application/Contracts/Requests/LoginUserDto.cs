namespace SwiftShopper.Application.Contracts.Requests;

public class LoginUserDto
{
    public required string EmailOrPhoneNumber { get; init; }

    public required string Password { get; init; }
}
