using System.Data.Entity;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;

namespace Inprotech.Web.Search.Name
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.QuickNameSearch)]
    [RequiresAccessTo(ApplicationTask.RunSavedNameSearch)]
    [RequiresAccessTo(ApplicationTask.AdvancedNameSearch)]
    [RoutePrefix("api/search/name")]
    public class NameSearchResultViewController : ApiController, ISearchResultViewController
    {
        readonly IDbContext _dbContext;
        readonly IListPrograms _listPrograms;
        readonly QueryContext _queryContextDefault;
        readonly ISecurityContext _securityContext;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly ISiteControlReader _siteControlReader;

        public NameSearchResultViewController(IDbContext dbContext, ISecurityContext securityContext, IListPrograms listPrograms, ITaskSecurityProvider taskSecurityProvider, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _listPrograms = listPrograms;
            _taskSecurityProvider = taskSecurityProvider;
            _queryContextDefault = securityContext.User.IsExternalUser
                ? QueryContext.NameSearchExternal
                : QueryContext.NameSearch;
            _siteControlReader = siteControlReader;
        }

        [Route("view")]
        public async Task<dynamic> Get(int? queryKey, QueryContext queryContext)
        {
            if (_queryContextDefault != queryContext)
            {
                return BadRequest();
            }

            var queryName = string.Empty;
            if (queryKey.HasValue)
            {
                queryName = (await _dbContext.Set<Query>().FirstOrDefaultAsync(_ => _.Id == queryKey.Value))?.Name;
            }

            return new
            {
                isExternal = _securityContext.User.IsExternalUser,
                QueryName = queryName,
                QueryContext = (int) queryContext,
                Programs = _listPrograms.GetNamePrograms(),
                Permissions = new
                {
                    CanMaintainNameNotes = _taskSecurityProvider.HasAccessTo(ApplicationTask.AnnotateNames),
                    CanMaintainNameAttributes = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainNameAttributes),
                    CanMaintainName = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainName, ApplicationTaskAccessLevel.Modify),
                    CanMaintainOpportunity =_taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainOpportunity),
                    CanMaintainAdHocDate= _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainAdHocDate),
                    CanMaintainContactActivity=_taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainContactActivity),
                    CanAccessDocumentsFromDms = _taskSecurityProvider.HasAccessTo(ApplicationTask.AccessDocumentsfromDms)
                },
                ExportLimit = _siteControlReader.Read<int?>(SiteControls.ExportLimit)
            };
        }
    }
}