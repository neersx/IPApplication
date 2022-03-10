using System;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts.DocItems;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Notifications.Security;
using Inprotech.Integration.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.Security.Authorization
{
    public class UserAccountLocked
    {
        readonly IEmailNotification _emailNotifier;
        readonly IPopupNotification _popupNotifier;
        readonly ISiteControlReader _siteControls;
        readonly IDbContext _dbContext;
        readonly IDocItemRunner _docItemRunner;
        readonly IUserAdministrators _userAdministrators;

        public UserAccountLocked(IUserAdministrators userAdministrators, IEmailNotification emailNotifier, IPopupNotification popupNotifier, ISiteControlReader siteControls, 
                                 IDbContext dbContext, IDocItemRunner docItemRunner)
        {
            _userAdministrators = userAdministrators;
            _emailNotifier = emailNotifier;
            _popupNotifier = popupNotifier;
            _siteControls = siteControls;
            _dbContext = dbContext;
            _docItemRunner = docItemRunner;
        }

        public Task<Activity> NotifyAllConcerned(UserAccountLockedMessage message)
        {
            var emailContent = GetEmailContent(message.Username);
            var emailRecipients = _userAdministrators.Resolve(message.IdentityId).ToArray();
            if (!emailRecipients.Any())
                throw new Exception(Alerts.UserAccountLocked_UnableToNotify);

            var emailNotification = new Notification
                               {
                                   Subject = emailContent.Subject,
                                   Body = GetEmailBody(message, emailContent.Body),
                                   IsBodyHtml = true
                               };
            emailNotification.EmailRecipient.AddRange(emailRecipients);

            var notifyByEmail = Activity.Run<UserAccountLocked>(_ => _.NotifyByEmail(emailNotification));

            var screenNotification = new Notification
            {
                Subject = emailContent.Subject,
                Body = GetBody(message, emailContent.Body)
            };
            screenNotification.EmailRecipient.AddRange(emailRecipients);

            var notifyOnScreen = Activity.Run<UserAccountLocked>(_ => _.NotifyOnScreen(screenNotification));

            return Task.FromResult((Activity) Activity.Parallel(notifyByEmail, notifyOnScreen));
        }

        public async Task NotifyByEmail(Notification notification)
        {
            notification.From = _siteControls.Read<string>(SiteControls.WorkBenchAdministratorEmail);
            await _emailNotifier.Send(notification);
        }

        public async Task NotifyOnScreen(Notification notification)
        {
            await _popupNotifier.Send(notification);
        }

        string GetEmailBody(UserAccountLockedMessage details, string body)
        {
            var message = new StringBuilder(body);
            message.AppendFormat("<br /> <br /> Full Name: {0} <br />", details.DisplayName);
            message.AppendFormat("User Name: {0} <br />", details.Username);
            message.AppendFormat("User Email: {0} <br />", details.UserEmail);
            message.AppendFormat("Date Locked (UTC): {0:U} <br />", details.LockedUtc);
            message.AppendFormat("Date Locked (Server): {0:F}", details.LockedLocal);
            return message.ToString();
        }

        string GetBody(UserAccountLockedMessage details, string body)
        {
            var message = new StringBuilder(body);
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

            return message.ToString();
        }

        UserEmailContent GetEmailContent(string userName)
        {
            var emailContent = new UserEmailContent();

            var docItem = _dbContext.Set<DocItem>().FirstOrDefault(_ => _.Name == KnownEmailDocItems.UserAccountLocked);
            if (docItem == null) return emailContent;

            var p = DefaultDocItemParameters.ForDocItemSqlQueries(userName);
            var dataSet = _docItemRunner.Run(docItem.Id, p);

            var table = dataSet?.Tables.Count > 0 ? dataSet.Tables[0] : new DataTable();
            var dataRow = table.Rows.Count > 0 ? table.Rows[0] : table.NewRow();
            emailContent.Subject = table.Columns.Count > 0 ? dataRow.Field<string>(table.Columns[0]) : string.Format(Alerts.UserAccountLockedTitle, userName);
            emailContent.Body = table.Columns.Count > 1 ? dataRow.Field<string>(table.Columns[1]) : Alerts.UserAccountLockedExplanation;

            return emailContent;
        }
    }
}