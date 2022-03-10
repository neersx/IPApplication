using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Notifications.Security;
using Inprotech.Integration.Properties;
using Inprotech.Integration.Security.Authorization;

namespace Inprotech.Integration.Notification
{
    public abstract class NotificationBase
    {
        readonly IEmailNotification _emailNotifier;
        readonly IPopupNotification _popupNotifier;
        readonly ISiteControlReader _siteControls;
        readonly IUserAdministrators _userAdministrators;

        protected NotificationBase(IUserAdministrators userAdministrators, IEmailNotification emailNotifier, IPopupNotification popupNotifier, ISiteControlReader siteControls)
        {
            _userAdministrators = userAdministrators;
            _emailNotifier = emailNotifier;
            _popupNotifier = popupNotifier;
            _siteControls = siteControls;
        }

        public async Task NotifyByEmail(Security.Authorization.Notification notification)
        {
            await _emailNotifier.Send(new Security.Authorization.Notification
            {
                From = _siteControls.Read<string>(SiteControls.WorkBenchAdministratorEmail),
                Subject = notification.Subject,
                Body = notification.Body,
                UserAdministrators = notification.UserAdministrators
            });
        }

        public async Task NotifyOnScreen(Security.Authorization.Notification notification)
        {
            await _popupNotifier.Send(notification);
        }
        
        public Task<Activity> NotifyAllConcerned(UserAccountLockedMessage message)
        {
            var notification = new Security.Authorization.Notification
                               {
                                   Subject = string.Format(Alerts.UserAccountLockedTitle, message.Username),
                                   Body = GetBody(message),
                                   UserAdministrators = _userAdministrators.Resolve(message.IdentityId)
                               };

            if (!notification.UserAdministrators.Any())
                throw new Exception(Alerts.UserAccountLocked_UnableToNotify);

            var notifyByEmail = Activity.Run<NotificationBase>(_ => _.NotifyByEmail(notification));

            var notifyOnScreen = Activity.Run<NotificationBase>(_ => _.NotifyOnScreen(notification));

            return Task.FromResult((Activity) Activity.Parallel(notifyByEmail, notifyOnScreen));
        }

      
        static string GetBody(UserAccountLockedMessage details)
        {
            var message = new StringBuilder(Alerts.UserAccountLockedExplanation);
            message.AppendLine();
            message.AppendLine();
            message.AppendFormat("Full Name: {0}", details.DisplayName);
            message.AppendLine();
            message.AppendFormat("User Name: {0}", details.Username);
            message.AppendLine();
            message.AppendFormat("User Email: {0}", details.UserEmail);
            message.AppendLine();
            message.AppendFormat("Date Locked (UTC): {0:U}", details.LockedUtc);
            message.AppendLine();
            message.AppendFormat("Date Locked (Server): {0:F}", details.LockedLocal);
            message.AppendLine();
            message.AppendLine();
            message.AppendLine();
            message.Append("Thank you.");
            message.AppendLine();
            message.Append("Inprotech");
            message.AppendLine();

            return message.ToString();
        }
    }
}
