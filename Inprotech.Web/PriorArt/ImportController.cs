using System;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.PriorArt
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Create)]
    public class ImportController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IEvidenceImporter _evidenceImporter;
        
        public ImportController(
            IDbContext dbContext,
            IEvidenceImporter evidenceImporter)
        {
            _dbContext = dbContext;
            _evidenceImporter = evidenceImporter;
        }

        [HttpPost]
        [AppliesToComponent(KnownComponents.PriorArt)]
        [Route("api/priorart/import/fromcaseevidencefinder")]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update, PropertyPath = "model.CaseKey")]
        public void FromCaseEvidenceFinder(ImportEvidenceModel model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));

            _evidenceImporter.ImportMatch(model, model.Evidence);
            _dbContext.SaveChanges();
        }

        [HttpPost]
        [AppliesToComponent(KnownComponents.PriorArt)]
        [Route("api/priorart/import/fromIpOneDataDocumentFinder")]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update, PropertyPath = "model.CaseKey")]
        public async Task FromIpOneDataDocumentFinder(ImportEvidenceModel model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));

            _evidenceImporter.ImportMatch(model, model.Evidence);
            await _dbContext.SaveChangesAsync();
        }
    }
}