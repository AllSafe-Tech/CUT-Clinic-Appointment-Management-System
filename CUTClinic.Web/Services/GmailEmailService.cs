
using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Configuration;
using MimeKit;

namespace CUTClinic.Web.Services;

/// <summary>
/// Sends email messages through Gmail SMTP.
/// Credentials are read from ASP.NET Core User Secrets
/// or another configured secure configuration provider.
/// </summary>
public sealed class GmailEmailService
{
    private readonly IConfiguration _configuration;

    public GmailEmailService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    /// <summary>
    /// Sends an email to a student.
    /// This method reports success only after Gmail accepts the message.
    /// Gmail acceptance does not guarantee delivery to the inbox.
    /// </summary>
    public async Task SendEmailAsync(
        string recipientEmail,
        string subject,
        string messageBody,
        CancellationToken cancellationToken = default)
    {
        // Validate the input before attempting to send the email.
        if (string.IsNullOrWhiteSpace(recipientEmail))
        {
            throw new ArgumentException(
                "A recipient email address is required.",
                nameof(recipientEmail));
        }

        if (string.IsNullOrWhiteSpace(subject))
        {
            throw new ArgumentException(
                "An email subject is required.",
                nameof(subject));
        }

        if (string.IsNullOrWhiteSpace(messageBody))
        {
            throw new ArgumentException(
                "An email message is required.",
                nameof(messageBody));
        }

        // Read Gmail settings from User Secrets or other configuration.
        string host = GetRequiredSetting("Email:Host");
        string username = GetRequiredSetting("Email:Username");
        string password = GetRequiredSetting("Email:Password");
        string fromAddress = GetRequiredSetting("Email:FromAddress");
        string fromName = GetRequiredSetting("Email:FromName");

        int port = _configuration.GetValue<int?>("Email:Port")
            ?? throw new InvalidOperationException(
                "Email:Port is missing from configuration.");

        // Construct the email message.
        var email = new MimeMessage();

        email.From.Add(new MailboxAddress(fromName, fromAddress));
        email.To.Add(MailboxAddress.Parse(recipientEmail));
        email.Subject = subject;

        // Use plain text so the appointment details remain readable
        // in common email clients.
        email.Body = new TextPart("plain")
        {
            Text = messageBody
        };

        // Create a fresh SMTP connection for this message.
        // STARTTLS encrypts the connection after connecting to port 587.
        using var smtpClient = new SmtpClient();

        await smtpClient.ConnectAsync(
            host,
            port,
            SecureSocketOptions.StartTls,
            cancellationToken);

        try
        {
            // Authenticate using the Google App Password,
            // not the normal Gmail account password.
            await smtpClient.AuthenticateAsync(
                username,
                password,
                cancellationToken);

            // Gmail must accept the message before this method completes.
            await smtpClient.SendAsync(email, cancellationToken);
        }
        finally
        {
            // Disconnect cleanly when possible.
            if (smtpClient.IsConnected)
            {
                await smtpClient.DisconnectAsync(
                    true,
                    cancellationToken);
            }
        }
    }

    /// <summary>
    /// Gets a required configuration setting and provides a safe
    /// error message without exposing its value.
    /// </summary>
    private string GetRequiredSetting(string key)
    {
        string? value = _configuration[key];

        if (string.IsNullOrWhiteSpace(value))
        {
            throw new InvalidOperationException(
                $"Required configuration setting '{key}' is missing.");
        }

        return value;
    }
}
