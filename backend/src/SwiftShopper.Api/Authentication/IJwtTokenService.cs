using SwiftShopper.Application.Contracts.Responses;

namespace SwiftShopper.Api.Authentication;

public interface IJwtTokenService
{
    AuthSessionDto CreateSession(AuthenticatedUserDto user);
}
