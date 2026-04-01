using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using SwiftShopper.Api.Authentication;
using SwiftShopper.Api.Configuration;
using SwiftShopper.Api.Endpoints;
using SwiftShopper.Api.Hubs;
using SwiftShopper.Api.Swagger;
using SwiftShopper.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSignalR();
builder.Services.AddSwaggerGen();
builder.Services.ConfigureOptions<ConfigureSwaggerOptions>();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.Configure<JwtTokenOptions>(
	builder.Configuration.GetSection(JwtTokenOptions.SectionName));
builder.Services.Configure<SignupOtpOptions>(
	builder.Configuration.GetSection(SignupOtpOptions.SectionName));
builder.Services.AddSingleton<IJwtTokenService, JwtTokenService>();

var jwtOptions = builder.Configuration
	.GetSection(JwtTokenOptions.SectionName)
	.Get<JwtTokenOptions>() ?? new JwtTokenOptions();
var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtOptions.SigningKey));

builder.Services
	.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
	.AddJwtBearer(options =>
	{
		options.TokenValidationParameters = new TokenValidationParameters
		{
			ValidateIssuer = true,
			ValidateAudience = true,
			ValidateIssuerSigningKey = true,
			ValidateLifetime = true,
			ValidIssuer = jwtOptions.Issuer,
			ValidAudience = jwtOptions.Audience,
			IssuerSigningKey = signingKey,
			ClockSkew = TimeSpan.Zero
		};
	});
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy =>
        policy.RequireAuthenticatedUser()
              .RequireRole("Admin"));
});
builder.Services.AddCors(options =>
{
	options.AddPolicy(CorsPolicies.AllowFlutterClients, policy =>
	{
		policy
			.SetIsOriginAllowed(_ => true)
			.AllowAnyHeader()
			.AllowAnyMethod()
			.AllowCredentials();
	});
});

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();

app.UseCors(CorsPolicies.AllowFlutterClients);
app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();

app.MapHealthEndpoints();
app.MapAdminEndpoints();
app.MapMarketsEndpoints();
app.MapUploadEndpoints();
app.MapRequestsEndpoints();
app.MapOrdersEndpoints();
app.MapChatEndpoints();
app.MapPaymentsEndpoints();
app.MapAuthEndpoints();
app.MapHub<ChatHub>("/hubs/chat");

app.Run();
