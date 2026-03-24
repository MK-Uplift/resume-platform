using Microsoft.EntityFrameworkCore;
using Resume.Api.Data;
using Resume.Api.Models;
using Amazon.SimpleEmail;
using Amazon.SimpleEmail.Model;
using Amazon;

var builder = WebApplication.CreateBuilder(args);

// Add CORS - Allow all origins for testing (TODO: restrict in production)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowBlazor", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Add SES client (Sydney region - SES not available in ap-southeast-4)
// Use no-arg constructor so it picks up ECS task role credentials automatically
builder.Services.AddSingleton<IAmazonSimpleEmailService>(_ =>
    new AmazonSimpleEmailServiceClient(RegionEndpoint.APSoutheast2));

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
app.MapPost("/api/messages", async (ContactMessage message, AppDbContext db, IAmazonSimpleEmailService ses, ILogger<Program> logger) =>
{
    message.CreatedAt = DateTime.UtcNow;
    db.Messages.Add(message);
    await db.SaveChangesAsync();

    // Send email notification via SES
    try
    {
        logger.LogInformation("Sending SES email for message from {Name}", message.Name);
        await ses.SendEmailAsync(new SendEmailRequest
        {
            Source = "mkuplift11@gmail.com",
            Destination = new Destination { ToAddresses = ["mkuplift11@gmail.com"] },
            Message = new Message
            {
                Subject = new Content($"Resume Contact: {message.Name}"),
                Body = new Body
                {
                    Text = new Content(
                        $"New message from your resume website:\n\n" +
                        $"Name: {message.Name}\n" +
                        $"Email: {message.Email}\n" +
                        $"Message: {message.Message}\n\n" +
                        $"Sent at: {message.CreatedAt:yyyy-MM-dd HH:mm} UTC"
                    )
                }
            }
        });
        logger.LogInformation("SES email sent successfully for {Name}", message.Name);
    }
    catch (Exception ex)
    {
        logger.LogWarning("SES email failed: {Error} | StackTrace: {Stack}", ex.Message, ex.StackTrace);
    }

    return Results.Created($"/api/messages/{message.Id}", message);
})
.WithName("CreateMessage")
.WithOpenApi();

app.Run();
