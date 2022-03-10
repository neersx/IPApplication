using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases
{
    public interface ICaseEmailTemplate
    {
        Task<EmailTemplate> ForCaseName(CaseNameEmailTemplateParameters parameters);

        Task<IEnumerable<EmailTemplate>> ForCaseNames(IEnumerable<CaseNameEmailTemplateParameters> parameters);
        
        Task<EmailTemplate> ForCase(int caseId);
    }

    public class CaseEmailTemplate : ICaseEmailTemplate
    {
        readonly IDbContext _dbContext;
        readonly IDocItemRunner _docItemRunner;
        readonly IEmailValidator _emailValidator;
        readonly ISecurityContext _securityContext;

        public CaseEmailTemplate(IDbContext dbContext, ISecurityContext securityContext, IDocItemRunner docItemRunner, IEmailValidator emailValidator)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _docItemRunner = docItemRunner;
            _emailValidator = emailValidator;
        }

        public async Task<IEnumerable<EmailTemplate>> ForCaseNames(IEnumerable<CaseNameEmailTemplateParameters> parameters)
        {
            if (parameters == null) throw new ArgumentNullException(nameof(parameters));

            var r = new List<EmailTemplate>();
            foreach (var p in parameters) r.Add(await ForCaseName(p));
            return r;
        }

        public async Task<EmailTemplate> ForCaseName(CaseNameEmailTemplateParameters parameters)
        {
            if (parameters == null) throw new ArgumentNullException(nameof(parameters));
            if (string.IsNullOrEmpty(parameters.NameType)) throw new ArgumentException("Name Type is required");

            var caseRef = await (from c in _dbContext.Set<Case>()
                                 where c.Id == parameters.CaseKey
                                 select c.Irn).SingleAsync();

            var userId = _securityContext.User.Id;

            var sequence = parameters.Sequence ?? 0;

            return new EmailTemplate
            {
                RecipientEmail = parameters.CaseNameMainEmail,
                RecipientCopiesTo = ValidateAndSplitEmail(Resolve("EMAIL_CASE_CC_WEB", userId, caseRef, parameters.NameType, sequence)),
                Subject = Resolve("EMAIL_CASE_SUBJECT_WEB", userId, caseRef, parameters.NameType, sequence),
                Body = Resolve("EMAIL_CASE_BODY_WEB", userId, caseRef, parameters.NameType, sequence)
            };
        }

        public async Task<EmailTemplate> ForCase(int caseId)
        {
            var caseRef = await (from c in _dbContext.Set<Case>()
                                 where c.Id == caseId
                                 select c.Irn).SingleAsync();

            var userId = _securityContext.User.Id;

            var recipient = Resolve("EMAIL_CASE_TO_ADMIN", userId, caseRef);

            if (!string.IsNullOrEmpty(recipient) && !_emailValidator.IsValid(recipient))
                recipient = null;

            return new EmailTemplate
            {
                RecipientEmail = recipient,
                Subject = Resolve("EMAIL_CASE_SUBJECT_ADMIN", userId, caseRef),
                Body = Resolve("EMAIL_CASE_BODY_ADMIN", userId, caseRef)
            };
        }

        IEnumerable<string> ValidateAndSplitEmail(string emailResultFromDataItem)
        {
            if (string.IsNullOrEmpty(emailResultFromDataItem) || !_emailValidator.IsValid(emailResultFromDataItem))
            {
                yield break;
            }

            foreach (var email in emailResultFromDataItem.Split(',', ';'))
            {
                if (string.IsNullOrWhiteSpace(email.Trim())) continue;
                yield return email.Trim();
            }
        }

        string Resolve(string dataItemName, int userId, string caseRef, string nameType = null, int? sequence = null)
        {
            if (string.IsNullOrWhiteSpace(caseRef)) throw new ArgumentNullException(nameof(caseRef));

            var p = DefaultDocItemParameters.ForDocItemSqlQueries();
            p["gstrEntryPoint"] = caseRef;
            p["gstrUserId"] = userId;

            if (!string.IsNullOrEmpty(nameType)) p["p1"] = nameType;
            if (sequence.HasValue) p["p2"] = sequence;

            return _docItemRunner.Run(dataItemName, p).ScalarValueOrDefault<string>();
        }
    }

    public class EmailTemplate
    {
        public EmailTemplate()
        {
            RecipientCopiesTo = Enumerable.Empty<string>();
        }

        public string RecipientEmail { get; set; }

        public IEnumerable<string> RecipientCopiesTo { get; set; }

        public string Subject { get; set; }

        public string Body { get; set; }
    }

    public class CaseNameEmailTemplateParameters
    {
        public int CaseKey { get; set; }

        public string NameType { get; set; }

        public int? Sequence { get; set; }

        public string CaseNameMainEmail { get; set; }
    }

    public static class EmailTemplateExtension
    {
        public static bool TryCreateMailtoUri(this EmailTemplate e, out Uri mailto)
        {
            var r = $"mailto:{e.RecipientEmail}";
            var c = string.Join(";", e.RecipientCopiesTo);
            var p = new List<string>();

            if (!string.IsNullOrWhiteSpace(c)) {p.Add($"cc={c}");}
            if (!string.IsNullOrWhiteSpace(e.Subject)) {p.Add($"subject={Uri.EscapeDataString(e.Subject)}");}
            if (!string.IsNullOrWhiteSpace(e.Body)) {p.Add($"body={Uri.EscapeDataString(e.Body)}");}
            if (p.Count > 0) r += $"?{string.Join("&", p)}";

            return Uri.TryCreate(r, UriKind.RelativeOrAbsolute, out mailto);
        }
    }
}