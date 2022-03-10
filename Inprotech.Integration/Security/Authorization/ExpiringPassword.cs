using Dependable;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Notifications.Security;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Properties;
using InprotechKaizen.Model.Components.Security;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Inprotech.Integration.Security.Authorization
{
    public class ExpiringPassword
    {
        readonly IEmailNotification _emailNotifier;
        readonly ISiteControlReader _siteControls;
        readonly IUserPasswordExpiryValidator _userPasswordExpiryValidator;

        public ExpiringPassword(IEmailNotification emailNotifier, 
                                ISiteControlReader siteControls, IUserPasswordExpiryValidator userPasswordExpiryValidator)
        {
            _emailNotifier = emailNotifier;
            _siteControls = siteControls;
            _userPasswordExpiryValidator = userPasswordExpiryValidator;
        }

        public async Task<Activity> CheckAndNotify()
        {
            var enforcePasswordPolicy = _siteControls.Read<bool>(SiteControls.EnforcePasswordPolicy);
            var passwordExpiryDuration = _siteControls.Read<int?>(SiteControls.PasswordExpiryDuration) ?? 0;
            if (!enforcePasswordPolicy || passwordExpiryDuration <= 0) 
                return DefaultActivity.NoOperation();

            var usersWithPasswordDate = await _userPasswordExpiryValidator.Resolve(passwordExpiryDuration);

            var userPasswordExpiryDetails = usersWithPasswordDate as UserPasswordExpiryDetails[] ?? usersWithPasswordDate.ToArray();
            var notifications = new List<Notification>();
            foreach (var userPasswordExpiryDetail in userPasswordExpiryDetails)
            {
                var notification = new Notification
                {
                    Subject = Alerts.PasswordExpiry_Title,
                    Body = userPasswordExpiryDetail.EmailBody,
                    IsBodyHtml = EmailHelper.HasHtmlTags(userPasswordExpiryDetail.EmailBody)
                };
                notification.EmailRecipient.Add(new UserEmail { Email = userPasswordExpiryDetail.Email, Id = userPasswordExpiryDetail.Id });
                notifications.Add(notification);
            }

            var listOfActivities = notifications.Select(notification => Activity.Run<ExpiringPassword>(_ => _.NotifyByEmail(notification))).Cast<Activity>().ToList();
            return Activity.Sequence(listOfActivities);
        }

        public async Task NotifyByEmail(Notification notification)
        {
            notification.From = _siteControls.Read<string>(SiteControls.ProductSupportEmail);
            await _emailNotifier.Send(notification);
        }
    }
}
