using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Notifications.Security;
using Inprotech.Infrastructure.Policy;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Properties;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Integration.Security.Authorization
{
    public class ExpiringLicenses
    {
        readonly IEmailNotification _emailNotifier;
        readonly ILicenses _licenses;
        readonly IPopupNotification _popupNotifier;
        readonly ISiteControlReader _siteControls;
        readonly ISiteDateFormat _siteDateFormat;
        readonly IUserAdministrators _userAdministrators;

        public ExpiringLicenses(ILicenses licenses, IUserAdministrators userAdministrators, IEmailNotification emailNotifier, IPopupNotification popupNotifier, ISiteDateFormat siteDateFormat, ISiteControlReader siteControls)
        {
            _licenses = licenses;
            _userAdministrators = userAdministrators;
            _emailNotifier = emailNotifier;
            _popupNotifier = popupNotifier;
            _siteDateFormat = siteDateFormat;
            _siteControls = siteControls;
        }

        public async Task<Activity> CheckAndNotify()
        {
            var expiring = (await _licenses.Expiring()).ToArray();

            if (!expiring.Any()) return DefaultActivity.NoOperation();

            var notification = new Notification
                               {
                                   Subject = Alerts.LicenseExpiry_Title,
                                   Body = GetBody(expiring)
                               };

            notification.EmailRecipient.AddRange(_userAdministrators.Resolve());

            if (!notification.EmailRecipient.Any())
                throw new Exception(Alerts.LicenseExpiry_UnableToNotify);

            var notifyByEmail = Activity.Run<ExpiringLicenses>(_ => _.NotifyByEmail(notification));

            var notifyOnScreen = Activity.Run<ExpiringLicenses>(_ => _.NotifyOnScreen(notification));

            return Activity.Parallel(notifyByEmail, notifyOnScreen);
        }

        public async Task NotifyByEmail(Notification notification)
        {
            var notificationObj = new Notification
            {
                From = _siteControls.Read<string>(SiteControls.ProductSupportEmail),
                Subject = notification.Subject,
                Body = notification.Body
            };
            notificationObj.EmailRecipient.AddRange(notification.EmailRecipient);

            await _emailNotifier.Send(notificationObj);
        }

        public async Task NotifyOnScreen(Notification notification)
        {
            await _popupNotifier.Send(notification);
        }

        string GetBody(IEnumerable<ExpiringLicense> expiringLicenses)
        {
            var dateFormat = _siteDateFormat.Resolve();

            var message = new StringBuilder(Alerts.LicenseExpiry_ModuleList);
            message.AppendLine();
            message.AppendLine();
            message.AppendLine();

            foreach (var module in expiringLicenses)
            {
                message.AppendFormat("\t" + Alerts.LicenseExpiry_ModuleItem, module.Module, module.ExpiryDate.ToString(dateFormat));

                message.AppendLine();
                message.AppendLine();
            }

            message.AppendLine();
            message.Append(Alerts.LicenseExpiry_Explanation);
            message.AppendLine();
            message.AppendLine();
            message.Append(Alerts.LicenseExpiry_Extension);
            message.AppendLine();

            return message.ToString();
        }
    }
}