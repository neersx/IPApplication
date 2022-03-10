using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Search.PriorArt
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.RunSavedPriorArtSearch)]
    [RequiresAccessTo(ApplicationTask.AdvancedPriorArtSearch)]
    [RoutePrefix("api/search/priorart")]
    public class PriorArtSearchResultViewController : ApiController, ISearchResultViewController
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly ISiteControlReader _siteControlReader;

        public PriorArtSearchResultViewController(IDbContext dbContext, ISecurityContext securityContext, ITaskSecurityProvider taskSecurityProvider, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _taskSecurityProvider = taskSecurityProvider;
            _siteControlReader = siteControlReader;
        }

        [Route("view")]
        public async Task<dynamic> Get(int? queryKey, QueryContext queryContext)
        {
            if (QueryContext.PriorArtSearch != queryContext) return BadRequest();

            var queryName = string.Empty;
            if (queryKey.HasValue)
            {
                queryName = (await _dbContext.Set<Query>().FirstOrDefaultAsync(_ => _.Id == queryKey.Value))?.Name;
            }

            return new
            {
                isExternal = _securityContext.User.IsExternalUser,
                QueryName = queryName,
                QueryContext = (int)queryContext,
                Permissions = new
                {
                    CanMaintainPriorArt = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPriorArt)
                },
                ExportLimit = _siteControlReader.Read<int?>(SiteControls.ExportLimit)
            };
        }
    }
}