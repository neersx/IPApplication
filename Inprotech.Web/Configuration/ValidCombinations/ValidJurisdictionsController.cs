using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Persistence;
using System;
using System.Linq;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.ModelBinding;

namespace Inprotech.Web.Configuration.ValidCombinations
{
    [RoutePrefix("api/configuration/validcombination/jurisdiction")]
    [Authorize]
    public class ValidJurisdictionsController : ApiController
    {
        readonly IDbContext _dbContext;
        private readonly ISimpleExcelExporter _excelExporter;
        readonly IValidJurisdictionsDetails _validJurisdictionsDetails;

        public ValidJurisdictionsController(IDbContext dbContext, ISimpleExcelExporter excelExporter, IValidJurisdictionsDetails validJurisdictionsDetails)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (excelExporter == null) throw new ArgumentNullException("excelExporter");
            if (validJurisdictionsDetails == null) throw new ArgumentNullException(nameof(validJurisdictionsDetails));

            _dbContext = dbContext;
            _excelExporter = excelExporter;
            _validJurisdictionsDetails = validJurisdictionsDetails;
        }

        static readonly CommonQueryParameters SortByParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
                                                 {
                                                     SortBy = "Country",
                                                     SortDir = "asc"
                                                 });

        [HttpGet]
        [Route("search")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public PagedResults Search(
            [ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "criteria")] ValidCombinationSearchCriteria searchCriteria,
            [ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            return GetPagedResults(_validJurisdictionsDetails.SearchValidJurisdiction(searchCriteria), SortByParameters.Extend(queryParameters));
        }

        [HttpGet]
        [Route("exportToExcel")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public HttpResponseMessage ExportToExcel(
            [ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "criteria")] ValidCombinationSearchCriteria searchCriteria,
            [ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            if (queryParameters != null) queryParameters.Take = Int32.MaxValue;
            var data = GetPagedResults(_validJurisdictionsDetails.SearchValidJurisdiction(searchCriteria), SortByParameters.Extend(queryParameters));

            return _excelExporter.Export(data, "Search Result.xlsx");
        }

        internal PagedResults GetPagedResults(IQueryable<JurisdictionSearch> results, CommonQueryParameters queryParameters)
        {
            var total = results.Count();

            var executedResults = results;

            if (queryParameters.SortBy != "Country")
            {
                executedResults = results.OrderByProperty(queryParameters.SortBy, queryParameters.SortDir);
            }

            executedResults = executedResults.Skip(queryParameters.Skip.GetValueOrDefault())
                                             .Take(queryParameters.Take.GetValueOrDefault());

            return new PagedResults(executedResults, total);
        }
    }
}