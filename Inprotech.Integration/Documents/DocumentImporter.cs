using System;
using System.Data.Entity;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Persistence;
using InprotechKaizen.Model.Components.Cases.Events;
using InprotechKaizen.Model.Components.ContactActivities;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.Documents
{
    public interface IDocumentImporter
    {
        Task<dynamic> Import(int userIdentityId, DocumentImport documentImport);
    }

    public class DocumentImporter : IDocumentImporter
    {
        readonly ICreateActivityAttachment _createActivityAttachment;
        readonly IDbContext _dbContext;
        readonly IDefaultFileNameFormatter _defaultFileNameFormatter;
        readonly IIntegrationServerClient _integrationServerClient;
        readonly IOccurredEvents _occurredEvents;
        readonly IRepository _repository;
        readonly ITransactionRecordal _transactionRecordal;

        public DocumentImporter(
            IRepository repository,
            IDbContext dbContext,
            IOccurredEvents occurredEvents,
            IIntegrationServerClient integrationServerClient,
            ICreateActivityAttachment createActivityAttachment,
            IDefaultFileNameFormatter defaultFileNameFormatter,
            ITransactionRecordal transactionRecordal)
        {
            _repository = repository;
            _dbContext = dbContext;
            _occurredEvents = occurredEvents;
            _integrationServerClient = integrationServerClient;
            _createActivityAttachment = createActivityAttachment;
            _defaultFileNameFormatter = defaultFileNameFormatter;
            _transactionRecordal = transactionRecordal;
        }

        public async Task<dynamic> Import(int userIdentityId, DocumentImport documentImport)
        {
            if (documentImport == null) throw new ArgumentNullException(nameof(documentImport));
            
            var inprotechCase = await (from c in _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                                       where c.Id == documentImport.CaseId
                                       select c).SingleOrDefaultAsync();
            
            var document = await _repository.Set<Document>()
                                            .SingleOrDefaultAsync(d => d.Id == documentImport.DocumentId);

            var result = Validate(inprotechCase, document, documentImport);
            if (result != null)
            {
                return result;
            }

            var fileName = _defaultFileNameFormatter.Format(document);

            _transactionRecordal.RecordTransactionFor(inprotechCase, CaseTransactionMessageIdentifier.AmendedCase);

            var activity = await _createActivityAttachment.Exec(
                                                          userIdentityId,
                                                          inprotechCase.Id,
                                                          null,
                                                          documentImport.ActivityTypeId,
                                                          documentImport.CategoryId,
                                                          document.MailRoomDate,
                                                          document.DocumentDescription,
                                                          documentImport.AttachmentName,
                                                          fileName,
                                                          null,
                                                          documentImport.IsPublic,
                                                          documentImport.AttachmentTypeId,
                                                          null,
                                                          documentImport.EventId,
                                                          documentImport.Cycle,
                                                          null,
                                                          document.PageCount);

            var stream = await _integrationServerClient.DownloadContent($"api/filestore/{document.FileStore.Id}");
            
            var attachment = activity.Attachments.Single();
            attachment.Reference = document.Reference;
            attachment.AttachmentContent = new AttachmentContent(
                                                                 ReadAsBytes(stream),
                                                                 fileName,
                                                                 document.MediaType ?? "application/pdf"
                                                                );

            await _dbContext.SaveChangesAsync();

            return new {Result = "success"};
        }

        dynamic Validate(InprotechKaizen.Model.Cases.Case @case, Document doc, DocumentImport documentImport)
        {
            if (doc == null) throw new HttpException(404, "Document Not Found.");
            
            if (documentImport.EventId == null) return null;

            var events = _occurredEvents.For(@case);

            var eventSelected = events.SingleOrDefault(e => e.EventId == documentImport.EventId);
            if (eventSelected == null)
            {
                throw new ArgumentException("Provided event does not exist in the case.");
            }

            if (documentImport.Cycle == null || documentImport.Cycle > eventSelected.Cycle)
            {
                return new {Result = "invalid-cycle"};
            }

            return null;
        }

        static byte[] ReadAsBytes(Stream input)
        {
            var buffer = new byte[16 * 1024];

            using (var ms = new MemoryStream())
            {
                int read;

                while ((read = input.Read(buffer, 0, buffer.Length)) > 0)
                    ms.Write(buffer, 0, read);

                return ms.ToArray();
            }
        }
    }
}