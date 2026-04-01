using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using SwiftShopper.Application.Contracts.Responses;

namespace SwiftShopper.Api.Authentication;

public class JwtTokenService : IJwtTokenService
{
    private readonly JwtTokenOptions _options;

    public JwtTokenService(IOptions<JwtTokenOptions> options)
    {
        _options = options.Value;
    }

    public AuthSessionDto CreateSession(AuthenticatedUserDto user)
    {
        var now = DateTimeOffset.UtcNow;
        var expiresAt = now.AddDays(_options.AccessTokenLifetimeDays);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.UserId),
            new(JwtRegisteredClaimNames.Email, user.Email),
            new(ClaimTypes.NameIdentifier, user.UserId),
            new(ClaimTypes.Name, user.FullName),
            new(ClaimTypes.MobilePhone, user.PhoneNumber),
            new(ClaimTypes.Role, user.Role.ToString())
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.SigningKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var jwt = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: claims,
            notBefore: now.UtcDateTime,
            expires: expiresAt.UtcDateTime,
            signingCredentials: creds);

        var token = new JwtSecurityTokenHandler().WriteToken(jwt);

        return new AuthSessionDto
        {
            AccessToken = token,
            ExpiresAt = expiresAt,
            User = user
        };
    }
}
