using Microsoft.EntityFrameworkCore;
using Resume.Api.Data;
using Resume.Api.Models;

var builder = WebApplication.CreateBuilder(args);

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowBlazor", policy =>
    {
        policy.WithOrigins(
            "http://localhost:5000",
            "https://localhost:5001",
            "https://ddcfte7n5r9tt.cloudfront.net"
        )
        .AllowAnyMethod()
        .AllowAnyHeader();
    });
});

// Add DbContext
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowBlazor");
app.UseHttpsRedirection();

// Health check endpoint
app.MapGet("/health", () => Results.Ok(new { status = "ok" }))
    .WithName("HealthCheck")
    .WithOpenApi();

// Get all messages
app.MapGet("/api/messages", async (AppDbContext db) =>
{
    var messages = await db.Messages
        .OrderByDescending(m => m.CreatedAt)
        .ToListAsync();
    return Results.Ok(messages);
})
.WithName("GetMessages")
.WithOpenApi();

// Post a new message
app.MapPost("/api/messages", async (ContactMessage message, AppDbContext db) =>
{
    message.CreatedAt = DateTime.UtcNow;
    db.Messages.Add(message);
    await db.SaveChangesAsync();
    return Results.Created($"/api/messages/{message.Id}", message);
})
.WithName("CreateMessage")
.WithOpenApi();

app.Run();
