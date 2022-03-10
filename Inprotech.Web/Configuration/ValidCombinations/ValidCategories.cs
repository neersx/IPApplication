using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Web.Characteristics;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Web.Configuration.ValidCombinations
{
    public interface IValidCategories
    {
        CaseCategorySaveDetails ValidCaseCategory(ValidCategoryIdentifier validCategoryIdentifier);
        dynamic Save(CaseCategorySaveDetails saveDetails);
        dynamic Update(CaseCategorySaveDetails saveDetails);
        DeleteResponseModel<ValidCategoryIdentifier> Delete(ValidCategoryIdentifier[] deleteRequestModel);
        ValidatedCharacteristic ValidateCategory(string caseType, string caseCategory);
    }
    public class ValidCategories : IValidCategories
    {
        readonly IDbContext _dbContext;
        readonly IValidCombinationValidator _validator;
        readonly IMultipleClassApplicationCountries _multipleClassApplicationCountries;

        public ValidCategories(IDbContext dbContext,
                               IValidCombinationValidator validator,
                               IMultipleClassApplicationCountries multipleClassApplicationCountries)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _validator = validator ?? throw new ArgumentNullException(nameof(validator));
            _multipleClassApplicationCountries = multipleClassApplicationCountries ?? throw new ArgumentNullException(nameof(multipleClassApplicationCountries));
        }

        public CaseCategorySaveDetails ValidCaseCategory(ValidCategoryIdentifier validCategoryIdentifier)
        {
            var validCategory = _dbContext.Set<ValidCategory>()
                                          .SingleOrDefault(_ => _.CountryId == validCategoryIdentifier.CountryId
                                                                && _.PropertyTypeId == validCategoryIdentifier.PropertyTypeId
                                                                && _.CaseTypeId == validCategoryIdentifier.CaseTypeId
                                                                && _.CaseCategoryId == validCategoryIdentifier.CategoryId);

            if (validCategory == null)
                return null;

            var response = new CaseCategorySaveDetails
            {
                Jurisdictions = new[]
                {
                    new CountryModel
                    {
                        Code = validCategory.CountryId,
                        Value = validCategory.Country.Name
                    }
                },
                PropertyType = new PropertyType(validCategory.PropertyTypeId, validCategory.PropertyType.Name),
                CaseType = new CaseType(validCategory.CaseTypeId, validCategory.CaseType.Name),
                CaseCategory = new CaseCategory(validCategory.CaseCategoryId, validCategory.CaseCategory.Name),
                ValidDescription = validCategory.CaseCategoryDesc,
                MultiClassPropertyApp = validCategory.MultiClassPropertyApp
            };

            if (validCategory.PropertyEventNo.HasValue)
            {
                response.PropertyEvent = new Event
                {
                    Key = validCategory.PropertyEventNo.Value,
                    Code = validCategory.PropertyEvent.Code,
                    Value = validCategory.PropertyEvent.Description
                };
            }

            return response;
        }

        public dynamic Save(CaseCategorySaveDetails saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));

            var validationResult = CheckForErrors(saveDetails);
            if (validationResult != null) return validationResult;

            var multiClassJurisdictions = _multipleClassApplicationCountries.Resolve().ToArray();

            foreach (var entity in saveDetails.Jurisdictions.Select(jurisdiction => TranslateSaveDetailsIntoValidCategory(jurisdiction, saveDetails, multiClassJurisdictions)))
            {
                _dbContext.Set<ValidCategory>().Add(entity);
            }

            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                UpdatedKeys = saveDetails.Jurisdictions.Select(_ => new ValidCategoryIdentifier(_.Code, saveDetails.PropertyType.Code, saveDetails.CaseType.Code, saveDetails.CaseCategory.Code))
            };
        }

        public dynamic Update(CaseCategorySaveDetails saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));
            
            var countryId = saveDetails.Jurisdictions.First().Code;
            var validCategory = _dbContext.Set<ValidCategory>()
                                          .SingleOrDefault(
                                                           _ =>
                                                               _.CountryId == countryId
                                                               && _.PropertyTypeId == saveDetails.PropertyType.Code
                                                               && _.CaseTypeId == saveDetails.CaseType.Code
                                                               && _.CaseCategoryId == saveDetails.CaseCategory.Code);

            if (validCategory == null) return null;

            validCategory.CaseCategoryDesc = saveDetails.ValidDescription;
            validCategory.PropertyEventNo = saveDetails.PropertyEvent != null
                ? (int?)Convert.ToInt64(saveDetails.PropertyEvent.Key)
                : null;
            validCategory.MultiClassPropertyApp = saveDetails.MultiClassPropertyApp;

            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                UpdatedKeys = new ValidCategoryIdentifier(countryId, saveDetails.PropertyType.Code, saveDetails.CaseType.Code, saveDetails.CaseCategory.Code)
            };
        }

        public DeleteResponseModel<ValidCategoryIdentifier> Delete(ValidCategoryIdentifier[] deleteRequestModel)
        {
            if (deleteRequestModel == null) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new DeleteResponseModel<ValidCategoryIdentifier>();

            using (var txScope = _dbContext.BeginTransaction())
            {
                var validCategories = deleteRequestModel.Select(deleteReq =>
                                                                    _dbContext.Set<ValidCategory>().SingleOrDefault(vp => vp.CountryId == deleteReq.CountryId
                                                                                                                          && vp.PropertyTypeId == deleteReq.PropertyTypeId
                                                                                                                          && vp.CaseTypeId == deleteReq.CaseTypeId
                                                                                                                          && vp.CaseCategoryId == deleteReq.CategoryId)).ToArray();

                response.InUseIds = new List<ValidCategoryIdentifier>();

                foreach (var validCategory in validCategories)
                {
                    if (ValidCategoryInUse(validCategory))
                    {
                        response.InUseIds.Add(new ValidCategoryIdentifier(validCategory.CountryId, validCategory.PropertyTypeId,
                                                                          validCategory.CaseTypeId, validCategory.CaseCategoryId));
                    }
                    else
                    {
                        _dbContext.Set<ValidCategory>().Remove(validCategory);
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
                response.Result = "success";
            }
            return response;
        }

        public ValidatedCharacteristic ValidateCategory(string caseType, string caseCategory)
        {
            return _validator.ValidateCaseCategory(caseType, caseCategory);
        }

        ValidCategory TranslateSaveDetailsIntoValidCategory(CountryModel countryModel, CaseCategorySaveDetails saveDetails, IEnumerable<string> multiClassJurisdictions)
        {
            return new ValidCategory
            {
                PropertyTypeId = saveDetails.PropertyType.Code,
                CountryId = countryModel.Code,
                CaseTypeId = saveDetails.CaseType.Code,
                CaseCategoryId = saveDetails.CaseCategory.Code,
                CaseCategoryDesc = saveDetails.ValidDescription,
                MultiClassPropertyApp = multiClassJurisdictions.Any(_ => _.Equals(countryModel.Key))
                                                    && saveDetails.MultiClassPropertyApp.HasValue
                                                    && saveDetails.MultiClassPropertyApp.Value
                                            ? null
                                            : saveDetails.MultiClassPropertyApp,
                PropertyEventNo = saveDetails.PropertyEvent != null ? (int?)Convert.ToInt64(saveDetails.PropertyEvent.Key) : null
            };
        }

        internal ValidationResult CheckForErrors(CaseCategorySaveDetails saveDetails)
        {
            var validationResult = _validator.CheckValidPropertyCombination(saveDetails);
            return validationResult ?? CheckDuplicateValidCombination(saveDetails);
        }

        internal ValidationResult CheckDuplicateValidCombination(CaseCategorySaveDetails saveDetails)
        {
            if (saveDetails.SkipDuplicateCheck) return null;
            var countries = saveDetails.Jurisdictions.Where(country => _dbContext.Set<ValidCategory>()
                                                                                 .Any(
                                                                                      _ =>
                                                                                          _.CountryId == country.Code && _.PropertyTypeId == saveDetails.PropertyType.Code &&
                                                                                          _.CaseTypeId == saveDetails.CaseType.Code && _.CaseCategoryId == saveDetails.CaseCategory.Code)).ToArray();

            return _validator.DuplicateCombinationValidationResult(countries, saveDetails.Jurisdictions.Length);
        }

        internal bool ValidCategoryInUse(ValidCategory validCategory)
        {
            if (_dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                          .Any(_ => (_.Country.Id == validCategory.CountryId || validCategory.CountryId == KnownValues.DefaultCountryCode) &&
                                    _.PropertyType.Code == validCategory.PropertyTypeId && _.Type.Code == validCategory.CaseTypeId &&
                                    _.Category.CaseCategoryId == validCategory.CaseCategoryId))
                return true;

            if (_dbContext.Set<ValidSubType>()
                          .Any(_ => _.Country.Id == validCategory.CountryId &&
                                    _.PropertyType.Code == validCategory.PropertyTypeId &&
                                    _.CaseCategoryId == validCategory.CaseCategoryId &&
                                    _.CaseTypeId == validCategory.CaseTypeId))
                return true;

            if (_dbContext.Set<ValidBasisEx>()
                          .Any(_ => _.CountryId == validCategory.CountryId &&
                                    _.PropertyTypeId == validCategory.PropertyTypeId &&
                                    _.CaseCategoryId == validCategory.CaseCategoryId &&
                                    _.CaseTypeId == validCategory.CaseTypeId))
                return true;

            return false;
        }
    }

    public class ValidCategoryIdentifier
    {
        public ValidCategoryIdentifier(string countryId, string propertyTypeId, string caseTypeId, string categoryId)
        {
            CountryId = countryId;
            PropertyTypeId = propertyTypeId;
            CaseTypeId = caseTypeId;
            CategoryId = categoryId;
        }
        public string CountryId { get; set; }
        public string PropertyTypeId { get; set; }
        public string CaseTypeId { get; set; }
        public string CategoryId { get; set; }
    }

    public class CaseCategorySaveDetails : ValidCombinationSaveModel
    {
        public Event PropertyEvent { get; set; }
        public string ValidDescription { get; set; }
        public bool? MultiClassPropertyApp { get; set; }
    }
}
