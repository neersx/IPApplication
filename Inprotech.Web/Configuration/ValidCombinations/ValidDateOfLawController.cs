using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;
using System;
using System.Data.Entity;
using System.Linq;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.ModelBinding;

namespace Inprotech.Web.Configuration.ValidCombinations
{
    [RoutePrefix("api/dateoflaw")]
    [Authorize]
    public class ValidDateOfLawController : ApiController
    {
        readonly IDbContext _dbContext;
        private readonly ISimpleExcelExporter _excelExporter;

        static readonly CommonQueryParameters SortByParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "Country",
                SortDir = "asc"
            });

        public ValidDateOfLawController(IDbContext dbContext, ISimpleExcelExporter excelExporter)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (excelExporter == null) throw new ArgumentNullException("excelExporter");

            _dbContext = dbContext;
            _excelExporter = excelExporter;
        }

        [HttpGet]
        [Route("search")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public PagedResults Search(
            [ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "criteria")] ValidCombinationSearchCriteria searchCriteria,
            [ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            return GetPagedResults(SearchDateOfLaw(searchCriteria), SortByParameters.Extend(queryParameters));
        }

        [HttpGet]
        [Route("exportToExcel")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public HttpResponseMessage ExportToExcel(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "criteria")] ValidCombinationSearchCriteria searchCriteria,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            var data = GetPagedResults(SearchDateOfLaw(searchCriteria),
                                       SortByParameters.Extend(new CommonQueryParameters
                                       {
                                           Take = int.MaxValue
                                       }));

            return _excelExporter.Export(data, "Search Result.xlsx");
        }

        internal IQueryable<DateOfLaw> SearchDateOfLaw(ValidCombinationSearchCriteria searchCriteria)
        {
            var result = _dbContext.Set<DateOfLaw>().AsQueryable();

            if (!string.IsNullOrEmpty(searchCriteria.PropertyType))
                result = result.Where(_ => _.PropertyType.Code == searchCriteria.PropertyType);

            if (searchCriteria.Jurisdictions.Any())
                result = result.Where(_ => searchCriteria.Jurisdictions.Contains(_.Country.Id));

            if (searchCriteria.DateOfLaw!=default(DateTime))
                result = result.Where(_ => _.Date == searchCriteria.DateOfLaw);

            return result;
        }

        internal PagedResults GetPagedResults(IQueryable<DateOfLaw> results, CommonQueryParameters queryParameters)
        {
            var total = results.Count();

            var executedResults =
                results.OrderByProperty(MapColumnName(queryParameters.SortBy),
                    queryParameters.SortDir)
                    .Skip(queryParameters.Skip.GetValueOrDefault())
                    .Take(queryParameters.Take.GetValueOrDefault());

            var data = executedResults
                .Include(_ => _.Country)
                .Include(_ => _.PropertyType)
                .ToArray()
                .Select(_ =>
                            new ValidDateOfLawRow
                                {
                                    Country = _.Country != null ? _.Country.Name : null,
                                    PropertyType = _.PropertyType != null ? _.PropertyType.Name : null,
                                    DateOfLaw = _.Date.ToString("dd-MMM-yyyy"),
                                    RetrospectiveAction = _.RetroAction == null ? null : _.RetroAction.Name,
                                    DefaultEventForLaw = _.LawEvent == null ? null : _.LawEvent.Description,
                                    DefaultRetrospectiveEvent = _.RetroEvent == null ? null : _.RetroEvent.Description
                                }).ToArray();

            return new PagedResults(data, total);
        }

        private static string MapColumnName(string name)
        {
            if (name == "dateOfLaw")
                return "Date";
            if (name == "retrospectiveAction")
                return "RetroAction.Name";
            if (name == "defaultEventForLaw")
                return "LawEvent.Description";
            if (name == "defaultRetrospectiveEvent")
                return "RetroEvent.Description";

            return string.Format("{0}.{1}", name, "Name");
        }
    }

    public class ValidDateOfLawRow
    {
        [ExcelHeader("Jurisdiction")]
        public string Country { get; set; }

        [ExcelHeader("Property Type")]
        public string PropertyType { get; set; }

        [ExcelHeader("Date Of Law")]
        public string DateOfLaw { get; set; }

        [ExcelHeader("Retrospective Action")]
        public string RetrospectiveAction { get; set; }

        [ExcelHeader("Default Event For Law")]
        public string DefaultEventForLaw { get; set; }

        [ExcelHeader("Default Retrospective Event")]
        public string DefaultRetrospectiveEvent { get; set; }
    }
}
