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
    [RoutePrefix("api/configuration/validcombination/basis")]
    [Authorize]
    public class ValidBasisController : ApiController, IValidCombinationBulkController
    {
        readonly IDbContext _dbContext;
        readonly IValidBasisImp _validBasisImp;
        readonly ISimpleExcelExporter _excelExporter;

        static readonly CommonQueryParameters SortByParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "Country",
                SortDir = "asc"
            });

        public ValidBasisController(IDbContext dbContext, IValidBasisImp validBasisImp, ISimpleExcelExporter excelExporter)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _validBasisImp = validBasisImp ?? throw new ArgumentNullException(nameof(validBasisImp));
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
            return GetPagedResults(SearchValidBasis(searchCriteria), SortByParameters.Extend(queryParameters));
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
            var data = GetPagedResults(SearchValidBasis(searchCriteria), SortByParameters.Extend(queryParameters));

            return _excelExporter.Export(data, "Search Result.xlsx");
        }

        internal IQueryable<ValidBasisSearch> SearchValidBasis(ValidCombinationSearchCriteria searchCriteria)
        {
            var validBasis = _dbContext.Set<ValidBasis>().AsQueryable();
            var validBasisEx = _dbContext.Set<ValidBasisEx>().AsQueryable();

            var result = validBasis
                .GroupJoin(validBasisEx,
                    vb => new { vb.CountryId, vb.PropertyTypeId, vb.BasisId },
                    vbe => new { vbe.CountryId, vbe.PropertyTypeId, vbe.BasisId },
                    (o, i) => new { o, i })
                .SelectMany(vbs => vbs.i.DefaultIfEmpty(),
                    (o, i) => new ValidBasisSearch
                              {
                                  Id = new ValidBasisIdentifier
                                  {
                                      BasisId = o.o.BasisId,
                                      CountryId = o.o.Country.Id,
                                      CaseCategoryId = i.CaseCategory.CaseCategoryId,
                                      PropertyTypeId = o.o.PropertyType.Code,
                                      CaseTypeId = i.CaseType.Code
                                  },
                                  Country = o.o.Country.Name,
                                  CountryCode = o.o.Country.Id,
                                  PropertyType = o.o.PropertyType.Name,
                                  PropertyTypeId = o.o.PropertyType.Code,
                                  Basis = o.o.Basis.Name,
                                  BasisId = o.o.Basis.Code,
                                  CaseType = i.CaseType.Name,
                                  CaseTypeId = i.CaseType.Code,
                                  Category = i.CaseCategory.Name,
                                  CategoryId = i.CaseCategory.CaseCategoryId,
                                  ValidDescription = o.o.BasisDescription
                              }).AsQueryable();

            if (!string.IsNullOrEmpty(searchCriteria.PropertyType))
                result = result.Where(_ => _.PropertyTypeId == searchCriteria.PropertyType);

            if (!string.IsNullOrEmpty(searchCriteria.CaseType))
                result = result.Where(_ => _.CaseTypeId == searchCriteria.CaseType);

            if (!string.IsNullOrEmpty(searchCriteria.CaseCategory))
                result = result.Where(_ => _.CategoryId == searchCriteria.CaseCategory);

            if (!string.IsNullOrEmpty(searchCriteria.Basis))
                result = result.Where(_ => _.BasisId == searchCriteria.Basis);

            if (searchCriteria.Jurisdictions.Any())
                result = result.Where(_ => searchCriteria.Jurisdictions.Contains(_.CountryCode));

            return result.OrderBy(r => r.Country).ThenBy(r => r.PropertyType)
                .ThenBy(r => r.CaseType).ThenBy(r => r.Category).ThenBy(r => r.Basis).ThenBy(r => r.ValidDescription);
        }

        internal PagedResults GetPagedResults(IQueryable<ValidBasisSearch> results, CommonQueryParameters queryParameters)
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

        [HttpGet]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public dynamic ValidBasis([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "entitykey")] ValidBasisIdentifier validBasisIdentifier)
        {
            var result = _validBasisImp.GetValidBasis(validBasisIdentifier);

            return result ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        [HttpPut]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Update(BasisSaveDetails basisSaveDetails)
        {
            var result = _validBasisImp.Update(basisSaveDetails);

            return result ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Save(BasisSaveDetails basisSaveDetails)
        {
            return _validBasisImp.Save(basisSaveDetails);
        }

        [HttpPost]
        [Route("delete")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public DeleteResponseModel<ValidBasisIdentifier> Delete(ValidBasisIdentifier[] deleteRequestModel)
        {
            var response = _validBasisImp.Delete(deleteRequestModel);
            return response ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        public void Copy(CountryModel fromJurisdiction, CountryModel[] toJurisdictions)
        {
            if (fromJurisdiction == null) throw new ArgumentNullException("fromJurisdiction");
            if (toJurisdictions == null || !toJurisdictions.Any()) throw new ArgumentNullException("toJurisdictions");

            var validBasis = _dbContext.Set<ValidBasis>().Where(_ => _.Country.Id == fromJurisdiction.Code).ToArray();
            var validBasisEx = _dbContext.Set<ValidBasisEx>().Where(_ => _.CountryId == fromJurisdiction.Code).ToArray();
            foreach (var jurisdiction in toJurisdictions)
            {
                foreach (var vb in validBasis.Where(vb => !_dbContext.Set<ValidBasis>()
                    .Any(_ => _.CountryId == jurisdiction.Code && _.PropertyTypeId == vb.PropertyTypeId && _.BasisId == vb.BasisId)))
                {
                    var vbe = validBasisEx.FirstOrDefault(x => x.CountryId == fromJurisdiction.Code && x.PropertyTypeId == vb.PropertyTypeId
                                                               && x.BasisId == vb.BasisId);

                    CaseCategory caseCategory=null;
                    CaseType caseType = null;
                    if (vbe != null)
                    {
                        caseCategory= new CaseCategory(vbe.CaseCategory.CaseCategoryId, vbe.CaseCategory.Name);
                        caseType=new CaseType(vbe.CaseType.Code, vbe.CaseType.Name);
                    }

                    Save(new BasisSaveDetails
                    {
                        Jurisdictions = new[] { jurisdiction },
                        PropertyType = new PropertyType(vb.PropertyType.Code, vb.PropertyType.Name),
                        Basis = new Basis(vb.Basis.Code, vb.Basis.Name),
                        ValidDescription = vb.BasisDescription,
                        CaseCategory = caseCategory,
                        CaseType = caseType,
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
            return _validBasisImp.ValidateCaseCategory(caseType, caseCategory);
        } 

        public class ValidBasisSearch
        {
            public ValidBasisIdentifier Id { get; set; }

            [ExcelHeader("Case Type")]
            public string CaseType { get; set; }
            public string CaseTypeId { get; set; }

            [ExcelHeader("Jurisdiction")]
            public string Country { get; set; }

            public string CountryCode { get; set; }

            [ExcelHeader("Property Type")]
            public string PropertyType { get; set; }
            public string PropertyTypeId { get; set; }

            [ExcelHeader("Case Category")]
            public string Category { get; set; }
            public string CategoryId { get; set; }

            [ExcelHeader("Basis")]
            public string Basis { get; set; }
            public string BasisId { get; set; }

            [ExcelHeader("Valid Description")]
            public string ValidDescription { get; set; }
        }
    }
}
