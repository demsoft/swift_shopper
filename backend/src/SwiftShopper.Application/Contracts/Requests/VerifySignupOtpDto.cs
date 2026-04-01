namespace SwiftShopper.Application.Contracts.Requests;

public class VerifySignupOtpDto
{
    public required string UserId { get; init; }

    public required string OtpCode { get; init; }
}
