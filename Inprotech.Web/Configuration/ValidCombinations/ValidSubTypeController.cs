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
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.ModelBinding;

namespace Inprotech.Web.Configuration.ValidCombinations
{
    [RoutePrefix("api/configuration/validcombination/subtype")]
    [Authorize]
    public class ValidSubTypeController : ApiController, IValidCombinationBulkController
    {
        readonly IDbContext _dbContext;
        readonly IValidSubTypes _validSubTypes;
        readonly ISimpleExcelExporter _excelExporter;

        static readonly CommonQueryParameters SortByParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "Country",
                SortDir = "asc"
            });

        public ValidSubTypeController(IDbContext dbContext, IValidSubTypes validSubTypes, ISimpleExcelExporter excelExporter)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _validSubTypes = validSubTypes ?? throw new ArgumentNullException(nameof(validSubTypes));
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
            return GetPagedResults(SearchValidSubType(searchCriteria), SortByParameters.Extend(queryParameters));
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
            var data = GetPagedResults(SearchValidSubType(searchCriteria), SortByParameters.Extend(queryParameters));

            return _excelExporter.Export(data, "Search Result.xlsx");
        }

        internal IQueryable<ValidSubType> SearchValidSubType(ValidCombinationSearchCriteria searchCriteria)
        {
            var result = _dbContext.Set<ValidSubType>().AsQueryable();

            if (searchCriteria.Jurisdictions.Any())
                result = result.Where(_ => searchCriteria.Jurisdictions.Contains(_.CountryId));

            if (!string.IsNullOrEmpty(searchCriteria.PropertyType))
                result = result.Where(_ => _.PropertyTypeId == searchCriteria.PropertyType);

            if (!string.IsNullOrEmpty(searchCriteria.CaseType))
                result = result.Where(_ => _.CaseTypeId == searchCriteria.CaseType);

            if (!string.IsNullOrEmpty(searchCriteria.CaseCategory))
                result = result.Where(_ => _.CaseCategoryId == searchCriteria.CaseCategory);

            if (!string.IsNullOrEmpty(searchCriteria.SubType))
                result = result.Where(_ => _.SubtypeId == searchCriteria.SubType);

            return result;
        }

        internal PagedResults GetPagedResults(IQueryable<ValidSubType> results, CommonQueryParameters queryParameters)
        {
            var total = results.Count();

            var executedResults =
                results.OrderByProperty(MapColumnName(queryParameters.SortBy),
                    queryParameters.SortDir)
                    .Skip(queryParameters.Skip.GetValueOrDefault())
                    .Take(queryParameters.Take.GetValueOrDefault());

            var data = executedResults
                .ToArray()
                .Select(_ => new ValidSubTypeRow
                {
                    Id = new ValidSubTypeIdentifier(_.CountryId, _.PropertyTypeId, _.CaseTypeId, _.CaseCategoryId, _.SubtypeId),
                    Country = _.Country?.Name,
                    PropertyType = _.PropertyType?.Name,
                    CaseType = _.CaseType?.Name,
                    ValidCategory = _.ValidCategory?.CaseCategoryDesc,
                    SubType = _.SubType?.Name,
                    ValidDescription = _.SubTypeDescription
                }).ToArray();

            return new PagedResults(data, total);
        }

        static string MapColumnName(string name)
        {
            return name == "validDescription" ? "SubTypeDesc" : $"{name}.{(name == "validCategory" ? "CaseCategoryDesc" : "Name")}";
        }

        [HttpGet]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public dynamic ValidSubType([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "entitykey")] ValidSubTypeIdentifier validSubTypeIdentifier)
        {
            var validSubType = _validSubTypes.GetValidSubType(validSubTypeIdentifier);
            return validSubType ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Save(SubTypeSaveDetails subTypeSaveDetails)
        {
            return _validSubTypes.Save(subTypeSaveDetails);
        }

        [HttpPut]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Update(SubTypeSaveDetails subTypeSaveDetails)
        {
            var response = _validSubTypes.Update(subTypeSaveDetails);
            return response ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        [HttpPost]
        [Route("delete")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public DeleteResponseModel<ValidSubTypeIdentifier> Delete(ValidSubTypeIdentifier[] deleteRequestModel)
        {
            var response = _validSubTypes.Delete(deleteRequestModel);
            return response ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        public void Copy(CountryModel fromJurisdiction, CountryModel[] toJurisdictions)
        {
            if (fromJurisdiction == null) throw new ArgumentNullException(nameof(fromJurisdiction));
            if (toJurisdictions == null || !toJurisdictions.Any()) throw new ArgumentNullException(nameof(toJurisdictions));

            var validSubTypes = _dbContext.Set<ValidSubType>().Where(_ => _.Country.Id == fromJurisdiction.Code).ToArray();
            foreach (var jurisdiction in toJurisdictions)
            {
                foreach (var vs in validSubTypes.Where(vs => !_dbContext.Set<ValidSubType>()
                    .Any(_ => _.CountryId == jurisdiction.Code && _.PropertyTypeId == vs.PropertyTypeId && _.CaseTypeId == vs.CaseTypeId
                    && _.CaseCategoryId == vs.CaseCategoryId && _.SubtypeId == vs.SubtypeId)))
                {
                    Save(new SubTypeSaveDetails
                    {
                        Jurisdictions = new[] { jurisdiction },
                        PropertyType = new PropertyType(vs.PropertyType.Code, vs.PropertyType.Name),
                        ValidDescription = vs.SubTypeDescription,
                        CaseCategory = new CaseCategory(vs.ValidCategory.CaseCategory.CaseCategoryId, vs.ValidCategory.CaseCategory.Name),
                        SubType = new SubType(vs.SubType.Code, vs.SubType.Name),
                        CaseType = new CaseType(vs.CaseType.Code, vs.CaseType.Name),
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
            return _validSubTypes.ValidateCategory(caseType, caseCategory);
        }

        public class ValidSubTypeRow
        {
            public ValidSubTypeIdentifier Id { get; set; }

            [ExcelHeader("Case Type")]
            public string CaseType { get; set; }

            [ExcelHeader("Jurisdiction")]
            public string Country { get; set; }

            [ExcelHeader("Property Type")]
            public string PropertyType { get; set; }

            [ExcelHeader("Case Category")]
            public string ValidCategory { get; set; }

            [ExcelHeader("Sub Type")]
            public string SubType { get; set; }

            [ExcelHeader("Valid Description")]
            public string ValidDescription { get; set; }
        }
    }
}
