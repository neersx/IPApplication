using System;
using System.Net.Mail;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Notifications;

namespace Inprotech.IntegrationServer.Emails
{
    public class SmtpClient : ISmtpClient
    {
        readonly IBackgroundProcessLogger<SmtpClient> _logger;

        public SmtpClient(IBackgroundProcessLogger<SmtpClient> logger)
        {
            _logger = logger;
        }
        
        public async Task SendAsync(MailMessage message)
        {
            try
            {
                await new System.Net.Mail.SmtpClient().SendMailAsync(message);
            }
            catch (Exception e)
            {
                _logger.Exception(e);
                throw;
            }
        }
    }
}
