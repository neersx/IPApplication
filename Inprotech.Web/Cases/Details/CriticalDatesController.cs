using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class CriticalDatesController : ApiController
    {
        readonly ICriticalDatesResolver _criticalDatesResolver;
        readonly IDbContext _dbContext;

        public CriticalDatesController(IDbContext dbContext, ICriticalDatesResolver criticalDatesResolver)
        {
            _dbContext = dbContext;
            _criticalDatesResolver = criticalDatesResolver;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/critical-dates")]
        public async Task<IEnumerable<CriticalDate>> Get(int caseKey)
        {
            var @case = await (from c in _dbContext.Set<Case>()
                               where c.Id == caseKey
                               select c)
                .SingleOrDefaultAsync();

            if (@case == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            return await _criticalDatesResolver.Resolve(caseKey);
        }
    }
}