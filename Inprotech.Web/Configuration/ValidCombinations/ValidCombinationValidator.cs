using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Characteristics;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;
using System;
using System.Linq;

namespace Inprotech.Web.Configuration.ValidCombinations
{
    public interface IValidCombinationValidator
    {
        ValidationResult CheckValidPropertyCombination(ValidCombinationSaveModel saveDetails);

        ValidationResult CheckValidCategoryCombination(ValidCombinationSaveModel subTypeSaveDetails);

        ValidationResult DuplicateCombinationValidationResult(CountryModel[] countries, int totalCountries);

        ValidatedCharacteristic ValidateCaseCategory(string caseType, string caseCategory);
    }

    public class ValidCombinationValidator : IValidCombinationValidator
    {
        readonly IDbContext _dbContext;
        readonly ICaseCategories _caseCategories;

        public ValidCombinationValidator(IDbContext dbContext, ICaseCategories caseCategories)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (caseCategories == null) throw new ArgumentNullException("caseCategories");

            _dbContext = dbContext;
            _caseCategories = caseCategories;
        }

        public ValidationResult CheckValidPropertyCombination(ValidCombinationSaveModel saveDetails)
        {
            var invalidCountries = saveDetails.Jurisdictions.Where(country => !_dbContext.Set<ValidProperty>()
                .Any(_ => _.CountryId == country.Code && _.PropertyTypeId == saveDetails.PropertyType.Code))
                .Select(country => new
                {
                    country.Code,
                    Description = country.Value
                }).ToList();

            if (!invalidCountries.Any())
            {
                return null;
            }

            if (invalidCountries.Count == saveDetails.Jurisdictions.Length)
            {
                return new ValidationResult
                {
                    Result = "Error",
                    Message = ConfigurationResources.ErrorInvalidPropertyTypes
                };
                
            }

            return new ValidationResult
            {
                Result = "confirmation",
                ValidationMessage = ConfigurationResources.InValidPorpertyTypes,
                ConfirmationMessage = ConfigurationResources.ConfirmSaveForValidCombination,
                Countries = invalidCountries.Select(_ => _.Description).ToArray(),
                CountryKeys = invalidCountries.Select(_ => _.Code).ToArray()
            };

        }

        public ValidationResult CheckValidCategoryCombination(ValidCombinationSaveModel subTypeSaveDetails)
        {
            var invalidCombinations = subTypeSaveDetails.Jurisdictions.Where(country => !_dbContext.Set<ValidCategory>()
               .Any(_ => _.CountryId == country.Code
                        && _.PropertyTypeId == subTypeSaveDetails.PropertyType.Code
                        && _.CaseTypeId == subTypeSaveDetails.CaseType.Code
                        && _.CaseCategoryId == subTypeSaveDetails.CaseCategory.Code))
               .Select(country => new
               {
                   country.Code,
                   Description = country.Value
               }).ToList();

            if (!invalidCombinations.Any())
            {
                return null;
            }

            if (invalidCombinations.Count == subTypeSaveDetails.Jurisdictions.Length)
            {
                return new ValidationResult
                {
                    Result = "Error",
                    Message = ConfigurationResources.ErrorInvalidCaseCategories
                };
            }

            return new ValidationResult
            {
                Result = "confirmation",
                ValidationMessage = ConfigurationResources.InvalidCaseCategory,
                ConfirmationMessage = ConfigurationResources.ConfirmSaveForValidCombination,
                Countries = invalidCombinations.Select(_ => _.Description).ToArray(),
                CountryKeys = invalidCombinations.Select(_ => _.Code).ToArray()
            };
        }

        public ValidationResult DuplicateCombinationValidationResult(CountryModel[] countries, int totalCountries)
        {
            if (!countries.Any()) return null;

            if (countries.Length == totalCountries)
            {
                return new ValidationResult
                {
                    Result = "Error",
                    Message = ConfigurationResources.ErrorDuplicateValidCombination
                };
            }

            return new ValidationResult
            {
                Result = "confirmation",
                ValidationMessage = ConfigurationResources.DuplicateValidCombination,
                ConfirmationMessage = ConfigurationResources.ConfirmSaveForValidCombination,
                Countries = countries.Select(_ => _.Value).ToArray(),
                CountryKeys = countries.Select(_ => _.Code).ToArray()
            };
        }

        public ValidatedCharacteristic ValidateCaseCategory(string caseType, string caseCategory)
        {
            if (string.IsNullOrWhiteSpace(caseCategory)) return new ValidatedCharacteristic();
            if (string.IsNullOrWhiteSpace(caseType)) return new ValidatedCharacteristic(isValid: false);

            var categories = _caseCategories.Get(null, caseType, null, null);

            var validCategory = categories.FirstOrDefault(_ => _.Key == caseCategory);
            var isValid = validCategory.Key != null;
            return new ValidatedCharacteristic(validCategory.Key, validCategory.Value, isValid);
        } 
    }
}
