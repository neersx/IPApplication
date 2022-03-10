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
    [RoutePrefix("api/configuration/validcombination/relationship")]
    [Authorize]
    public class ValidRelationshipController : ApiController, IValidCombinationBulkController
    {
        readonly IDbContext _dbContext;
        readonly IValidCombinationValidator _validator;
        readonly ISimpleExcelExporter _excelExporter;

        static readonly CommonQueryParameters SortByParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "country",
                SortDir = "asc"
            });

        public ValidRelationshipController(IDbContext dbContext, IValidCombinationValidator validator, ISimpleExcelExporter excelExporter)
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
            return GetPagedResults(SearchValidRelationships(searchCriteria), SortByParameters.Extend(queryParameters));
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
            var data = GetPagedResults(SearchValidRelationships(searchCriteria), SortByParameters.Extend(queryParameters));

            return _excelExporter.Export(data, "Search Result.xlsx");
        }

        internal IQueryable<ValidRelationship> SearchValidRelationships(ValidCombinationSearchCriteria searchCriteria)
        {
            var result = _dbContext.Set<ValidRelationship>().AsQueryable();

            if (!string.IsNullOrEmpty(searchCriteria.PropertyType))
                result = result.Where(_ => _.PropertyTypeId == searchCriteria.PropertyType);

            if (!string.IsNullOrEmpty(searchCriteria.Relationship))
                result = result.Where(_ => _.RelationshipCode == searchCriteria.Relationship);

            if (searchCriteria.Jurisdictions.Any())
                result = result.Where(_ => searchCriteria.Jurisdictions.Contains(_.Country.Id));

            return result;
        }

        internal PagedResults GetPagedResults(IQueryable<ValidRelationship> results, CommonQueryParameters queryParameters)
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
                .Include(_ => _.Relationship)
                .ToArray()
                .Select(_ =>
                            new ValidRelationshipRow
                                {
                                    Id = new ValidRelationshipIdentifier(_.CountryId, _.PropertyTypeId, _.RelationshipCode),
                                    Country = _.Country != null ? _.Country.Name : null,
                                    PropertyType = _.PropertyType != null ? _.PropertyType.Name : null,
                                    Relationship = _.Relationship != null ? _.Relationship.Description : null,
                                    RecipRelationship = _.ReciprocalRelationship != null ? _.ReciprocalRelationship.Description : null
                                }).ToArray();

            return new PagedResults(data, total);
        }

        static string MapColumnName(string name)
        {
            switch (name)
            {
                case "recipRelationship":
                    return "recipRelationship.Description";
                case "relationship":
                    return "relationship.Description";
                default:
                    return string.Format("{0}.{1}", name, "Name");
            }
        }

        [HttpGet]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public dynamic ValidRelationship([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "entitykey")] ValidRelationshipIdentifier validRelationshipIdentifier)
        {
            var validRelationship = _dbContext.Set<ValidRelationship>()
                                        .SingleOrDefault(_ => _.CountryId == validRelationshipIdentifier.CountryId
                                            && _.PropertyTypeId == validRelationshipIdentifier.PropertyTypeId
                                            && _.RelationshipCode == validRelationshipIdentifier.RelationshipCode);

            if (validRelationship == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            var response = new RelationshipSaveDetails
            {
                Jurisdictions = new[]
                {
                    new CountryModel
                                         {
                                            Code = validRelationship.CountryId,
                                            Value = validRelationship.Country.Name
                                         }
                },
                PropertyType = new PropertyType(validRelationship.PropertyTypeId, validRelationship.PropertyType.Name),
                Relationship = new Relationship(validRelationship.RelationshipCode, validRelationship.Relationship.Description)
            };

            if (validRelationship.ReciprocalRelationship != null)
            {
                response.RecipRelationship = new Relationship(validRelationship.ReciprocalRelationshipCode, validRelationship.ReciprocalRelationship.Description);
            }

            return response;
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Save(RelationshipSaveDetails saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException("saveDetails");

            var validationResult = CheckForErrors(saveDetails);
            if (validationResult != null) return validationResult;

            foreach (var entity in saveDetails.Jurisdictions.Select(jurisdiction => TranslateSaveDetailsIntoValidRelationship(jurisdiction, saveDetails)))
            {
                _dbContext.Set<ValidRelationship>().Add(entity);
            }

            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                UpdatedKeys = saveDetails.Jurisdictions.Select(_ => new ValidRelationshipIdentifier(_.Code, saveDetails.PropertyType.Code, saveDetails.Relationship.Code))
            };
        }

        [HttpPut]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Update(RelationshipSaveDetails saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException("saveDetails");

            var countryId = saveDetails.Jurisdictions.First().Code;
            var validRelationship = _dbContext.Set<ValidRelationship>()
                .SingleOrDefault(
                    _ =>
                        _.CountryId == countryId
                        && _.PropertyTypeId == saveDetails.PropertyType.Code
                        && _.RelationshipCode == saveDetails.Relationship.Code);

            if (validRelationship == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            validRelationship.ReciprocalRelationshipCode = saveDetails.RecipRelationship != null ? saveDetails.RecipRelationship.Code : null;

            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                UpdatedKeys = new ValidRelationshipIdentifier(countryId, saveDetails.PropertyType.Code, saveDetails.Relationship.Code)
            };
        }

        [HttpPost]
        [Route("delete")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public DeleteResponseModel<ValidRelationshipIdentifier> Delete(ValidRelationshipIdentifier[] deleteRequestModel)
        {
            if (deleteRequestModel == null) throw new ArgumentNullException("deleteRequestModel");

            var response = new DeleteResponseModel<ValidRelationshipIdentifier>();

            using (var txScope = _dbContext.BeginTransaction())
            {
                var validCategories = deleteRequestModel.Select(deleteReq =>
                                        _dbContext.Set<ValidRelationship>().SingleOrDefault(vp => vp.CountryId == deleteReq.CountryId
                                                                                && vp.PropertyTypeId == deleteReq.PropertyTypeId
                                                                                && vp.RelationshipCode == deleteReq.RelationshipCode)).ToArray();

                response.InUseIds = new List<ValidRelationshipIdentifier>();

                foreach (var validRelationship in validCategories)
                {
                    if (ValidRelationshipInUse(validRelationship))
                    {
                        response.InUseIds.Add(new ValidRelationshipIdentifier(validRelationship.CountryId, validRelationship.PropertyTypeId, validRelationship.RelationshipCode));
                    }
                    else
                    {
                        _dbContext.Set<ValidRelationship>().Remove(validRelationship);
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

            var validRelationships = _dbContext.Set<ValidRelationship>().Where(_ => _.Country.Id == fromJurisdiction.Code).ToArray();
            foreach (var jurisdiction in toJurisdictions)
            {
                foreach (var vr in validRelationships.Where(vr => !_dbContext.Set<ValidRelationship>()
                    .Any(_ => _.CountryId == jurisdiction.Code && _.PropertyTypeId == vr.PropertyTypeId && _.RelationshipCode == vr.RelationshipCode)))
                {
                    Save(new RelationshipSaveDetails
                    {
                        Jurisdictions = new[] { jurisdiction },
                        PropertyType = new PropertyType(vr.PropertyType.Code, vr.PropertyType.Name),
                        Relationship = new Relationship(vr.Relationship.Relationship, vr.Relationship.Description),
                        RecipRelationship = vr.ReciprocalRelationship!=null? new Relationship(vr.ReciprocalRelationship.Relationship, vr.ReciprocalRelationship.Description) : null,
                        SkipDuplicateCheck = true
                    });
                }
            }

            _dbContext.SaveChanges();
        }

        ValidRelationship TranslateSaveDetailsIntoValidRelationship(CountryModel countryModel, RelationshipSaveDetails saveDetails)
        {
            return new ValidRelationship
            {
                PropertyTypeId = saveDetails.PropertyType.Code,
                CountryId = countryModel.Code,
                RelationshipCode = saveDetails.Relationship.Code,
                ReciprocalRelationshipCode = saveDetails.RecipRelationship != null ? saveDetails.RecipRelationship.Code : null
            };
        }

        internal ValidationResult CheckForErrors(RelationshipSaveDetails saveDetails)
        {
            var validationResult = _validator.CheckValidPropertyCombination(saveDetails);
            return validationResult ?? CheckDuplicateValidCombination(saveDetails);
        }

        internal ValidationResult CheckDuplicateValidCombination(RelationshipSaveDetails saveDetails)
        {

            if (saveDetails.SkipDuplicateCheck) return null;
            var countries = saveDetails.Jurisdictions.Where(country => _dbContext.Set<ValidRelationship>()
                .Any(
                    _ =>
                        _.CountryId == country.Code && _.PropertyTypeId == saveDetails.PropertyType.Code &&
                         _.RelationshipCode == saveDetails.Relationship.Code))
                .ToArray();

            return _validator.DuplicateCombinationValidationResult(countries, saveDetails.Jurisdictions.Length);
        }

        internal bool ValidRelationshipInUse(ValidRelationship validRelationship)
        {
            return _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                             .Any(_ => (_.Country.Id == validRelationship.CountryId || validRelationship.CountryId == KnownValues.DefaultCountryCode) &&
                                _.PropertyType.Code == validRelationship.PropertyTypeId && _.RelatedCases.Any(rc => rc.Relationship == validRelationship.RelationshipCode));
        }

        public class ValidRelationshipIdentifier
        {
            public ValidRelationshipIdentifier(string countryId, string propertyTypeId, string relationshipCode)
            {
                CountryId = countryId;
                PropertyTypeId = propertyTypeId;
                RelationshipCode = relationshipCode;

            }
            public string CountryId { get; set; }
            public string PropertyTypeId { get; set; }
            public string RelationshipCode { get; set; }
        }

        public class RelationshipSaveDetails : ValidCombinationSaveModel
        {
            public Relationship Relationship { get; set; }
            public Relationship RecipRelationship { get; set; }
        }

        public class ValidRelationshipRow
        {
            public ValidRelationshipIdentifier Id { get; set; }

            [ExcelHeader("Jurisdiction")]
            public string Country { get; set; }

            [ExcelHeader("Property Type")]
            public string PropertyType { get; set; }

            [ExcelHeader("Relationship")]
            public string Relationship { get; set; }

            [ExcelHeader("Reciprocial Relationship")]
            public string RecipRelationship { get; set; }
        }
    }
}
