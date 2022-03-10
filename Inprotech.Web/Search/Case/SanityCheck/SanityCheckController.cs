using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.DataValidation;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Search.Case.SanityCheck
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/search/case/sanitycheck")]
    public class SanityCheckController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISanityCheckService _sanityCheckService;
        readonly ISecurityContext _securityContext;

        public SanityCheckController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ISecurityContext securityContext, ISanityCheckService sanityCheckService)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _securityContext = securityContext;
            _sanityCheckService = sanityCheckService;
        }

        [HttpPost]
        [Route("apply")]
        public dynamic ApplySanityCheck(List<int> caseIds)
        {
            if (caseIds == null || !caseIds.Any())
            {
                return new {Status = false};
            }

            _dbContext.ApplySanityCheck(caseIds, _securityContext.User.Id, _preferredCultureResolver.Resolve());
            return new {Status = true};
        }

        [HttpPost]
        [Route("results")]
        public async Task<PagedResults> GetSanityCheckResults(SanityResultRequestParams searchRequestParams)
        {
            if (searchRequestParams == null) throw new ArgumentNullException(nameof(SanityResultRequestParams));
            if (searchRequestParams.ProcessId <= 0) throw new HttpResponseException(HttpStatusCode.BadRequest);

            var results = await _sanityCheckService.GetSanityCheckResults(searchRequestParams);

            var orderedResults = results.OrderByProperty(searchRequestParams.Params.SortBy,
                                                         searchRequestParams.Params.SortDir)
                                       .Skip(searchRequestParams.Params.Skip.GetValueOrDefault())
                                       .Take(searchRequestParams.Params.Take.GetValueOrDefault(Int32.MaxValue));

            return results.Any() ? new PagedResults(orderedResults, results.Length) : new PagedResults(results, 0);
        }

        [HttpPost]
        [Route("export")]
        public async Task<IHttpActionResult> Export(SanityResultRequestParams exportParams)
        {
            if (exportParams == null) throw new ArgumentNullException(nameof(SanityResultRequestParams));
            if (!exportParams.ExportFormat.HasValue) throw new HttpResponseException(HttpStatusCode.BadRequest);

            var r = await _sanityCheckService.Export(exportParams);
            if (r == null) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return new FileStreamResult(r, Request);
        }
    }

    public class SanityResultRequestParams
    {
        public CommonQueryParameters Params { get; set; }
        public int ProcessId { get; set; }
        public ReportExportFormat? ExportFormat { get; set; }
    }
}