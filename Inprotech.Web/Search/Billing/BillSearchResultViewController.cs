using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;

namespace Inprotech.Web.Search.Billing
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/search/billing")]
    public class BillSearchResultViewController : ApiController, ISearchResultViewController
    {
        readonly IDbContext _dbContext;
        readonly IWebPartSecurity _webPartSecurity;
        readonly IBillingUserPermissionSettingsResolver _billingUserPermissionSettingsResolver;
        public BillSearchResultViewController(IDbContext dbContext, IWebPartSecurity webPartSecurity, IBillingUserPermissionSettingsResolver billingUserPermissionSettingsResolver)
        {
            _dbContext = dbContext;
            _webPartSecurity = webPartSecurity;
            _billingUserPermissionSettingsResolver = billingUserPermissionSettingsResolver;
        }

        [Route("view")]
        public async Task<dynamic> Get(int? queryKey, QueryContext queryContext)
        {
            if (!_webPartSecurity.HasAccessToWebPart(ApplicationWebPart.BillSearch)) throw new HttpResponseException(HttpStatusCode.Forbidden);

            if (QueryContext.BillingSelection != queryContext) return BadRequest();

            var queryName = string.Empty;
            if (queryKey.HasValue)
            {
                queryName = _dbContext.Set<Query>().FirstOrDefault(_ => _.Id == queryKey.Value)?.Name;
            }

            var permissions = await _billingUserPermissionSettingsResolver.Resolve();
            return new
            {
                QueryName = queryName,
                QueryContext = (int)queryContext,
                Permissions = permissions
            };
        }
    }
}
