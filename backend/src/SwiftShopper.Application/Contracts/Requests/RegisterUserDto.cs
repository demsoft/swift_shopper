namespace SwiftShopper.Application.Contracts.Requests;

public class RegisterUserDto
{
    public required string FullName { get; init; }

    public required string Email { get; init; }

    public required string PhoneNumber { get; init; }

    public required string Password { get; init; }
}
