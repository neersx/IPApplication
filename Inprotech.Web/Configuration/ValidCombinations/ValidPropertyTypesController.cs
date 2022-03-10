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
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using PropertyType = Inprotech.Web.Picklists.PropertyType;

namespace Inprotech.Web.Configuration.ValidCombinations
{
    [RoutePrefix("api/configuration/validcombination/propertytype")]
    [Authorize]
    public class ValidPropertyTypesController : ApiController, IValidCombinationBulkController
    {
        readonly IDbContext _dbContext;
        readonly ISimpleExcelExporter _excelExporter;
        readonly IValidPropertyTypes _validPropertyTypes;

        static readonly CommonQueryParameters SortByParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "Country",
                SortDir = "asc"
            });

        public ValidPropertyTypesController(IDbContext dbContext, ISimpleExcelExporter excelExporter, IValidPropertyTypes validPropertyTypes)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _excelExporter = excelExporter ?? throw new ArgumentNullException(nameof(excelExporter));
            _validPropertyTypes = validPropertyTypes ?? throw new ArgumentNullException(nameof(validPropertyTypes));
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

        internal IQueryable<ValidProperty> SearchValidProperty(ValidCombinationSearchCriteria searchCriteria)
        {
            var result = _dbContext.Set<ValidProperty>().AsQueryable();

            if (!string.IsNullOrEmpty(searchCriteria.PropertyType))
                result = result.Where(_ => _.PropertyType.Code == searchCriteria.PropertyType);

            if (searchCriteria.Jurisdictions.Any())
                result = result.Where(_ => searchCriteria.Jurisdictions.Contains(_.Country.Id));

            return result;
        }

        internal PagedResults GetPagedResults(IQueryable<ValidProperty> results, CommonQueryParameters queryParameters)
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
                    new ValidPropertyTypesRow
                    {
                        Id = new ValidPropertyIdentifier(_.CountryId, _.PropertyTypeId),
                        CountryId = _.CountryId,
                        Country = _.Country?.Name,
                        PropertyTypeId = _.PropertyTypeId,
                        PropertyType = _.PropertyType?.Name,
                        ValidDescription = _.PropertyName
                    }).ToArray();

            return new PagedResults(data, total);
        }

        static string MapColumnName(string name)
        {
            if (name == "validDescription")
                return "PropertyName";

            return $"{name}.Name";
        }

        [HttpGet]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public dynamic ValidPropertyType([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "entitykey")] ValidPropertyIdentifier validPropertyIdentifier)
        {
            var response = _validPropertyTypes.GetValidPropertyType(validPropertyIdentifier);
            if(response == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            return response;
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Save(PropertyTypeSaveDetails propertyTypeSaveDetails)
        {
            return _validPropertyTypes.Save(propertyTypeSaveDetails);
        }

        [HttpPut]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Update(PropertyTypeSaveDetails propertyTypeSaveDetails)
        {
            var result = _validPropertyTypes.Update(propertyTypeSaveDetails);
            return result ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        [HttpPost]
        [Route("delete")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public DeleteResponseModel<ValidPropertyIdentifier> Delete(ValidPropertyIdentifier[] deleteRequestModel)
        {
            var response = _validPropertyTypes.Delete(deleteRequestModel);
            return response ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        public void Copy(CountryModel fromJurisdiction, CountryModel[] toJurisdictions)
        {
            if (fromJurisdiction == null) throw new ArgumentNullException(nameof(fromJurisdiction));
            if (toJurisdictions == null || !toJurisdictions.Any()) throw new ArgumentNullException(nameof(toJurisdictions));

            var validProperties = _dbContext.Set<ValidProperty>().Where(vp => vp.Country.Id == fromJurisdiction.Code).ToArray();
            foreach (var jurisdiction in toJurisdictions)
            {
                foreach (var vp in validProperties.Where(vp => !_dbContext.Set<ValidProperty>()
                    .Any(evp => evp.CountryId == jurisdiction.Code && evp.PropertyTypeId == vp.PropertyTypeId)))
                {
                    Save(new PropertyTypeSaveDetails
                    {
                        Jurisdictions = new[] { jurisdiction },
                        PropertyType = new PropertyType(vp.PropertyType.Code, vp.PropertyName),
                        AnnuityType = vp.AnnuityType != null ? (AnnuityType)vp.AnnuityType : AnnuityType.NoAnnuity,
                        CycleOffset = vp.CycleOffset,
                        Offset = vp.Offset,
                        ValidDescription = vp.PropertyName,
                        SkipDuplicateCheck = true
                    });
                }
            }

            _dbContext.SaveChanges();
        }

        public class ValidPropertyTypesRow
        {
            public ValidPropertyIdentifier Id { get; set; }
            public string CountryId { get; set; }
            public string PropertyTypeId { get; set; }

            [ExcelHeader("Jurisdiction")]
            public string Country { get; set; }

            [ExcelHeader("Property Type")]
            public string PropertyType { get; set; }

            [ExcelHeader("Valid Description")]
            public string ValidDescription { get; set; }
        }
    }
}
