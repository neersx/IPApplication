using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Contracts;
using Inprotech.Contracts.DocItems;
using Inprotech.IntegrationServer.DocumentGeneration.Services.HtmlBodyConverter;
using InprotechKaizen.Model.Components.DocumentGeneration.Delivery;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.DocumentGeneration.RequestTypes.DeliverAsDraftEmail
{
    public interface IDraftEmail
    {
        Task<DraftEmailProperties> Prepare(DocGenRequest queueItem);
    }

    public class DraftEmail : IDraftEmail
    {
        readonly IDbContext _dbContext;
        readonly IDocItemRunner _docItemRunner;
        readonly IEmailRecipientResolver _emailRecipientResolver;
        readonly IIndex<Category, IHtmlBodyConverter> _htmlBodyConverters;
        readonly IFileSystem _fileSystem;

        public DraftEmail(IDbContext dbContext,
                          IEmailRecipientResolver emailRecipientResolver,
                          IDocItemRunner docItemRunner,
                          IIndex<Category, IHtmlBodyConverter> htmlBodyConverters, IFileSystem fileSystem)
        {
            _dbContext = dbContext;
            _emailRecipientResolver = emailRecipientResolver;
            _docItemRunner = docItemRunner;
            _htmlBodyConverters = htmlBodyConverters;
            _fileSystem = fileSystem;
        }

        public async Task<DraftEmailProperties> Prepare(DocGenRequest queueItem)
        {
            if (queueItem == null) throw new ArgumentNullException(nameof(queueItem));

            var l = await (from d in _dbContext.Set<Document>()
                           where queueItem.LetterId == d.Id
                           select new
                           {
                               d.DocItemMailbox,
                               d.DocItemSubject,
                               d.DocItemBody
                           }).SingleAsync();

            var mailbox = ResolveMailbox(queueItem, l.DocItemMailbox);

            var emailAddresses = await ResolveEmailRecipients(queueItem);

            var subject = ResolveEmailSubject(queueItem, emailAddresses.Subject, l.DocItemSubject);

            var body = await ResolveEmailBody(queueItem, l.DocItemBody);

            var email = new DraftEmailProperties
            {
                Mailbox = mailbox,
                Subject = subject,
                Body = body.Body,
                IsBodyHtml = body.IsContentInBody
            };

            foreach (var recipient in emailAddresses.To)
                email.Recipients.Add(recipient);

            foreach (var cc in emailAddresses.Cc)
                email.CcRecipients.Add(cc);

            foreach (var bcc in emailAddresses.Bcc)
                email.BccRecipients.Add(bcc);

            if (!body.IsContentInBody)
            {
                var content = _fileSystem.ReadAllBytes(queueItem.FileName);
                var fileName = Path.GetFileName(queueItem.FileName);
                email.Attachments.Add(new EmailAttachment { FileName = fileName, Content = Convert.ToBase64String(content) });
            }
            
            foreach(var attachment in body.Attachments)
                email.Attachments.Add(attachment);
            
            return email;
        }

        async Task<dynamic> ResolveEmailRecipients(DocGenRequest request)
        {
            return await _emailRecipientResolver.Resolve(request.Id);
        }

        string ResolveMailbox(DocGenRequest request, string mailboxDataItem)
        {
            var mailbox = string.Empty;
            if (!string.IsNullOrWhiteSpace(mailboxDataItem))
            {
                mailbox = RunActivityRequestDataItem(mailboxDataItem, request.Id.ToString());
            }

            return mailbox;
        }

        async Task<(string Body, bool IsContentInBody, IEnumerable<EmailAttachment> Attachments)> ResolveEmailBody(DocGenRequest request, string bodyDataItem)
        {
            if (!string.IsNullOrWhiteSpace(bodyDataItem))
            {
                return (RunActivityRequestDataItem(bodyDataItem, request.Id.ToString()), false, Enumerable.Empty<EmailAttachment>());
            }

            var category = CategoryResolver.Resolve(request.FileName);
            if (_htmlBodyConverters.TryGetValue(category, out var htmlBodyConverterService))
            {
                var result = await htmlBodyConverterService.Convert(request.FileName);
                return (result.Body, true, result.Attachments);
            }

            return (string.Empty, false, Enumerable.Empty<EmailAttachment>());
        }

        string ResolveEmailSubject(DocGenRequest request, string subjectFromCustomEmailStoredProcedure, string subjectDataItem)
        {
            var subject = subjectFromCustomEmailStoredProcedure;
            if (!string.IsNullOrWhiteSpace(subject))
                return subject;
            
            if (!string.IsNullOrWhiteSpace(subjectDataItem))
            {
                subject = RunActivityRequestDataItem(subjectDataItem, request.Id.ToString());
            }

            if (string.IsNullOrWhiteSpace(subject))
            {
                subject = request.LetterName;
            }

            return subject;
        }

        string RunActivityRequestDataItem(string dataItemName, string entryPointValue)
        {
            var parameters = DefaultDocItemParameters.ForDocItemSqlQueries(entryPointValue);
            return _docItemRunner.Run(dataItemName, parameters).ScalarValueOrDefault<string>();
        }
    }
}