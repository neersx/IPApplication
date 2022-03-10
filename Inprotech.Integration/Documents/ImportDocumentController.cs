using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Persistence;
using InprotechKaizen.Model.Components.Cases.Events;
using InprotechKaizen.Model.Components.Configuration.Extensions;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.Documents
{
    [Authorize]
    [RoutePrefix("api/casecomparison")]
    public class ImportDocumentController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly IDocumentImporter _documentImporter;
        readonly IOccurredEvents _occurredEvents;
        readonly IRepository _repository;

        public ImportDocumentController(
            IRepository repository,
            IDbContext dbContext,
            ISecurityContext securityContext,
            IOccurredEvents occurredEvents,
            IDocumentImporter documentImporter)
        {
            _repository = repository ?? throw new ArgumentNullException(nameof(repository));
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _securityContext = securityContext;
            _occurredEvents = occurredEvents ?? throw new ArgumentNullException(nameof(occurredEvents));
            _documentImporter = documentImporter ?? throw new ArgumentNullException(nameof(documentImporter));
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("importdocument/{caseId}/{documentId}")]
        public async Task<dynamic> Get(int? caseId, int? documentId)
        {
            if (caseId == null) throw new ArgumentNullException(nameof(caseId));
            if (documentId == null) throw new ArgumentNullException(nameof(documentId));

            var doc = _repository.Set<Document>()
                                 .SingleOrDefault(d => d.Id == documentId);

            if (doc == null)
            {
                throw new HttpException(404, "Document Not Found.");
            }
            
            var inprotechCase = await (from c in _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                                                           .Include(c => c.CaseEvents)
                                                           .Include(c => c.OpenActions)
                                       where c.Id == caseId
                                       select c).SingleOrDefaultAsync();

            var selectionAvailable = ActivityAttachmentTableCodes();

            return new
            {
                CaseId = inprotechCase.Id,
                CaseRef = inprotechCase.Irn,
                inprotechCase.Title,
                DocumentId = doc.Id,
                ActivityDate = doc.MailRoomDate,
                AttachmentName = doc.DocumentDescription,
                OccurredEvents = _occurredEvents.For(inprotechCase),
                Categories = selectionAvailable.For(TableTypes.ContactActivityCategory).Select(s => Selection(s)),
                ActivityTypes = selectionAvailable.For(TableTypes.ContactActivityType).Select(s => Selection(s)),
                AttachmentTypes = selectionAvailable.For(TableTypes.AttachmentType).Select(s => Selection(s))
            };
        }

        [HttpPost]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update, PropertyPath = "documentImport.CaseId")]
        [RequiresAccessTo(ApplicationTask.SaveImportedCaseData, ApplicationTaskAccessLevel.Modify)]
        [Route("importdocument/save")]
        public async Task<dynamic> Save(DocumentImport documentImport)
        {
            var userIdentityId = _securityContext.User.Id;
            return await _documentImporter.Import(userIdentityId, documentImport);
        }

        TableCode[] ActivityAttachmentTableCodes()
        {
            var required = new[]
            {
                (int) TableTypes.ContactActivityType, (int) TableTypes.ContactActivityCategory,
                (int) TableTypes.AttachmentType
            };
            return _dbContext.Set<TableCode>().Where(tc => required.Contains(tc.TableTypeId)).ToArray();
        }

        static dynamic Selection(TableCode tableCode)
        {
            return new {Description = tableCode.Name, tableCode.Id};
        }
    }
}