using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using SwiftShopper.Domain.Entities;

namespace SwiftShopper.Infrastructure.Persistence;

public class SwiftShopperDbContext : DbContext
{
    public SwiftShopperDbContext(DbContextOptions<SwiftShopperDbContext> options)
        : base(options)
    {
    }

    public DbSet<ShoppingRequest> ShoppingRequests => Set<ShoppingRequest>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<ChatMessage> ChatMessages => Set<ChatMessage>();
    public DbSet<UserAccount> UserAccounts => Set<UserAccount>();
    public DbSet<SignupOtpVerification> SignupOtpVerifications => Set<SignupOtpVerification>();
    public DbSet<Market> Markets => Set<Market>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // ── ShoppingRequest ──────────────────────────────────────────────────
        modelBuilder.Entity<ShoppingRequest>(entity =>
        {
            entity.ToTable("ShoppingRequests");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasMaxLength(64);
            entity.Property(x => x.CustomerId).HasMaxLength(64).IsRequired();
            entity.Property(x => x.PreferredStore).HasMaxLength(120).IsRequired();
            entity.Property(x => x.DeliveryAddress).HasMaxLength(400).IsRequired();
            entity.Property(x => x.DeliveryNotes).HasMaxLength(600);
            entity.Property(x => x.Budget).HasColumnType("decimal(18,2)");

            entity.OwnsMany(x => x.Items, item =>
            {
                item.ToTable("RequestItems");
                item.WithOwner().HasForeignKey("ShoppingRequestId");
                item.Property<int>("Id").ValueGeneratedOnAdd();
                item.HasKey("Id");
                item.Property(x => x.Name).HasMaxLength(160).IsRequired();
                item.Property(x => x.Unit).HasMaxLength(80);
                item.Property(x => x.Description).HasMaxLength(400);
                item.Property(x => x.Price).HasColumnType("decimal(18,2)");
                item.Property(x => x.MaxPrice).HasColumnType("decimal(18,2)");
            });
        });

        // ── Order ────────────────────────────────────────────────────────────
        modelBuilder.Entity<Order>(entity =>
        {
            entity.ToTable("Orders");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasMaxLength(64);
            entity.Property(x => x.RequestId).HasMaxLength(64).IsRequired();
            entity.Property(x => x.ShopperId).HasMaxLength(64);
            entity.Property(x => x.ShopperName).HasMaxLength(120);
            entity.Property(x => x.StoreName).HasMaxLength(120);
            entity.Property(x => x.StoreAddress).HasMaxLength(300);
            entity.Property(x => x.ItemsSubtotal).HasColumnType("decimal(18,2)");
            entity.Property(x => x.DeliveryFee).HasColumnType("decimal(18,2)");
            entity.Property(x => x.ServiceFee).HasColumnType("decimal(18,2)");

            // TotalAmount is a computed property — ignore it in the DB
            entity.Ignore(x => x.TotalAmount);

            entity
                .HasOne<ShoppingRequest>()
                .WithMany()
                .HasForeignKey(x => x.RequestId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // ── OrderItem ────────────────────────────────────────────────────────
        modelBuilder.Entity<OrderItem>(entity =>
        {
            entity.ToTable("OrderItems");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedOnAdd();
            entity.Property(x => x.OrderId).HasMaxLength(64).IsRequired();
            entity.Property(x => x.Name).HasMaxLength(160).IsRequired();
            entity.Property(x => x.Unit).HasMaxLength(80);
            entity.Property(x => x.Description).HasMaxLength(400);
            entity.Property(x => x.EstimatedPrice).HasColumnType("decimal(18,2)");
            entity.Property(x => x.FoundPrice).HasColumnType("decimal(18,2)");
            entity.Property(x => x.PhotoUrl).HasMaxLength(1000);

            entity
                .HasOne<Order>()
                .WithMany()
                .HasForeignKey(x => x.OrderId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // ── ChatMessage ──────────────────────────────────────────────────────
        modelBuilder.Entity<ChatMessage>(entity =>
        {
            entity.ToTable("ChatMessages");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasMaxLength(64);
            entity.Property(x => x.OrderId).HasMaxLength(64).IsRequired();
            entity.Property(x => x.Sender).HasMaxLength(32).IsRequired();
            entity.Property(x => x.Type).HasMaxLength(32).IsRequired();
            entity.Property(x => x.Text).HasMaxLength(1000);
            entity.Property(x => x.ImageUrl).HasMaxLength(1000);

            entity.OwnsOne(x => x.PriceCard, pc =>
            {
                pc.Property(x => x.ItemName).HasMaxLength(160);
                pc.Property(x => x.Quantity).HasMaxLength(80);
                pc.Property(x => x.OldPrice).HasColumnType("decimal(18,2)");
                pc.Property(x => x.NewPrice).HasColumnType("decimal(18,2)");
            });

            entity
                .HasOne<Order>()
                .WithMany()
                .HasForeignKey(x => x.OrderId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // ── UserAccount ──────────────────────────────────────────────────────
        modelBuilder.Entity<UserAccount>(entity =>
        {
            entity.ToTable("UserAccounts");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasMaxLength(64);
            entity.Property(x => x.FullName).HasMaxLength(140).IsRequired();
            entity.Property(x => x.Email).HasMaxLength(160).IsRequired();
            entity.Property(x => x.PhoneNumber).HasMaxLength(32).IsRequired();
            entity.Property(x => x.PasswordHash).HasMaxLength(200).IsRequired();
            entity.Property(x => x.PasswordSalt).HasMaxLength(200).IsRequired();

            entity.Property(x => x.AvatarUrl).HasMaxLength(1000);
            entity.Property(x => x.Latitude);
            entity.Property(x => x.Longitude);
            entity.HasIndex(x => x.Email).IsUnique();
            entity.HasIndex(x => x.PhoneNumber).IsUnique();
        });

        // ── SignupOtpVerification ────────────────────────────────────────────
        modelBuilder.Entity<SignupOtpVerification>(entity =>
        {
            entity.ToTable("SignupOtpVerifications");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasMaxLength(64);
            entity.Property(x => x.UserId).HasMaxLength(64).IsRequired();
            entity.Property(x => x.CodeHash).HasMaxLength(200).IsRequired();

            entity
                .HasOne<UserAccount>()
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(x => x.UserId);
        });

        // ── Market ───────────────────────────────────────────────────────────
        modelBuilder.Entity<Market>(entity =>
        {
            entity.ToTable("Markets");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasMaxLength(64);
            entity.Property(x => x.Name).HasMaxLength(160).IsRequired();
            entity.Property(x => x.Type).HasMaxLength(60).IsRequired();
            entity.Property(x => x.Location).HasMaxLength(200);
            entity.Property(x => x.Zone).HasMaxLength(100);
            entity.Property(x => x.Address).HasMaxLength(400);
            entity.Property(x => x.OpeningTime).HasMaxLength(10);
            entity.Property(x => x.ClosingTime).HasMaxLength(10);
            entity.Property(x => x.PhotoUrl).HasMaxLength(1000);
            entity.Property(x => x.Latitude);
            entity.Property(x => x.Longitude);

            // Store categories as a comma-separated string
            var categoriesComparer = new ValueComparer<List<string>>(
                (a, b) => a != null && b != null && a.SequenceEqual(b),
                v => v.Aggregate(0, (h, s) => HashCode.Combine(h, s.GetHashCode())),
                v => v.ToList());

            entity.Property(x => x.Categories)
                .HasConversion(
                    v => string.Join(',', v),
                    v => v.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList())
                .Metadata.SetValueComparer(categoriesComparer);
        });
    }
}
