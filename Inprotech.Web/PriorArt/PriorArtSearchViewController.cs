using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.PriorArt
{
    [Authorize]
    [ViewInitialiser]
    [RequiresAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Create)]
    public class PriorArtSearchViewController : ApiController
    {
        readonly IDbContext _dbContext;

        public PriorArtSearchViewController(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("api/priorart/priorartsearchview/{sourceId:int?}/{caseKey:int?}")]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update)]
        public dynamic Get(int? sourceId = null, int? caseKey = null)
        {
            var priorArtSearchViewModel = new PriorArtSearchViewModel();
            if (!sourceId.HasValue && !caseKey.HasValue) return priorArtSearchViewModel;

            if (sourceId.HasValue)
            {
                var priorArtSource = _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>()
                                               .SingleOrDefault(pa => pa.Id == sourceId);

                if (priorArtSource == null) throw Exceptions.NotFound("Source not found.");
                if (!priorArtSource.IsSourceDocument) throw Exceptions.BadRequest("Not a source document.");
                var sourceDocumentModel = new SourceDocumentModel(priorArtSource);
                priorArtSearchViewModel.SourceDocumentData = sourceDocumentModel;
            }

            priorArtSearchViewModel.CaseKey = caseKey;

            return priorArtSearchViewModel;
        }
    }
}