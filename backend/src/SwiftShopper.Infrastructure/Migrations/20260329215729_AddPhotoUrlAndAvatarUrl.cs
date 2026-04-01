using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SwiftShopper.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddPhotoUrlAndAvatarUrl : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AvatarUrl",
                table: "UserAccounts",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PhotoUrl",
                table: "Markets",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AvatarUrl",
                table: "UserAccounts");

            migrationBuilder.DropColumn(
                name: "PhotoUrl",
                table: "Markets");
        }
    }
}
