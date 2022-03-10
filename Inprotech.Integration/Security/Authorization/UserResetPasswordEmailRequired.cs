using Dependable;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Notifications.Security;
using System.Threading.Tasks;

namespace Inprotech.Integration.Security.Authorization
{
    public class UserResetPasswordEmailRequired
    {
        readonly IEmailNotification _emailNotifier;
        readonly ISiteControlReader _siteControls;

        public UserResetPasswordEmailRequired(IEmailNotification emailNotifier, ISiteControlReader siteControls)
        {
            _emailNotifier = emailNotifier;
            _siteControls = siteControls;
        }

        public Task<Activity> EmailUser(UserResetPasswordMessage message)
        {
            var notification = new Notification
            {
                Subject = message.UserResetPassword,
                Body = message.EmailBody,
                IsBodyHtml = true
            };

            notification.EmailRecipient.Add( new UserEmail { Email = message.UserEmail, Id = message.IdentityId } );

            var notifyByEmail = Activity.Run<UserResetPasswordEmailRequired>(_ => _.NotifyByEmail(notification));

            return Task.FromResult((Activity) notifyByEmail);
        }

        public async Task NotifyByEmail(Notification notification)
        {
            var fromEmail = _siteControls.Read<string>(SiteControls.WorkBenchAdministratorEmail);
            if (string.IsNullOrWhiteSpace(fromEmail))
            {
                fromEmail = "noreply@inprotech";
            }

            notification.From = fromEmail;

            await _emailNotifier.Send(notification);
        }
    }
}