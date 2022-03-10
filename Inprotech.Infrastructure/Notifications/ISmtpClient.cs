using System.Net.Mail;
using System.Threading.Tasks;

namespace Inprotech.Infrastructure.Notifications
{
    public interface ISmtpClient
    {
        Task SendAsync(MailMessage message);
    }
}
