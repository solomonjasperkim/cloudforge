using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

var dbHost = Environment.GetEnvironmentVariable("DB_HOST") ?? "localhost";
var dbPort = Environment.GetEnvironmentVariable("DB_PORT") ?? "5432";
var dbName = Environment.GetEnvironmentVariable("DB_NAME") ?? "cloudforge";
var dbUser = Environment.GetEnvironmentVariable("DB_USER") ?? "cloudforge";
var dbPassword = Environment.GetEnvironmentVariable("DB_PASSWORD") ?? "cloudforge";
var connectionString = $"Host={dbHost};Port={dbPort};Database={dbName};Username={dbUser};Password={dbPassword}";

builder.Services.AddDbContext<AppDbContext>(options => options.UseNpgsql(connectionString));
builder.Services.AddHealthChecks();

var app = builder.Build();

app.MapGet("/", () => Results.Ok(new { service = "cloudforge-api", status = "ok" }));
app.MapHealthChecks("/health");

app.MapGet("/api/tasks", async (AppDbContext db) =>
    Results.Ok(await db.Tasks.AsNoTracking().OrderByDescending(x => x.CreatedAt).ToListAsync()));

app.MapGet("/api/tasks/{id:guid}", async (Guid id, AppDbContext db) =>
    await db.Tasks.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id) is { } task
        ? Results.Ok(task)
        : Results.NotFound());

app.MapPost("/api/tasks", async (CreateTaskRequest request, AppDbContext db) =>
{
    var task = new WorkTask
    {
        Id = Guid.NewGuid(),
        Title = request.Title.Trim(),
        Completed = false,
        CreatedAt = DateTimeOffset.UtcNow
    };

    db.Tasks.Add(task);
    await db.SaveChangesAsync();
    return Results.Created($"/api/tasks/{task.Id}", task);
});

app.MapPut("/api/tasks/{id:guid}", async (Guid id, UpdateTaskRequest request, AppDbContext db) =>
{
    var task = await db.Tasks.FindAsync(id);
    if (task is null) return Results.NotFound();

    task.Title = request.Title.Trim();
    task.Completed = request.Completed;
    await db.SaveChangesAsync();
    return Results.Ok(task);
});

app.MapDelete("/api/tasks/{id:guid}", async (Guid id, AppDbContext db) =>
{
    var task = await db.Tasks.FindAsync(id);
    if (task is null) return Results.NotFound();

    db.Tasks.Remove(task);
    await db.SaveChangesAsync();
    return Results.NoContent();
});

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.EnsureCreatedAsync();
}

app.Run();

record CreateTaskRequest(string Title);
record UpdateTaskRequest(string Title, bool Completed);

sealed class WorkTask
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public bool Completed { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

sealed class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<WorkTask> Tasks => Set<WorkTask>();
}
