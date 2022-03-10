using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Notifications;

namespace Inprotech.Integration.Security.Authorization
{
    public interface IPopupNotification
    {
        Task Send(Notification notification);
    }

    public class PopupNotification : IPopupNotification
    {
        readonly IBackgroundProcessMessageClient _messageClient;

        public PopupNotification(IBackgroundProcessMessageClient messageClient)
        {
            _messageClient = messageClient;
        }

        public async Task Send(Notification notification)
        {
            foreach (var admin in notification.EmailRecipient)
            {
                var message = new BackgroundProcessMessage
                              {
                                  ProcessType = BackgroundProcessType.UserAdministration,
                                  StatusType = StatusType.Information,
                                  IdentityId = admin.Id,
                                  Message = notification.Subject + Environment.NewLine + notification.Body
                              };

                await _messageClient.SendAsync(message);
            }
        }
    }
}