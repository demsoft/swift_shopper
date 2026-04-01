using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SwiftShopper.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddGpsCoordinates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<double>(
                name: "Latitude",
                table: "UserAccounts",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "Longitude",
                table: "UserAccounts",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "Latitude",
                table: "Markets",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "Longitude",
                table: "Markets",
                type: "float",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Latitude",
                table: "UserAccounts");

            migrationBuilder.DropColumn(
                name: "Longitude",
                table: "UserAccounts");

            migrationBuilder.DropColumn(
                name: "Latitude",
                table: "Markets");

            migrationBuilder.DropColumn(
                name: "Longitude",
                table: "Markets");
        }
    }
}
