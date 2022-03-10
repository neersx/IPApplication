using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Picklists
{

    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/criteria")]
    public class CriteriaPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
       
        public CriteriaPicklistController(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        [HttpGet]
        [AuthorizeCriteriaPurposeCodeTaskSecurity]
        [Route("")]
        public PagedResults TypeaheadSearch(string search, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters, string purposeCode)
        {
            var results = _dbContext.Set<Criteria>().WherePurposeCode(purposeCode);

            results = results.Where(_ => search == null || _.Id.ToString().Contains(search) || _.Description.Contains(search));
            var r = results.Select(_ => new CriteriaResult
            {
                Id = _.Id,
                Description = _.Description,
            });

            return Helpers.GetPagedResults(r,
                                           queryParameters ?? new CommonQueryParameters(),
                                           x => x.Id.ToString(),
                                           x => x.Description,
                                           search);
        }
    }
}
