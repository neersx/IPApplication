using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts.DocItems;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Notifications.Security;
using Inprotech.Integration.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.Security.Authorization
{
    public class UserTwoFactorEmailRequired
    {
        readonly IEmailNotification _emailNotifier;
        readonly ISiteControlReader _siteControls;
        readonly IDbContext _dbContext;
        readonly IDocItemRunner _docItemRunner;

        public UserTwoFactorEmailRequired(IEmailNotification emailNotifier, ISiteControlReader siteControls, IDbContext dbContext, IDocItemRunner docItemRunner)
        {
            _emailNotifier = emailNotifier;
            _siteControls = siteControls;
            _dbContext = dbContext;
            _docItemRunner = docItemRunner;
        }

        public Task<Activity> EmailUser(UserAccount2FaMessage message)
        {
            var emailContent = GetEmailContent(message.AuthenticationCode);
            var notification = new Notification
            {
                Subject = emailContent.Subject,
                Body = GetBody(emailContent),
                IsBodyHtml = EmailHelper.HasHtmlTags(emailContent.Body)
            };
            notification.EmailRecipient.
                         Add(new UserEmail { Email = message.UserEmail, Id = message.IdentityId });

            var notifyByEmail = Activity.Run<UserTwoFactorEmailRequired>(_ => _.NotifyByEmail(notification));

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

        static string GetBody(UserEmailContent content)
        {
            var message = new StringBuilder(content.Body);
            message.AppendLine();
            message.AppendLine();
            message.Append(content.Footer);
            message.AppendLine();
            return message.ToString();
        }

        UserEmailContent GetEmailContent(string code)
        {
            var emailContent = new UserEmailContent();

            var docItem = _dbContext.Set<DocItem>().FirstOrDefault(_ => _.Name == KnownEmailDocItems.TwoFactor);
            if (docItem == null) return emailContent;

            var p = DefaultDocItemParameters.ForDocItemSqlQueries(code);
            var dataSet = _docItemRunner.Run(docItem.Id, p);

            var table = dataSet?.Tables.Count > 0 ? dataSet.Tables[0] : new DataTable();
            var dataRow = table.Rows.Count > 0 ? table.Rows[0] : table.NewRow();
            emailContent.Subject = table.Columns.Count > 0 ? dataRow.Field<string>(table.Columns[0]) : Alerts.UserAccountRequiresTwoFactorEmailTitle;
            emailContent.Body = table.Columns.Count > 1 ? dataRow.Field<string>(table.Columns[1]) : string.Format(Alerts.UserAccountRequiresTwoFactorExplanation, code);
            emailContent.Footer = table.Columns.Count > 2 ? dataRow.Field<string>(table.Columns[2]) : "This is a system generated email. Please do not reply.";

            return emailContent;
        }
    }
}