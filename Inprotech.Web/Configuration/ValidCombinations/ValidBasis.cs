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
    public interface IValidBasisImp
    {
        BasisSaveDetails GetValidBasis(ValidBasisIdentifier validBasisIdentifier);
        dynamic Update(BasisSaveDetails basisSaveDetails);
        dynamic Save(BasisSaveDetails basisSaveDetails);
        DeleteResponseModel<ValidBasisIdentifier> Delete(ValidBasisIdentifier[] deleteRequestModel);
        ValidatedCharacteristic ValidateCaseCategory(string caseType, string caseCategory);

    }
    public class ValidBasisImp : IValidBasisImp
    {
        readonly IDbContext _dbContext;
        readonly IValidCombinationValidator _validator;

        public ValidBasisImp(IDbContext dbContext, IValidCombinationValidator validator)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _validator = validator ?? throw new ArgumentNullException(nameof(validator));
        }

        public BasisSaveDetails GetValidBasis(ValidBasisIdentifier validBasisIdentifier)
        {
            var validBasis = _dbContext.Set<ValidBasis>()
                                       .SingleOrDefault(_ => _.BasisId == validBasisIdentifier.BasisId
                                                             && _.CountryId == validBasisIdentifier.CountryId
                                                             && _.PropertyTypeId == validBasisIdentifier.PropertyTypeId);

            if (validBasis == null)
                return null;

            ValidBasisEx validBasisEx = null;

            if (!string.IsNullOrEmpty(validBasisIdentifier.CaseCategoryId))
            {
                validBasisEx = _dbContext.Set<ValidBasisEx>()
                                         .SingleOrDefault(_ => _.BasisId == validBasisIdentifier.BasisId
                                                               && _.CountryId == validBasisIdentifier.CountryId
                                                               && _.PropertyTypeId == validBasisIdentifier.PropertyTypeId
                                                               && _.CaseTypeId == validBasisIdentifier.CaseTypeId
                                                               && _.CaseCategoryId == validBasisIdentifier.CaseCategoryId);
            }

            return new BasisSaveDetails
            {
                Jurisdictions = new[]
                {
                    new CountryModel
                    {
                        Code = validBasis.CountryId,
                        Value = validBasis.Country.Name
                    }
                },
                Basis = new Basis(validBasis.Basis.Code, validBasis.Basis.Name),
                PropertyType = new PropertyType(validBasis.PropertyType.Code, validBasis.PropertyType.Name),
                CaseType = validBasisEx != null ? new CaseType(validBasisEx.CaseType.Code, validBasisEx.CaseType.Name) : null,
                CaseCategory = validBasisEx != null ? new CaseCategory(validBasisEx.CaseCategory.CaseCategoryId, validBasisEx.CaseCategory.Name) : null,
                ValidDescription = validBasis.BasisDescription
            };
        }

        public dynamic Update(BasisSaveDetails basisSaveDetails)
        {
            if (basisSaveDetails == null) throw new ArgumentNullException(nameof(basisSaveDetails));

            var countryId = basisSaveDetails.Jurisdictions.First().Code;

            var validBasis = _dbContext.Set<ValidBasis>()
                                       .SingleOrDefault(
                                                        _ =>
                                                            _.CountryId == countryId
                                                            && _.PropertyTypeId == basisSaveDetails.PropertyType.Code
                                                            && _.BasisId == basisSaveDetails.Basis.Code);

            if (validBasis == null) return null;

            validBasis.BasisDescription = basisSaveDetails.ValidDescription;
            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                RerunSearch = true,
                UpdatedKeys = new ValidBasisIdentifier
                {
                    BasisId = basisSaveDetails.Basis.Code,
                    CountryId = countryId,
                    CaseCategoryId = basisSaveDetails.CaseCategory?.Code,
                    PropertyTypeId = basisSaveDetails.PropertyType.Code,
                    CaseTypeId = basisSaveDetails.CaseType?.Code
                }
            };
        }

        public dynamic Save(BasisSaveDetails basisSaveDetails)
        {
            if (basisSaveDetails == null) throw new ArgumentNullException(nameof(basisSaveDetails));

            var validCombinationResult = CheckForErrors(basisSaveDetails);
            if (validCombinationResult != null) return validCombinationResult;

            foreach (var entity in basisSaveDetails.Jurisdictions
                                                   .Where(jurisdiction => !ValidBasisExists(jurisdiction.Code, basisSaveDetails.PropertyType.Code, basisSaveDetails.Basis.Code))
                                                   .Select(jurisdiction => TranslateSaveDetailsIntoValidBasis(jurisdiction, basisSaveDetails)))
            {
                _dbContext.Set<ValidBasis>().Add(entity);
            }

            foreach (var country in basisSaveDetails.Jurisdictions
                                                    .Where(
                                                           jurisdiction =>
                                                               ValidBasisExists(jurisdiction.Code, basisSaveDetails.PropertyType.Code, basisSaveDetails.Basis.Code)))
            {
                var validBasis = _dbContext.Set<ValidBasis>().Single(_ => _.BasisId == basisSaveDetails.Basis.Code
                                                                          && _.CountryId == country.Code
                                                                          && _.PropertyTypeId == basisSaveDetails.PropertyType.Code);
                validBasis.BasisDescription = basisSaveDetails.ValidDescription;
            }

            if (!string.IsNullOrEmpty(basisSaveDetails.CaseCategory?.Code))
            {
                foreach (var entity in basisSaveDetails.Jurisdictions
                                                       .Select(jurisdiction => TranslateSaveDetailsIntoValidBasisEx(jurisdiction, basisSaveDetails)))
                {
                    _dbContext.Set<ValidBasisEx>().Add(entity);
                }
            }

            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                RerunSearch = true,
                UpdatedKeys = basisSaveDetails
                    .Jurisdictions
                    .Select(_ =>
                                new ValidBasisIdentifier
                                {
                                    BasisId = basisSaveDetails.Basis.Code,
                                    CountryId = _.Code,
                                    CaseCategoryId = basisSaveDetails.CaseCategory?.Code,
                                    PropertyTypeId = basisSaveDetails.PropertyType.Code,
                                    CaseTypeId = basisSaveDetails.CaseType != null && basisSaveDetails.CaseCategory != null ? basisSaveDetails.CaseType.Code : null
                                })
            };
        }

        public DeleteResponseModel<ValidBasisIdentifier> Delete(ValidBasisIdentifier[] deleteRequestModel)
        {
            if (deleteRequestModel == null) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new DeleteResponseModel<ValidBasisIdentifier>();

            using (var txScope = _dbContext.BeginTransaction())
            {
                response.InUseIds = new List<ValidBasisIdentifier>();

                foreach (var validIdentifier in deleteRequestModel)
                {
                    if (!string.IsNullOrEmpty(validIdentifier.CaseCategoryId))
                    {
                        var validBasisEx =
                            _dbContext.Set<ValidBasisEx>().SingleOrDefault(_ => _.CountryId == validIdentifier.CountryId
                                                                                && _.BasisId == validIdentifier.BasisId
                                                                                && _.PropertyTypeId == validIdentifier.PropertyTypeId
                                                                                && _.CaseTypeId == validIdentifier.CaseTypeId
                                                                                && _.CaseCategoryId == validIdentifier.CaseCategoryId);

                        if (validBasisEx == null)
                        {
                            response.InUseIds.Add(new ValidBasisIdentifier(validIdentifier.CountryId, validIdentifier.PropertyTypeId, validIdentifier.BasisId, validIdentifier.CaseTypeId, validIdentifier.CaseCategoryId));
                        }
                        else if (ValidBasisExInUse(validBasisEx))
                        {
                            response.InUseIds.Add(new ValidBasisIdentifier(validBasisEx.CountryId, validBasisEx.PropertyTypeId, validBasisEx.BasisId, validBasisEx.CaseTypeId, validBasisEx.CaseCategoryId));
                        }
                        else
                        {
                            _dbContext.Set<ValidBasisEx>().Remove(validBasisEx);
                            _dbContext.SaveChanges();
                        }
                    }
                    else
                    {
                        var validBasis = _dbContext.Set<ValidBasis>().SingleOrDefault(_ => _.CountryId == validIdentifier.CountryId
                                                                                       && _.BasisId == validIdentifier.BasisId
                                                                                       && _.PropertyTypeId == validIdentifier.PropertyTypeId);

                        if (validBasis != null && ValidBasisInUse(validBasis))
                        {
                            response.InUseIds.Add(new ValidBasisIdentifier(validBasis.CountryId, validBasis.PropertyTypeId, validBasis.BasisId, null, null));
                        }
                        else
                        {
                            _dbContext.Set<ValidBasis>().Remove(validBasis);
                            _dbContext.SaveChanges();
                        }
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

        ValidBasis TranslateSaveDetailsIntoValidBasis(CountryModel countryModel, BasisSaveDetails basisSaveDetails)
        {
#pragma warning disable 618
            var validBasis = new ValidBasis
#pragma warning restore 618
            {
                CountryId = countryModel.Code,
                PropertyTypeId = basisSaveDetails.PropertyType.Code,
                BasisId = basisSaveDetails.Basis.Code,
                BasisDescription = basisSaveDetails.ValidDescription
            };

            return validBasis;
        }

        public ValidatedCharacteristic ValidateCaseCategory(string caseType, string caseCategory)
        {
            return _validator.ValidateCaseCategory(caseType, caseCategory);
        }

        bool ValidBasisExists(string countryId, string propertyTypeId, string basisId)
        {
            return _dbContext.Set<ValidBasis>()
                             .Any(_ => _.CountryId == countryId
                                       && _.PropertyTypeId == propertyTypeId
                                       && _.BasisId == basisId);
        }

        ValidBasisEx TranslateSaveDetailsIntoValidBasisEx(CountryModel countryModel, BasisSaveDetails basisSaveDetails)
        {
            var validBasisEx = new ValidBasisEx
            {
                CountryId = countryModel.Code,
                PropertyTypeId = basisSaveDetails.PropertyType.Code,
                BasisId = basisSaveDetails.Basis.Code,
                CaseTypeId = basisSaveDetails.CaseType.Code,
                CaseCategoryId = basisSaveDetails.CaseCategory.Code
            };

            return validBasisEx;
        }

        internal ValidationResult CheckForErrors(BasisSaveDetails saveDetails)
        {
            var validationResult = _validator.CheckValidPropertyCombination(saveDetails);
            if (validationResult != null) return validationResult;

            if (!string.IsNullOrEmpty(saveDetails.CaseCategory?.Code))
                validationResult = _validator.CheckValidCategoryCombination(saveDetails);

            return validationResult ?? CheckForDuplicateErrors(saveDetails);
        }

        internal ValidationResult CheckForDuplicateErrors(BasisSaveDetails basisSaveDetails)
        {
            if (basisSaveDetails.SkipDuplicateCheck) return null;
            if (basisSaveDetails.CaseCategory != null && !string.IsNullOrEmpty(basisSaveDetails.CaseCategory.Code))
            {
                var extensionCountries = basisSaveDetails.Jurisdictions.Where(country => _dbContext.Set<ValidBasisEx>()
                                                                                                   .Any(_ => _.CountryId == country.Code
                                                                                                             && _.PropertyTypeId == basisSaveDetails.PropertyType.Code
                                                                                                             && _.BasisId == basisSaveDetails.Basis.Code
                                                                                                             && _.CaseTypeId == basisSaveDetails.CaseType.Code
                                                                                                             && _.CaseCategoryId == basisSaveDetails.CaseCategory.Code))
                                                         .ToArray();

                return _validator.DuplicateCombinationValidationResult(extensionCountries, basisSaveDetails.Jurisdictions.Length);
            }

            var countries = basisSaveDetails.Jurisdictions.Where(country => _dbContext.Set<ValidBasis>()
                                                                                      .Any(_ => _.CountryId == country.Code
                                                                                                && _.PropertyTypeId == basisSaveDetails.PropertyType.Code
                                                                                                && _.BasisId == basisSaveDetails.Basis.Code))
                                            .ToArray();

            return _validator.DuplicateCombinationValidationResult(countries, basisSaveDetails.Jurisdictions.Length);
        }

        internal bool ValidBasisInUse(ValidBasis validBasis)
        {
            return _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                             .Any(_ => (_.Country.Id == validBasis.CountryId || validBasis.CountryId == KnownValues.DefaultCountryCode) &&
                                       _.PropertyType.Code == validBasis.PropertyTypeId && _.Property.Basis == validBasis.BasisId) ||
                   _dbContext.Set<ValidBasisEx>().Any(_ => _.CountryId == validBasis.CountryId && _.PropertyTypeId == validBasis.PropertyTypeId && _.BasisId == validBasis.BasisId);
        }

        internal bool ValidBasisExInUse(ValidBasisEx validBasisEx)
        {
            return _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                             .Any(_ => (_.Country.Id == validBasisEx.CountryId || validBasisEx.CountryId == KnownValues.DefaultCountryCode) &&
                                       _.PropertyType.Code == validBasisEx.PropertyTypeId && _.Type.Code == validBasisEx.CaseTypeId &&
                                       _.Category.CaseCategoryId == validBasisEx.CaseCategoryId && _.Property.Basis == validBasisEx.BasisId);
        }
    }

    public class BasisSaveDetails : ValidCombinationSaveModel
    {
        public Basis Basis { get; set; }
        public string ValidDescription { get; set; }
    }

    public class ValidBasisIdentifier
    {
        public ValidBasisIdentifier() { }

        public ValidBasisIdentifier(string countryId, string propertyTypeId, string basisId, string caseTypeId, string caseCategoryId)
        {
            CountryId = countryId;
            PropertyTypeId = propertyTypeId;
            BasisId = basisId;
            CaseTypeId = caseTypeId;
            CaseCategoryId = caseCategoryId;
        }

        public string CountryId { get; set; }
        public string PropertyTypeId { get; set; }
        public string CaseTypeId { get; set; }
        public string CaseCategoryId { get; set; }
        public string BasisId { get; set; }
    }
}
