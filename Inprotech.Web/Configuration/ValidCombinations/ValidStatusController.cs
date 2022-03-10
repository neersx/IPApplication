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
    [RoutePrefix("api/configuration/validcombination/status")]
    [Authorize]
    public class ValidStatusController : ApiController, IValidCombinationBulkController
    {
        readonly IDbContext _dbContext;
        readonly IValidCombinationValidator _validator;
        readonly ISimpleExcelExporter _excelExporter;

        static readonly CommonQueryParameters SortByParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "Country",
                SortDir = "asc"
            });

        public ValidStatusController(IDbContext dbContext, IValidCombinationValidator validator, ISimpleExcelExporter excelExporter)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (validator == null) throw new ArgumentNullException("validator");
            if (excelExporter == null) throw new ArgumentNullException("excelExporter");

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
            return GetPagedResults(SearchValidStatus(searchCriteria), SortByParameters.Extend(queryParameters));
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
            var data = GetPagedResults(SearchValidStatus(searchCriteria), SortByParameters.Extend(queryParameters));

            return _excelExporter.Export(data, "Search Result.xlsx");
        }

        internal IQueryable<ValidStatus> SearchValidStatus(ValidCombinationSearchCriteria searchCriteria)
        {
            var result = _dbContext.Set<ValidStatus>().AsQueryable();

            if (!string.IsNullOrEmpty(searchCriteria.PropertyType))
                result = result.Where(_ => _.PropertyTypeId == searchCriteria.PropertyType);

            if (!string.IsNullOrEmpty(searchCriteria.CaseType))
                result = result.Where(_ => _.CaseTypeId == searchCriteria.CaseType);

            if (searchCriteria.Status.HasValue)
                result = result.Where(_ => _.StatusCode == searchCriteria.Status);

            if (searchCriteria.Jurisdictions.Any())
                result = result.Where(_ => searchCriteria.Jurisdictions.Contains(_.Country.Id));

            return result;
        }

        internal PagedResults GetPagedResults(IQueryable<ValidStatus> results, CommonQueryParameters queryParameters)
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
                .Include(_ => _.Status)
                .ToArray()
                .Select(_ =>
                    new ValidStatusRow
                    {
                        Id = new ValidStatusIdentifier(_.CountryId, _.PropertyTypeId, _.CaseTypeId, _.StatusCode),
                        Country = _.Country?.Name,
                        PropertyType = _.PropertyType?.Name,
                        CaseType = _.CaseType?.Name,
                        Status = _.Status?.Name,
                        StatusType = _.Status != null && _.Status.IsRenewal
                            ? StatusOptions.Renewal.ToString()
                            : StatusOptions.Case.ToString()
                    }).ToArray();

            return new PagedResults(data, total);
        }

        static string MapColumnName(string name)
        {
            if (name == "statusType") return "Status.RenewalFlag";
            return $"{name}.Name";
        }

        [HttpGet]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public dynamic ValidStatus(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "entitykey")] ValidStatusIdentifier
                validStatusIdentifier)
        {
            var validStatus = _dbContext.Set<ValidStatus>()
                                        .SingleOrDefault(_ => _.CountryId == validStatusIdentifier.CountryId
                                            && _.PropertyTypeId == validStatusIdentifier.PropertyTypeId
                                            && _.CaseTypeId == validStatusIdentifier.CaseTypeId
                                            && _.StatusCode == validStatusIdentifier.StatusCode);

            if (validStatus == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            var response = new StatusSaveDetails
            {
                Jurisdictions = new[]
                {
                    new CountryModel
                    {
                        Code = validStatus.CountryId,
                        Value = validStatus.Country.Name
                    }
                },
                PropertyType = new PropertyType(validStatus.PropertyTypeId, validStatus.PropertyType.Name),
                CaseType = new CaseType(validStatus.CaseTypeId, validStatus.CaseType.Name),
                Status = new Status(validStatus.StatusCode, validStatus.Status.Name)
            };

            return response;
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Save(StatusSaveDetails saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException("saveDetails");

            var validationResult = CheckForErrors(saveDetails);
            if (validationResult != null) return validationResult;

            foreach (var entity in saveDetails.Jurisdictions.Select(jurisdiction => TranslateSaveDetailsIntoValidStatus(jurisdiction, saveDetails)))
            {
                _dbContext.Set<ValidStatus>().Add(entity);
            }

            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                UpdatedKeys = saveDetails.Jurisdictions.Select(_ => new ValidStatusIdentifier(_.Code, saveDetails.PropertyType.Code, saveDetails.CaseType.Code, saveDetails.Status.Key))
            };
        }

        [HttpPost]
        [Route("delete")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public DeleteResponseModel<ValidStatusIdentifier> Delete(ValidStatusIdentifier[] deleteRequestModel)
        {
            if (deleteRequestModel == null) throw new ArgumentNullException("deleteRequestModel");

            var response = new DeleteResponseModel<ValidStatusIdentifier>();

            using (var txScope = _dbContext.BeginTransaction())
            {
                var validStatuss = deleteRequestModel.Select(deleteReq =>
                                        _dbContext.Set<ValidStatus>().SingleOrDefault(vp => vp.CountryId == deleteReq.CountryId
                                                                                && vp.PropertyTypeId == deleteReq.PropertyTypeId
                                                                                && vp.CaseTypeId == deleteReq.CaseTypeId
                                                                                && vp.StatusCode == deleteReq.StatusCode)).ToArray();

                response.InUseIds = new List<ValidStatusIdentifier>();

                foreach (var validStatus in validStatuss)
                {
                    if (ValidStatusInUse(validStatus))
                    {
                        response.InUseIds.Add(new ValidStatusIdentifier(validStatus.CountryId, validStatus.PropertyTypeId, validStatus.CaseTypeId, validStatus.StatusCode));
                    }
                    else
                    {
                        _dbContext.Set<ValidStatus>().Remove(validStatus);
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

            var validStatus = _dbContext.Set<ValidStatus>().Where(_ => _.Country.Id == fromJurisdiction.Code).ToArray();
            foreach (var jurisdiction in toJurisdictions)
            {
                foreach (var vs in validStatus.Where(vs => !_dbContext.Set<ValidStatus>()
                    .Any(_ => _.CountryId == jurisdiction.Code && _.PropertyTypeId == vs.PropertyTypeId && _.CaseTypeId == vs.CaseTypeId
                    && _.StatusCode == vs.StatusCode)))
                {

                    Save(new StatusSaveDetails
                    {
                        Jurisdictions = new[] { jurisdiction },
                        PropertyType = new PropertyType(vs.PropertyType.Code, vs.PropertyType.Name),
                        CaseType = new CaseType(vs.CaseType.Code, vs.CaseType.Name),
                        Status = new Status(vs.Status.Id, vs.Status.Name, vs.Status.IsRenewal),
                        SkipDuplicateCheck = true
                    });
                }
            }

            _dbContext.SaveChanges();
        }

        ValidStatus TranslateSaveDetailsIntoValidStatus(CountryModel countryModel, StatusSaveDetails saveDetails)
        {
            return new ValidStatus
            {
                PropertyTypeId = saveDetails.PropertyType.Code,
                CountryId = countryModel.Code,
                CaseTypeId = saveDetails.CaseType.Code,
                StatusCode = saveDetails.Status.Key
            };
        }

        internal ValidationResult CheckForErrors(StatusSaveDetails saveDetails)
        {
            var validationResult = _validator.CheckValidPropertyCombination(saveDetails);
            return validationResult ?? CheckDuplicateValidCombination(saveDetails);
        }

        internal ValidationResult CheckDuplicateValidCombination(StatusSaveDetails saveDetails)
        {
            if (saveDetails.SkipDuplicateCheck) return null;
            var countries = saveDetails.Jurisdictions.Where(country => _dbContext.Set<ValidStatus>()
                .Any(
                    _ =>
                        _.CountryId == country.Code && _.PropertyTypeId == saveDetails.PropertyType.Code &&
                        _.CaseTypeId == saveDetails.CaseType.Code && _.StatusCode == saveDetails.Status.Key))
                .ToArray();

            return _validator.DuplicateCombinationValidationResult(countries, saveDetails.Jurisdictions.Length);

        }

        internal bool ValidStatusInUse(ValidStatus validStatus)
        {
            return _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                             .Any(_ => (_.Country.Id == validStatus.CountryId || validStatus.CountryId == KnownValues.DefaultCountryCode) && 
                                _.PropertyType.Code == validStatus.PropertyTypeId && _.Type.Code == validStatus.CaseTypeId && 
                                _.CaseStatus.Id == validStatus.StatusCode);
        }

        public class ValidStatusIdentifier
        {
            public ValidStatusIdentifier(string countryId, string propertyTypeId, string caseTypeId, short statusCode)
            {
                CountryId = countryId;
                PropertyTypeId = propertyTypeId;
                CaseTypeId = caseTypeId;
                StatusCode = statusCode;
            }
            public string CountryId { get; set; }
            public string PropertyTypeId { get; set; }
            public string CaseTypeId { get; set; }
            public short StatusCode { get; set; }
        }

        public class StatusSaveDetails : ValidCombinationSaveModel
        {
            public Status Status { get; set; }
        }

        public class ValidStatusRow
        {
            public ValidStatusIdentifier Id { get; set; }

            [ExcelHeader("Case Type")]
            public string CaseType { get; set; }

            [ExcelHeader("Jurisdiction")]
            public string Country { get; set; }

            [ExcelHeader("Property Type")]
            public string PropertyType { get; set; }

            [ExcelHeader("Status")]
            public string Status { get; set; }

            [ExcelHeader("Status Type")]
            public string StatusType { get; set; }
        }
    }
}
