using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace SwiftShopper.Infrastructure.Persistence;

public class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<SwiftShopperDbContext>
{
    public SwiftShopperDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<SwiftShopperDbContext>();

        const string connectionString =
            "Data Source=173.208.144.83,1431;Initial Catalog=swiftshopper;User ID=sa;Password=godp1234#;Integrated Security=False;TrustServerCertificate=True;";

        optionsBuilder.UseSqlServer(connectionString);

        return new SwiftShopperDbContext(optionsBuilder.Options);
    }
}
