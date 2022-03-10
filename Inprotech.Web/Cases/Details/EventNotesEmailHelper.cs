using System;
using System.Data.Entity;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using Inprotech.Contracts.DocItems;
using Inprotech.Contracts.Messages;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Legacy;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Cases.Details
{
    public interface IEventNotesEmailHelper
    {
        (EventNotesMailMessage mailMessage, string emailValidationMessage) PrepareEmailMessage(CaseEventText caseEventText, string newEventText);
    }

    public class EventNotesEmailHelper : IEventNotesEmailHelper
    {
        readonly ISecurityContext _securityContext;
        readonly IDocItemRunner _docItemRunner;
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControls;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IStaticTranslator _staticTranslator;
        readonly IDataService _dataService;
        readonly IEmailValidator _emailValidator;

        public EventNotesEmailHelper(IDbContext dbContext, ISecurityContext securityContext,
                                     ISiteControlReader siteControls, IDocItemRunner docItemRunner,
                                     IPreferredCultureResolver preferredCultureResolver, IStaticTranslator staticTranslator,
                                     IDataService dataService, IEmailValidator emailValidator)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _docItemRunner = docItemRunner;
            _siteControls = siteControls;
            _preferredCultureResolver = preferredCultureResolver;
            _staticTranslator = staticTranslator;
            _dataService = dataService;
            _emailValidator = emailValidator;
        }

        public (EventNotesMailMessage mailMessage, string emailValidationMessage) PrepareEmailMessage(CaseEventText caseEventText, string newEventText)
        {
            (EventNotesMailMessage mailMessage, string emailValidationMessage) result = (new EventNotesMailMessage(), string.Empty);

            var culture = _preferredCultureResolver.ResolveAll().ToArray();

            var toEmailDocItem = GetDocItemName(SiteControls.EventNotesEmailTo);
            if (!string.IsNullOrEmpty(toEmailDocItem))
            {
                var recipients = GetRecipientsFromDocItem(caseEventText.CaseId, caseEventText.EventId, toEmailDocItem);
                if (string.IsNullOrEmpty(recipients) ||
                    (!string.IsNullOrEmpty(recipients) && recipients.Split(',').Any(_ => !_emailValidator.IsValid(_))))
                {
                    result.emailValidationMessage = _staticTranslator.Translate("taskPlanner.eventNotes.toCcEmailValidation", culture);
                    return result;
                }

                var name = _dbContext.Set<User>()
                                     .Include(_ => _.Name.Telecoms)
                                     .Single(_ => _.Id == _securityContext.User.Id)
                                     .Name;

                var from = name.MainEmailAddress();

                if (string.IsNullOrEmpty(from) || (!string.IsNullOrEmpty(from) && !_emailValidator.IsValid(from)))
                {
                    result.emailValidationMessage = _staticTranslator.Translate("taskPlanner.eventNotes.fromEmailValidation", culture);
                    return result;
                }

                var ccEmailDocItem = GetDocItemName(SiteControls.EventNotesEmailCopyTo);
                if (!string.IsNullOrEmpty(ccEmailDocItem))
                {
                    var copyToRecipients = GetRecipientsFromDocItem(caseEventText.CaseId, caseEventText.EventId, ccEmailDocItem);
                    if (!string.IsNullOrEmpty(copyToRecipients) && copyToRecipients.Split(',').Any(_ => !_emailValidator.IsValid(_)))
                    {
                        result.emailValidationMessage = _staticTranslator.Translate("taskPlanner.eventNotes.toCcEmailValidation", culture);
                        return result;
                    }

                    result.mailMessage.Cc = copyToRecipients;
                }

                result.mailMessage.To = recipients;
                result.mailMessage.From = from;
                result.mailMessage.Subject = _staticTranslator.Translate("taskPlanner.eventNotes.eventNotesEmailSubject", culture) + " " + caseEventText.Case.Irn;
                result.mailMessage.Body = PrepareEmailBody(caseEventText, newEventText, culture);
            }

            return result;
        }

        string PrepareEmailBody(CaseEventText caseEventText, string newEventText, string[] culture)
        {
            var noteType = caseEventText.EventNote.EventNoteType?.Description;

            var email = new StringBuilder();
            var emailBodyPart1 = _staticTranslator.Translate("taskPlanner.eventNotes.eventNotesEmailBodyPart1", culture);
            var emailBodyPart1WithEventNoteType = _staticTranslator.Translate("taskPlanner.eventNotes.eventNotesEmailBodyPart1WithEventNoteType", culture).Replace("{0}", noteType);
            var emailBodyPart2 = _staticTranslator.Translate("taskPlanner.eventNotes.eventNotesEmailBodyPart2", culture);
            email.Append(noteType == null ? emailBodyPart1 : emailBodyPart1WithEventNoteType);
            email.AppendFormat(" <a href='{0}'>{1}</a> ", _dataService.GetParentUri("?caseref=" + HttpUtility.HtmlEncode(caseEventText.Case.Irn)), HttpUtility.HtmlEncode(caseEventText.Case.Irn));
            email.AppendFormat(emailBodyPart2);
            email.Append("<br><br>");
            email.Append(FormatEmailBodyText(newEventText));

            return email.ToString();
        }

        static StringBuilder FormatEmailBodyText(string newEventText)
        {
            var builder = new StringBuilder();
            const string pattern = @"(-{3})(.*)";
            var splittedArray = newEventText.Split(new[] { "\r\n" }, StringSplitOptions.None);
            foreach (var s in splittedArray)
            {
                var match = Regex.Match(s, pattern);
                if (match.Success)
                {
                    builder.Append(s.Substring(0, match.Index));
                    builder.Append("<i>" + match.Value + "</i>");
                    builder.Append(s.Substring(match.Index + match.Length));
                }
                else
                {
                    builder.Append(s);
                }
                builder.Append("<br>");
            }
            return builder;
        }

        string GetRecipientsFromDocItem(int caseKey, int eventNo, string docItemName)
        {
            var p = DefaultDocItemParameters.ForDocItemSqlQueries();
            p["gstrEntryPoint"] = caseKey;
            p["gstrUserId"] = _securityContext.User.Id;
            p["p1"] = eventNo;

            return _docItemRunner.Run(docItemName, p).ScalarValueOrDefault<string>();
        }

        string GetDocItemName(string siteControlName)
        {
            var docItemName = _siteControls.Read<string>(siteControlName);
            if (string.IsNullOrEmpty(docItemName))
                return string.Empty;

            return docItemName;
        }
    }
    
}
