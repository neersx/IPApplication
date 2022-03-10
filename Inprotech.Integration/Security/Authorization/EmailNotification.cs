using System.Net.Mail;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Notifications;

namespace Inprotech.Integration.Security.Authorization
{
    public interface IEmailNotification
    {
        Task Send(Notification notification);
    }

    public class EmailNotification : IEmailNotification
    {
        readonly ISmtpClient _smtpClient;

        public EmailNotification(ISmtpClient smtpClient)
        {
            _smtpClient = smtpClient;
        }

        public async Task Send(Notification notification)
        {
            var message = new MailMessage
            {
                From = new MailAddress(notification.From),
                Subject = notification.Subject,
                Body = notification.Body,
                IsBodyHtml = notification.IsBodyHtml
            };

            foreach (var recipient in notification.EmailRecipient)
                message.To.Add(recipient.Email);

            foreach (var recipient in notification.CcEmailRecipient)
                message.CC.Add(recipient.Email);

            await _smtpClient.SendAsync(message);
        }
    }
}