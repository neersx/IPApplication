using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;
using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.ModelBinding;

namespace Inprotech.Web.Configuration.ValidCombinations
{
    [RoutePrefix("api/configuration/validcombination/checklist")]
    [Authorize]
    public class ValidChecklistController : ApiController, IValidCombinationBulkController
    {
        readonly IDbContext _dbContext;
        readonly IValidCombinationValidator _validator;
        private readonly ISimpleExcelExporter _excelExporter;

        static readonly CommonQueryParameters SortByParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "Country",
                SortDir = "asc"
            });

        public ValidChecklistController(IDbContext dbContext, IValidCombinationValidator validator, ISimpleExcelExporter excelExporter)
        {
            if (dbContext == null) throw new ArgumentNullException(nameof(dbContext));
            if (validator == null) throw new ArgumentNullException(nameof(validator));
            if (excelExporter == null) throw new ArgumentNullException(nameof(excelExporter));

            _dbContext = dbContext;
            _validator = validator;
            _excelExporter = excelExporter;
        }

        [HttpGet]
        [Route("search")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public PagedResults Search(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "criteria")] ValidCombinationSearchCriteria searchCriteria,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            return GetPagedResults(SearchValidChecklist(searchCriteria), SortByParameters.Extend(queryParameters));
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
            var data = GetPagedResults(SearchValidChecklist(searchCriteria), SortByParameters.Extend(queryParameters));

            return _excelExporter.Export(data, "Search Result.xlsx");
        }

        internal IQueryable<ValidChecklist> SearchValidChecklist(ValidCombinationSearchCriteria searchCriteria)
        {
            var result = _dbContext.Set<ValidChecklist>().AsQueryable();

            if (!string.IsNullOrEmpty(searchCriteria.PropertyType))
                result = result.Where(_ => _.PropertyTypeId == searchCriteria.PropertyType);

            if (searchCriteria.Jurisdictions.Any())
                result = result.Where(_ => searchCriteria.Jurisdictions.Contains(_.CountryId));

            if (!string.IsNullOrEmpty(searchCriteria.CaseType))
                result = result.Where(_ => _.CaseTypeId == searchCriteria.CaseType);

            if (searchCriteria.Checklist.HasValue)
                result = result.Where(_ => _.ChecklistType == searchCriteria.Checklist);

            return result;
        }

        internal PagedResults GetPagedResults(IQueryable<ValidChecklist> results, CommonQueryParameters queryParameters)
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
                .Include(_ => _.CheckList)
                .ToArray()
                .Select(_ =>
                    new ValidChecklistRow
                    {
                        Id = new ValidChecklistIdentifier(_.CountryId, _.PropertyTypeId, _.CaseTypeId, _.ChecklistType),
                        Country = _.Country != null ? _.Country.Name : null,
                        PropertyType = _.PropertyType != null ? _.PropertyType.Name : null,
                        ValidDescription = _.ChecklistDescription,
                        CaseType = _.CaseType != null ? _.CaseType.Name : null,
                        Checklist = _.CheckList != null ? _.CheckList.Description : null
                    }).ToArray();

            return new PagedResults(data, total);
        }

        static string MapColumnName(string name)
        {
            if (name == "validDescription")
                return "ChecklistDesc";

            if (name == "checklist")
                return "CheckList.Description";

            return string.Format("{0}.{1}", name, "Name");
        }

        [HttpGet]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public dynamic ValidChecklist(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "entitykey")] ValidChecklistIdentifier
                validChecklistIdentifier)
        {
            var validChecklist = _dbContext.Set<ValidChecklist>()
                                        .SingleOrDefault(_ => _.CountryId == validChecklistIdentifier.CountryId
                                            && _.PropertyTypeId == validChecklistIdentifier.PropertyTypeId
                                            && _.CaseTypeId == validChecklistIdentifier.CaseTypeId
                                            && _.ChecklistType == validChecklistIdentifier.ChecklistId);

            if (validChecklist == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            var response = new ChecklistSaveDetails
            {
                Jurisdictions = new[]
                {
                    new CountryModel
                    {
                        Code = validChecklist.CountryId,
                        Value = validChecklist.Country.Name
                    }
                },
                PropertyType = new PropertyType(validChecklist.PropertyTypeId, validChecklist.PropertyType.Name),
                CaseType = new CaseType(validChecklist.CaseTypeId, validChecklist.CaseType.Name),
                Checklist = new ChecklistMatcher(validChecklist.ChecklistType, validChecklist.CheckList.Description),
                ValidDescription = validChecklist.ChecklistDescription
            };

            return response;
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Save(ChecklistSaveDetails saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException("saveDetails");

            var validationResult = CheckForErrors(saveDetails);
            if (validationResult != null) return validationResult;

            foreach (var entity in saveDetails.Jurisdictions.Select(jurisdiction => TranslateSaveDetailsIntoValidChecklist(jurisdiction, saveDetails)))
            {
                _dbContext.Set<ValidChecklist>().Add(entity);
            }

            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                UpdatedKeys = saveDetails.Jurisdictions.Select(_ => new ValidChecklistIdentifier(_.Code, saveDetails.PropertyType.Code, saveDetails.CaseType.Code,saveDetails.Checklist.Code))
            };
        }

        [HttpPut]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Update(ChecklistSaveDetails saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException("saveDetails");
            var countryId = saveDetails.Jurisdictions.First().Code;

            var validChecklist = _dbContext.Set<ValidChecklist>()
                .SingleOrDefault(_ => _.CountryId == countryId
                                      && _.PropertyTypeId == saveDetails.PropertyType.Code
                                      && _.CaseTypeId == saveDetails.CaseType.Code
                                      && _.ChecklistType == saveDetails.Checklist.Code);

            if (validChecklist == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            validChecklist.ChecklistDescription = saveDetails.ValidDescription;
            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                UpdatedKeys = new ValidChecklistIdentifier(countryId, saveDetails.PropertyType.Code, saveDetails.CaseType.Code, saveDetails.Checklist.Code)
            };
        }

        [HttpPost]
        [Route("delete")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public DeleteResponseModel<ValidChecklistIdentifier> Delete(ValidChecklistIdentifier[] deleteRequestModel)
        {
            if (deleteRequestModel == null) throw new ArgumentNullException("deleteRequestModel");

            var response = new DeleteResponseModel<ValidChecklistIdentifier>();

            using (var txScope = _dbContext.BeginTransaction())
            {
                var validChecklists = deleteRequestModel.Select(deleteReq =>
                                        _dbContext.Set<ValidChecklist>().SingleOrDefault(vp => vp.CountryId == deleteReq.CountryId
                                                                                && vp.PropertyTypeId == deleteReq.PropertyTypeId
                                                                                && vp.CaseTypeId == deleteReq.CaseTypeId
                                                                                && vp.ChecklistType == deleteReq.ChecklistId)).ToArray();

                response.InUseIds = new List<ValidChecklistIdentifier>();

                foreach (var validChecklist in validChecklists)
                {
                    if (ValidChecklistInUse(validChecklist))
                    {
                        response.InUseIds.Add(new ValidChecklistIdentifier(validChecklist.CountryId, validChecklist.PropertyTypeId,
                                                                           validChecklist.CaseTypeId, validChecklist.ChecklistType));
                    }
                    else
                    {
                        _dbContext.Set<ValidChecklist>().Remove(validChecklist);
                        _dbContext.SaveChanges();
                    }
                }

                txScope.Complete();

                if (response.InUseIds.Any())
                {
                    response.HasError = true;
                    response.Message = ConfigurationResources.InUseErrorMessage;
                    return response;
                }
            }

            return response;
        }

        public void Copy(CountryModel fromJurisdiction, CountryModel[] toJurisdictions)
        {
            if (fromJurisdiction == null) throw new ArgumentNullException("fromJurisdiction");
            if (toJurisdictions == null || !toJurisdictions.Any()) throw new ArgumentNullException("toJurisdictions");

            var validChecklists = _dbContext.Set<ValidChecklist>().Where(_ => _.Country.Id == fromJurisdiction.Code).ToArray();
            foreach (var jurisdiction in toJurisdictions)
            {
                foreach (var vc in validChecklists.Where(vc => !_dbContext.Set<ValidChecklist>()
                    .Any(_ => _.CountryId == jurisdiction.Code && _.PropertyTypeId == vc.PropertyTypeId && _.CaseTypeId == vc.CaseTypeId
                    && _.ChecklistType == vc.ChecklistType)))
                {
                    Save(new ChecklistSaveDetails
                    {
                        Jurisdictions = new[] { jurisdiction },
                        PropertyType = new PropertyType(vc.PropertyType.Code, vc.PropertyType.Name),
                        CaseType = new CaseType(vc.CaseType.Code, vc.CaseType.Name),
                        Checklist = new ChecklistMatcher(vc.CheckList.Id, vc.CheckList.Description),
                        ValidDescription = vc.ChecklistDescription,
                        SkipDuplicateCheck = true
                        
                    });
                }
            }

            _dbContext.SaveChanges();
        }

        ValidChecklist TranslateSaveDetailsIntoValidChecklist(CountryModel countryModel, ChecklistSaveDetails saveDetails)
        {
            return new ValidChecklist
            {
                PropertyTypeId = saveDetails.PropertyType.Code,
                CountryId = countryModel.Code,
                CaseTypeId = saveDetails.CaseType.Code,
                ChecklistType = saveDetails.Checklist.Code,
                ChecklistDescription = saveDetails.ValidDescription
            };
        }

        internal ValidationResult CheckForErrors(ChecklistSaveDetails saveDetails)
        {
            var validationResult = _validator.CheckValidPropertyCombination(saveDetails);
            return validationResult ?? CheckDuplicateValidCombination(saveDetails);
        }

        internal ValidationResult CheckDuplicateValidCombination(ChecklistSaveDetails saveDetails)
        {
            if (saveDetails.SkipDuplicateCheck) return null;
            var countries = saveDetails.Jurisdictions.Where(country => _dbContext.Set<ValidChecklist>()
                .Any(
                    _ =>
                        _.CountryId == country.Code && _.PropertyTypeId == saveDetails.PropertyType.Code &&
                        _.CaseTypeId == saveDetails.CaseType.Code && _.ChecklistType == saveDetails.Checklist.Code))
                .ToArray();

            return _validator.DuplicateCombinationValidationResult(countries, saveDetails.Jurisdictions.Length);
        }

        internal bool ValidChecklistInUse(ValidChecklist validChecklist)
        {
            return _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                             .Any(_ => (_.Country.Id == validChecklist.CountryId || validChecklist.CountryId == KnownValues.DefaultCountryCode) &&
                                _.PropertyType.Code == validChecklist.PropertyTypeId && _.Type.Code == validChecklist.CaseTypeId &&
                                _.CaseChecklists.Any(cc=> cc.CheckListTypeId == validChecklist.ChecklistType));
        }

        public class ValidChecklistIdentifier
        {
            public ValidChecklistIdentifier(string countryId, string propertyTypeId, string caseTypeId, short checklistId)
            {
                CountryId = countryId;
                PropertyTypeId = propertyTypeId;
                CaseTypeId = caseTypeId;
                ChecklistId = checklistId;
            }
            public string CountryId { get; set; }
            public string PropertyTypeId { get; set; }
            public string CaseTypeId { get; set; }
            public short ChecklistId { get; set; }
        }

        public class ChecklistSaveDetails : ValidCombinationSaveModel
        {
            public ChecklistMatcher Checklist { get; set; }
            public string ValidDescription { get; set; }
        }

        public class ValidChecklistRow
        {
            public ValidChecklistIdentifier Id { get; set; }

            [ExcelHeader("Case Type")]
            public string CaseType { get; set; }

            [ExcelHeader("Jurisdiction")]
            public string Country { get; set; }

            [ExcelHeader("Property Type")]
            public string PropertyType { get; set; }

            [ExcelHeader("Checklist")]
            public string Checklist { get; set; }

            [ExcelHeader("Valid Description")]
            public string ValidDescription { get; set; }
        }
    }
}