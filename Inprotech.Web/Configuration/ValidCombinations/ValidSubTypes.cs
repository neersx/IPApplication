using Inprotech.Web.Characteristics;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;
using System;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Web.Configuration.ValidCombinations
{
    public interface IValidSubTypes
    {
        SubTypeSaveDetails GetValidSubType(ValidSubTypeIdentifier validSubTypeIdentifier);
        dynamic Save(SubTypeSaveDetails subTypeSaveDetails);
        dynamic Update(SubTypeSaveDetails subTypeSaveDetails);
        DeleteResponseModel<ValidSubTypeIdentifier> Delete(ValidSubTypeIdentifier[] deleteRequestModel);
        ValidatedCharacteristic ValidateCategory(string caseType, string caseCategory);
    }

    public class ValidSubTypes : IValidSubTypes
    {
        readonly IDbContext _dbContext;
        readonly IValidCombinationValidator _validator;

        public ValidSubTypes(IDbContext dbContext, IValidCombinationValidator validator)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _validator = validator ?? throw new ArgumentNullException(nameof(validator));
        }

        public SubTypeSaveDetails GetValidSubType(ValidSubTypeIdentifier validSubTypeIdentifier)
        {
            var validSubType = _dbContext.Set<ValidSubType>()
                                         .SingleOrDefault(_ => _.CountryId == validSubTypeIdentifier.CountryId
                                                               && _.PropertyTypeId == validSubTypeIdentifier.PropertyTypeId
                                                               && _.SubtypeId == validSubTypeIdentifier.SubTypeId
                                                               && _.CaseCategoryId == validSubTypeIdentifier.CaseCategoryId
                                                               && _.CaseTypeId == validSubTypeIdentifier.CaseTypeId);

            if (validSubType == null)
                return null;

            var response = new SubTypeSaveDetails
            {
                Jurisdictions = new[]
                {
                    new CountryModel
                    {
                        Code = validSubType.CountryId,
                        Value = validSubType.Country.Name
                    }
                },
                PropertyType = new PropertyType(validSubType.PropertyTypeId, validSubType.PropertyType.Name),
                SubType = new SubType(validSubType.SubtypeId, validSubType.SubType.Name),
                CaseType = new CaseType(validSubType.CaseTypeId, validSubType.CaseType.Name),
                CaseCategory = new CaseCategory(validSubType.CaseCategoryId, validSubType.ValidCategory.CaseCategoryDesc),
                ValidDescription = validSubType.SubTypeDescription
            };

            return response;

        }

        public dynamic Save(SubTypeSaveDetails subTypeSaveDetails)
        {
            if (subTypeSaveDetails == null) throw new ArgumentNullException(nameof(subTypeSaveDetails));

            var validCombinationResult = CheckForErrors(subTypeSaveDetails);
            if (validCombinationResult != null) return validCombinationResult;

            foreach (var entity in subTypeSaveDetails.Jurisdictions.Select(jurisdiction => TranslateSaveDetailsIntoValidSubType(jurisdiction, subTypeSaveDetails)))
            {
                _dbContext.Set<ValidSubType>().Add(entity);
            }

            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                UpdatedKeys = subTypeSaveDetails
                    .Jurisdictions
                    .Select(_ =>
                                new ValidSubTypeIdentifier(_.Code,
                                                           subTypeSaveDetails.PropertyType.Code,
                                                           subTypeSaveDetails.CaseType.Code,
                                                           subTypeSaveDetails.CaseCategory.Code,
                                                           subTypeSaveDetails.SubType.Code))
            };
        }

        public dynamic Update(SubTypeSaveDetails subTypeSaveDetails)
        {
            if (subTypeSaveDetails == null) throw new ArgumentNullException(nameof(subTypeSaveDetails));

            var countryId = subTypeSaveDetails.Jurisdictions.First().Code;

            var validSubType = _dbContext.Set<ValidSubType>()
                                         .SingleOrDefault(
                                                          _ =>
                                                              _.CountryId == countryId
                                                              && _.PropertyTypeId == subTypeSaveDetails.PropertyType.Code
                                                              && _.CaseTypeId == subTypeSaveDetails.CaseType.Code
                                                              && _.CaseCategoryId == subTypeSaveDetails.CaseCategory.Code
                                                              && _.SubtypeId == subTypeSaveDetails.SubType.Code);

            if (validSubType == null) return null;

            validSubType.SubTypeDescription = subTypeSaveDetails.ValidDescription;
            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                UpdatedKeys = new ValidSubTypeIdentifier(countryId,
                                                         subTypeSaveDetails.PropertyType.Code,
                                                         subTypeSaveDetails.CaseType.Code,
                                                         subTypeSaveDetails.CaseCategory.Code,
                                                         subTypeSaveDetails.SubType.Code)
            };
        }

        public DeleteResponseModel<ValidSubTypeIdentifier> Delete(ValidSubTypeIdentifier[] deleteRequestModel)
        {
            if (deleteRequestModel == null) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new DeleteResponseModel<ValidSubTypeIdentifier>();

            using (var txScope = _dbContext.BeginTransaction())
            {
                var validSubTypes = deleteRequestModel.Select(deleteReq =>
                                                                  _dbContext.Set<ValidSubType>().SingleOrDefault(vp => vp.CountryId == deleteReq.CountryId
                                                                                                                       && vp.PropertyTypeId == deleteReq.PropertyTypeId
                                                                                                                       && vp.CaseCategoryId == deleteReq.CaseCategoryId
                                                                                                                       && vp.CaseTypeId == deleteReq.CaseTypeId
                                                                                                                       && vp.SubtypeId == deleteReq.SubTypeId)).ToArray();

                response.InUseIds = new List<ValidSubTypeIdentifier>();
                if (validSubTypes[0] == null) return null;
                foreach (var validSubType in validSubTypes)
                {
                    if (ValidSubTypeInUse(validSubType))
                    {
                        response.InUseIds.Add(new ValidSubTypeIdentifier(validSubType.CountryId,
                                                                         validSubType.PropertyTypeId,
                                                                         validSubType.CaseTypeId,
                                                                         validSubType.CaseCategoryId,
                                                                         validSubType.SubtypeId));
                    }
                    else
                    {
                        _dbContext.Set<ValidSubType>().Remove(validSubType);
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

        ValidSubType TranslateSaveDetailsIntoValidSubType(CountryModel countryModel, SubTypeSaveDetails subTypeSaveDetails)
        {
            var validSubType = new ValidSubType(countryModel.Code, subTypeSaveDetails.PropertyType.Code,
                                                subTypeSaveDetails.CaseType.Code, subTypeSaveDetails.CaseCategory.Code, subTypeSaveDetails.SubType.Code)
            {
                SubTypeDescription = subTypeSaveDetails.ValidDescription
            };

            return validSubType;
        }

        internal ValidationResult CheckForErrors(SubTypeSaveDetails saveDetails)
        {
            var validationResult = _validator.CheckValidPropertyCombination(saveDetails);
            if (validationResult != null) return validationResult;

            validationResult = _validator.CheckValidCategoryCombination(saveDetails);
            return validationResult ?? CheckForDuplicateErrors(saveDetails);
        }

        internal ValidationResult CheckForDuplicateErrors(SubTypeSaveDetails subTypeSaveDetails)
        {
            if (subTypeSaveDetails.SkipDuplicateCheck) return null;

            var countries = subTypeSaveDetails.Jurisdictions.Where(country => _dbContext.Set<ValidSubType>()
                                                                                        .Any(_ => _.CountryId == country.Code
                                                                                                  && _.CaseTypeId == subTypeSaveDetails.CaseType.Code
                                                                                                  && _.PropertyTypeId == subTypeSaveDetails.PropertyType.Code
                                                                                                  && _.CaseCategoryId == subTypeSaveDetails.CaseCategory.Code
                                                                                                  && _.SubtypeId == subTypeSaveDetails.SubType.Code))
                                              .ToArray();

            return _validator.DuplicateCombinationValidationResult(countries, subTypeSaveDetails.Jurisdictions.Length);
        }

        internal bool ValidSubTypeInUse(ValidSubType validSubType)
        {
            return _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                             .Any(_ => (_.Country.Id == validSubType.CountryId || validSubType.CountryId == KnownValues.DefaultCountryCode) &&
                                       _.PropertyType.Code == validSubType.PropertyTypeId && _.Type.Code == validSubType.CaseTypeId &&
                                       _.Category.CaseCategoryId == validSubType.CaseCategoryId &&
                                       _.SubType.Code == validSubType.SubtypeId);
        }
    }

    public class ValidSubTypeIdentifier
    {
        public ValidSubTypeIdentifier(string countryId, string propertyTypeId, string caseTypeId, string caseCategoryId, string subTypeId)
        {
            CountryId = countryId;
            PropertyTypeId = propertyTypeId;
            CaseTypeId = caseTypeId;
            CaseCategoryId = caseCategoryId;
            SubTypeId = subTypeId;

        }
        public string CountryId { get; set; }
        public string PropertyTypeId { get; set; }
        public string CaseTypeId { get; set; }
        public string CaseCategoryId { get; set; }
        public string SubTypeId { get; set; }
    }

    public class SubTypeSaveDetails : ValidCombinationSaveModel
    {
        public SubType SubType { get; set; }
        public string ValidDescription { get; set; }
    }
}
