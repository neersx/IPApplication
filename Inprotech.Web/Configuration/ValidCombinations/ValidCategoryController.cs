using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Characteristics;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;
using System;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.ModelBinding;

namespace Inprotech.Web.Configuration.ValidCombinations
{
    [RoutePrefix("api/configuration/validcombination/category")]
    [Authorize]
    public class ValidCategoryController : ApiController, IValidCombinationBulkController
    {
        readonly IDbContext _dbContext;
        readonly IValidCategories _validCategories;
        private readonly ISimpleExcelExporter _excelExporter;

        static readonly CommonQueryParameters SortByParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "Country",
                SortDir = "asc"
            });

        public ValidCategoryController(IDbContext dbContext, IValidCategories validCategories, ISimpleExcelExporter excelExporter)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _validCategories = validCategories ?? throw new ArgumentNullException(nameof(validCategories));
            _excelExporter = excelExporter ?? throw new ArgumentNullException(nameof(excelExporter));
        }

        [HttpGet]
        [Route("search")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public PagedResults Search(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "criteria")] ValidCombinationSearchCriteria searchCriteria,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            return GetPagedResults(SearchValidProperty(searchCriteria), SortByParameters.Extend(queryParameters));
        }

        [HttpGet]
        [Route("exportToExcel")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public HttpResponseMessage ExportToExcel(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "criteria")] ValidCombinationSearchCriteria searchCriteria,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            if (queryParameters != null) queryParameters.Take = Int32.MaxValue;
            var data = GetPagedResults(SearchValidProperty(searchCriteria), SortByParameters.Extend(queryParameters));

            return _excelExporter.Export(data, "Search Result.xlsx");
        }

        internal IQueryable<ValidCategory> SearchValidProperty(ValidCombinationSearchCriteria searchCriteria)
        {
            var result = _dbContext.Set<ValidCategory>().AsQueryable();

            if (!string.IsNullOrEmpty(searchCriteria.PropertyType))
                result = result.Where(_ => _.PropertyTypeId == searchCriteria.PropertyType);

            if (searchCriteria.Jurisdictions.Any())
                result = result.Where(_ => searchCriteria.Jurisdictions.Contains(_.CountryId));

            if (!string.IsNullOrEmpty(searchCriteria.CaseType))
                result = result.Where(_ => _.CaseTypeId == searchCriteria.CaseType);

            if (!string.IsNullOrEmpty(searchCriteria.CaseCategory))
                result = result.Where(_ => _.CaseCategoryId == searchCriteria.CaseCategory);

            return result;
        }

        internal PagedResults GetPagedResults(IQueryable<ValidCategory> results, CommonQueryParameters queryParameters)
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
                .Include(_ => _.CaseType)
                .Include(_ => _.CaseCategory)
                .ToArray()
                .Select(_ => new ValidCategoryRow
                                 {
                                     Id = new ValidCategoryIdentifier(_.CountryId, _.PropertyTypeId, _.CaseTypeId, _.CaseCategoryId),
                                     Country = _.Country != null ? _.Country.Name : null,
                                     PropertyType = _.PropertyType != null ? _.PropertyType.Name : null,
                                     ValidDescription = _.CaseCategoryDesc,
                                     CaseType = _.CaseType != null ? _.CaseType.Name : null,
                                     CaseCategory = _.CaseCategory != null ? _.CaseCategory.Name : null
                                 }).ToArray();

            return new PagedResults(data, total);
        }

        static string MapColumnName(string name)
        {
            if (name == "validDescription")
                return "CaseCategoryDesc";

            return string.Format("{0}.{1}", name, "Name");
        }

        [HttpGet]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public dynamic ValidCaseCategory([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "entitykey")] ValidCategoryIdentifier validCategoryIdentifier)
        {
            var response = _validCategories.ValidCaseCategory(validCategoryIdentifier);
            return response ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Save(CaseCategorySaveDetails saveDetails)
        {
            return _validCategories.Save(saveDetails);
        }

        [HttpPut]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Update(CaseCategorySaveDetails saveDetails)
        {
            var response = _validCategories.Update(saveDetails);
            return response ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        [HttpPost]
        [Route("delete")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public DeleteResponseModel<ValidCategoryIdentifier> Delete(ValidCategoryIdentifier[] deleteRequestModel)
        {
            var response = _validCategories.Delete(deleteRequestModel);
            return response ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        public void Copy(CountryModel fromJurisdiction, CountryModel[] toJurisdictions)
        {
            if (fromJurisdiction == null) throw new ArgumentNullException(nameof(fromJurisdiction));
            if (toJurisdictions == null || !toJurisdictions.Any()) throw new ArgumentNullException(nameof(toJurisdictions));

            var validCategories = _dbContext.Set<ValidCategory>().Where(_ => _.Country.Id == fromJurisdiction.Code).ToArray();
            foreach (var jurisdiction in toJurisdictions)
            {
                foreach (var vc in validCategories.Where(vc => !_dbContext.Set<ValidCategory>()
                    .Any(_ => _.CountryId == jurisdiction.Code && _.PropertyTypeId == vc.PropertyTypeId && _.CaseTypeId == vc.CaseTypeId
                    && _.CaseCategoryId == vc.CaseCategoryId)))
                {
                    Save(new CaseCategorySaveDetails
                    {
                        Jurisdictions = new[] { jurisdiction },
                        PropertyType = new PropertyType(vc.PropertyType.Code, vc.PropertyType.Name),
                        CaseType = new CaseType(vc.CaseType.Code, vc.CaseType.Name),
                        ValidDescription = vc.CaseCategoryDesc,
                        CaseCategory = new CaseCategory(vc.CaseCategory.CaseCategoryId, vc.CaseCategory.Name),
                        MultiClassPropertyApp = vc.MultiClassPropertyApp,
                        PropertyEvent = vc.PropertyEvent!=null? new Event { Key = vc.PropertyEvent.Id, Code = vc.PropertyEvent.Code, Value = vc.PropertyEvent.Description} : null,
                        SkipDuplicateCheck = true
                    });
                }
            }

            _dbContext.SaveChanges();
        }

        [HttpGet]
        [Route("validateCategory")]
        public ValidatedCharacteristic ValidateCategory(string caseType, string caseCategory)
        {
            return _validCategories.ValidateCategory(caseType, caseCategory);
        } 
        
        public class ValidCategoryRow
        {
            public ValidCategoryIdentifier Id { get; set; }

            [ExcelHeader("Case Type")]
            public string CaseType { get; set; }

            [ExcelHeader("Jurisdiction")]
            public string Country { get; set; }

            [ExcelHeader("Property Type")]
            public string PropertyType { get; set; }

            [ExcelHeader("Case Category")]
            public string CaseCategory { get; set; }

            [ExcelHeader("Valid Description")]
            public string ValidDescription { get; set; }
        }
    }
}