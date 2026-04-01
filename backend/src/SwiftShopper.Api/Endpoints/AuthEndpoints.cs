using SwiftShopper.Application.Abstractions;
using SwiftShopper.Application.Contracts.Requests;
using SwiftShopper.Application.Contracts.Responses;
using SwiftShopper.Api.Authentication;
using Microsoft.Extensions.Options;

namespace SwiftShopper.Api.Endpoints;

public static class AuthEndpoints
{
    public static RouteGroupBuilder MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auth").WithTags("Auth");

        group.MapPost("/register/customer", async (
            RegisterUserDto request,
            ISwiftShopperService service,
            IOptions<SignupOtpOptions> otpOptions,
            CancellationToken cancellationToken) =>
        {
            if (!IsValidRegistrationRequest(request, out var validationError))
            {
                return Results.BadRequest(validationError);
            }

            try
            {
                var challenge = await service.RegisterCustomerAsync(request, cancellationToken);
                return Results.Created(
                    $"/api/auth/users/{challenge.UserId}",
                    SanitizeChallenge(challenge, otpOptions.Value));
            }
            catch (InvalidOperationException ex)
            {
                return Results.Conflict(ex.Message);
            }
        });

        group.MapPost("/register/shopper", async (
            RegisterUserDto request,
            ISwiftShopperService service,
            IOptions<SignupOtpOptions> otpOptions,
            CancellationToken cancellationToken) =>
        {
            if (!IsValidRegistrationRequest(request, out var validationError))
            {
                return Results.BadRequest(validationError);
            }

            try
            {
                var challenge = await service.RegisterShopperAsync(request, cancellationToken);
                return Results.Created(
                    $"/api/auth/users/{challenge.UserId}",
                    SanitizeChallenge(challenge, otpOptions.Value));
            }
            catch (InvalidOperationException ex)
            {
                return Results.Conflict(ex.Message);
            }
        });

        group.MapPost("/login", async (
            LoginUserDto request,
            ISwiftShopperService service,
            IJwtTokenService tokenService,
            CancellationToken cancellationToken) =>
        {
            if (!IsValidLoginRequest(request, out var validationError))
            {
                return Results.BadRequest(validationError);
            }

            var user = await service.LoginAsync(request, cancellationToken);
            if (user is null)
            {
                return Results.Unauthorized();
            }

            var session = tokenService.CreateSession(user);
            return Results.Ok(session);
        });

        group.MapPost("/resend-otp", async (
            ResendSignupOtpDto request,
            ISwiftShopperService service,
            IOptions<SignupOtpOptions> otpOptions,
            CancellationToken cancellationToken) =>
        {
            if (string.IsNullOrWhiteSpace(request.UserId))
            {
                return Results.BadRequest("User ID is required.");
            }

            var challenge = await service.ResendSignupOtpAsync(request, cancellationToken);
            if (challenge is null)
            {
                return Results.BadRequest("Unable to resend OTP for this user.");
            }

            return Results.Ok(SanitizeChallenge(challenge, otpOptions.Value));
        });

        group.MapPost("/verify-otp", async (
            VerifySignupOtpDto request,
            ISwiftShopperService service,
            IJwtTokenService tokenService,
            CancellationToken cancellationToken) =>
        {
            if (!IsValidOtpVerificationRequest(request, out var validationError))
            {
                return Results.BadRequest(validationError);
            }

            var user = await service.VerifySignupOtpAsync(request, cancellationToken);
            if (user is null)
            {
                return Results.BadRequest("Invalid or expired OTP.");
            }

            var session = tokenService.CreateSession(user);
            return Results.Ok(session);
        });

        return group;
    }

    private static bool IsValidRegistrationRequest(RegisterUserDto request, out string error)
    {
        if (string.IsNullOrWhiteSpace(request.FullName))
        {
            error = "Full name is required.";
            return false;
        }

        if (string.IsNullOrWhiteSpace(request.Email) || !request.Email.Contains('@'))
        {
            error = "A valid email is required.";
            return false;
        }

        if (string.IsNullOrWhiteSpace(request.PhoneNumber))
        {
            error = "Phone number is required.";
            return false;
        }

        if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 6)
        {
            error = "Password must be at least 6 characters.";
            return false;
        }

        error = string.Empty;
        return true;
    }

    private static bool IsValidLoginRequest(LoginUserDto request, out string error)
    {
        if (string.IsNullOrWhiteSpace(request.EmailOrPhoneNumber))
        {
            error = "Email or phone number is required.";
            return false;
        }

        if (string.IsNullOrWhiteSpace(request.Password))
        {
            error = "Password is required.";
            return false;
        }

        error = string.Empty;
        return true;
    }

    private static bool IsValidOtpVerificationRequest(VerifySignupOtpDto request, out string error)
    {
        if (string.IsNullOrWhiteSpace(request.UserId))
        {
            error = "User ID is required.";
            return false;
        }

        if (string.IsNullOrWhiteSpace(request.OtpCode) || request.OtpCode.Length != 4)
        {
            error = "A valid 4-digit OTP is required.";
            return false;
        }

        error = string.Empty;
        return true;
    }

    private static SignupOtpChallengeDto SanitizeChallenge(
        SignupOtpChallengeDto challenge,
        SignupOtpOptions options)
    {
        if (options.ExposeDevelopmentOtp)
        {
            return challenge;
        }

        return new SignupOtpChallengeDto
        {
            UserId = challenge.UserId,
            Email = challenge.Email,
            PhoneNumber = challenge.PhoneNumber,
            Role = challenge.Role,
            ExpiresAt = challenge.ExpiresAt,
            DevelopmentOtpCode = null
        };
    }
}
