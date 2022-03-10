using System;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Newtonsoft.Json;

namespace Inprotech.Integration.Documents
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ViewCaseDataComparison)]
    public class DocumentsController : ApiController
    {
        readonly IDocumentLoader _documentLoader;
        readonly IUpdatedEventsLoader _updatedEventsLoader;

        public DocumentsController(IDocumentLoader documentLoader, IUpdatedEventsLoader updatedEventsLoader)
        {
            if (documentLoader == null) throw new ArgumentNullException("documentLoader");
            if (updatedEventsLoader == null) throw new ArgumentNullException("updatedEventsLoader");
            _documentLoader = documentLoader;
            _updatedEventsLoader = updatedEventsLoader;
        }

        [HttpGet]
        [Route("api/casecomparison/{sourceType}/documents")]
        public dynamic Get(DataSourceType sourceType, int? caseId)
        {
            if (caseId == null) throw new ArgumentNullException("caseId");

            var importedRefs = _documentLoader.GetImportedRefs(caseId);

            var docs = _documentLoader.GetDocumentsFrom(sourceType, caseId).Distinct().ToArray();

            var updatedEvents = _updatedEventsLoader.Load(caseId, docs);

            return docs.Select(
                d => new
                {
                    d.Id,
                    d.MailRoomDate,
                    Code = d.FileWrapperDocumentCode,
                    Description = d.DocumentDescription,
                    Category = d.DocumentCategory,
                    d.PageCount,
                    Imported = importedRefs.Contains(d.Reference),
                    Status = d.Status.ToString(),
                    EventUpdatedDescription = updatedEvents[d].Description,
                    EventUpdatedCycle = updatedEvents[d].EventUpdatedCycle(),
                    Errors =
                        ((d.Status == DocumentDownloadStatus.Failed ||
                          d.Status == DocumentDownloadStatus.FailedToSendToDms)
                         && d.Errors != null)
                            ? JsonConvert.DeserializeObject(d.Errors)
                            : null
                }).OrderByDescending(_ => _.MailRoomDate);
        }
    }

    public static class UpdatedEventExt
    {
        public static int? EventUpdatedCycle(this UpdatedEvent updatedEvent)
        {
            if (updatedEvent.IsCyclic)
                return updatedEvent.Cycle;

            return null;
        }
    }
}