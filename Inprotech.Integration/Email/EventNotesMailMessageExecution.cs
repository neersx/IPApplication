using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts.Messages;
using Inprotech.Infrastructure.Notifications.Security;
using Inprotech.Integration.Security.Authorization;

namespace Inprotech.Integration.Email
{
    public class EventNotesMailMessageExecution
    {
        readonly IEmailNotification _emailNotifier;

        public EventNotesMailMessageExecution(IEmailNotification emailNotifier)
        {
            _emailNotifier = emailNotifier;
        }

        public Task<Activity> EmailUser(EventNotesMailMessage simpleMailMessage)
        {
            var notification = new Notification
            {
                From = simpleMailMessage.From,
                Subject = simpleMailMessage.Subject,
                Body = simpleMailMessage.Body,
                IsBodyHtml = true
            };

            notification.EmailRecipient.Add(new UserEmail { Email = simpleMailMessage.To });

            if (!string.IsNullOrEmpty(simpleMailMessage.Cc))
                notification.CcEmailRecipient.Add(new UserEmail { Email = simpleMailMessage.Cc });

            var notifyByEmail = Activity.Run<EventNotesMailMessageExecution>(_ => _.NotifyByEmail(notification));

            return Task.FromResult((Activity) notifyByEmail);
        }

        public async Task NotifyByEmail(Notification notification)
        {
            await _emailNotifier.Send(notification);
        }
    }
}
