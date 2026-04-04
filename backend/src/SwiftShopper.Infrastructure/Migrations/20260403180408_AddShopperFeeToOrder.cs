using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SwiftShopper.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddShopperFeeToOrder : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "ShopperFee",
                table: "Orders",
                type: "decimal(18,2)",
                nullable: false,
                defaultValue: 0m);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ShopperFee",
                table: "Orders");
        }
    }
}
