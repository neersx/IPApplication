using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;
using System;
using System.Collections.Generic;
using System.Linq;
using Case = InprotechKaizen.Model.Cases.Case;
using PropertyType = Inprotech.Web.Picklists.PropertyType;

namespace Inprotech.Web.Configuration.ValidCombinations
{
    public interface IValidPropertyTypes
    {
        PropertyTypeSaveDetails GetValidPropertyType(ValidPropertyIdentifier validPropertyIdentifier);
        dynamic Save(PropertyTypeSaveDetails propertyTypeSaveDetails);
        dynamic Update(PropertyTypeSaveDetails propertyTypeSaveDetails);
        DeleteResponseModel<ValidPropertyIdentifier> Delete(ValidPropertyIdentifier[] deleteRequestModel);
    }
    public class ValidPropertyTypes : IValidPropertyTypes
    {
        readonly IDbContext _dbContext;
        readonly IValidCombinationValidator _validator;

        public ValidPropertyTypes(IDbContext dbContext, IValidCombinationValidator validator)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _validator = validator ?? throw new ArgumentNullException(nameof(validator));
        }

        public PropertyTypeSaveDetails GetValidPropertyType(ValidPropertyIdentifier validPropertyIdentifier)
        {
            var validProperty = _dbContext.Set<ValidProperty>()
                                          .SingleOrDefault(_ => _.CountryId == validPropertyIdentifier.CountryId && _.PropertyTypeId == validPropertyIdentifier.PropertyTypeId);

            if (validProperty == null)
                return null;

            var response = new PropertyTypeSaveDetails
            {
                Jurisdictions = new[]
                {
                    new CountryModel
                    {
                        Code = validProperty.CountryId,
                        Value = validProperty.Country.Name
                    }
                },
                PropertyType = new PropertyType(validProperty.PropertyTypeId, validProperty.PropertyType.Name),
                ValidDescription = validProperty.PropertyName,
                Offset = validProperty.Offset,
                CycleOffset = validProperty.CycleOffset,
                AnnuityType = validProperty.AnnuityType != null ? (AnnuityType)validProperty.AnnuityType : AnnuityType.NoAnnuity
            };

            return response;
        }

        public dynamic Save(PropertyTypeSaveDetails propertyTypeSaveDetails)
        {
            if (propertyTypeSaveDetails == null) throw new ArgumentNullException(nameof(propertyTypeSaveDetails));
            var validationResult = CheckForErrors(propertyTypeSaveDetails);
            if (validationResult != null) return validationResult;

            foreach (var entity in propertyTypeSaveDetails.Jurisdictions.Select(jurisdiction => TranslateSaveDetailsIntoValidPoperty(jurisdiction, propertyTypeSaveDetails)))
            {
                _dbContext.Set<ValidProperty>().Add(entity);
            }

            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                UpdatedKeys = propertyTypeSaveDetails.Jurisdictions.Select(_ => new ValidPropertyIdentifier(_.Code, propertyTypeSaveDetails.PropertyType.Code))
            };
        }

        public dynamic Update(PropertyTypeSaveDetails propertyTypeSaveDetails)
        {
            if (propertyTypeSaveDetails == null) throw new ArgumentNullException(nameof(propertyTypeSaveDetails));
            var countryId = propertyTypeSaveDetails.Jurisdictions.First().Code;
            var validProperty = _dbContext.Set<ValidProperty>()
                                          .SingleOrDefault(
                                                           _ =>
                                                               _.CountryId == countryId &&
                                                               _.PropertyTypeId == propertyTypeSaveDetails.PropertyType.Code);

            if (validProperty == null) return null;

            validProperty.AnnuityType = Convert.ToByte(propertyTypeSaveDetails.AnnuityType);
            validProperty.Offset = propertyTypeSaveDetails.Offset;
            validProperty.CycleOffset = propertyTypeSaveDetails.CycleOffset;
            validProperty.PropertyName = propertyTypeSaveDetails.ValidDescription;

            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                UpdatedKeys = new ValidPropertyIdentifier(countryId, propertyTypeSaveDetails.PropertyType.Code)
            };
        }

        public DeleteResponseModel<ValidPropertyIdentifier> Delete(ValidPropertyIdentifier[] deleteRequestModel)
        {
            if (deleteRequestModel == null) throw new ArgumentNullException(nameof(deleteRequestModel));
            
            var response = new DeleteResponseModel<ValidPropertyIdentifier>();

            using (var txScope = _dbContext.BeginTransaction())
            {
                var validProperties = deleteRequestModel.Select(deleteReq =>
                                                                    _dbContext.Set<ValidProperty>().SingleOrDefault(vp => vp.CountryId == deleteReq.CountryId && vp.PropertyTypeId == deleteReq.PropertyTypeId)).ToArray();

                if (validProperties[0] == null)
                    return null;

                response.InUseIds = new List<ValidPropertyIdentifier>();

                foreach (var validProperty in validProperties)
                {
                    if (ValidPropertyInUse(validProperty))
                    {
                        response.InUseIds.Add(new ValidPropertyIdentifier(validProperty.CountryId, validProperty.PropertyTypeId));
                    }
                    else
                    {
                        _dbContext.Set<ValidProperty>().Remove(validProperty);
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

        ValidProperty TranslateSaveDetailsIntoValidPoperty(CountryModel countryModel, PropertyTypeSaveDetails saveDetails)
        {
            var validProperty = new ValidProperty
            {
                PropertyTypeId = saveDetails.PropertyType.Code,
                CountryId = countryModel.Code,
                AnnuityType = Convert.ToByte(saveDetails.AnnuityType),
                Offset = saveDetails.Offset,
                CycleOffset = saveDetails.CycleOffset,
                PropertyName = saveDetails.ValidDescription
            };

            return validProperty;
        }

        internal ValidationResult CheckForErrors(PropertyTypeSaveDetails saveDetails)
        {
            if (saveDetails.SkipDuplicateCheck) return null;
            var countries = saveDetails.Jurisdictions.Where(country => _dbContext.Set<ValidProperty>()
                                                                                 .Any(_ => _.CountryId == country.Code && _.PropertyTypeId == saveDetails.PropertyType.Code))
                                       .ToArray();

            return _validator.DuplicateCombinationValidationResult(countries, saveDetails.Jurisdictions.Length);
        }

        internal bool ValidPropertyInUse(ValidProperty validProperty)
        {
            return _dbContext.Set<Case>()
                             .Any(_ => (_.Country.Id == validProperty.CountryId || validProperty.CountryId == KnownValues.DefaultCountryCode) &&
                                       _.PropertyType.Code == validProperty.PropertyTypeId)
                   || _dbContext.Set<ValidBasis>()
                                .Any(_ => _.Country.Id == validProperty.CountryId &&
                                          _.PropertyType.Code == validProperty.PropertyTypeId)
                   || _dbContext.Set<ValidAction>()
                                .Any(_ => _.Country.Id == validProperty.CountryId &&
                                          _.PropertyType.Code == validProperty.PropertyTypeId)
                   || _dbContext.Set<ValidCategory>()
                                .Any(_ => _.Country.Id == validProperty.CountryId &&
                                          _.PropertyType.Code == validProperty.PropertyTypeId)
                   || _dbContext.Set<ValidChecklist>()
                                .Any(_ => _.Country.Id == validProperty.CountryId &&
                                          _.PropertyType.Code == validProperty.PropertyTypeId)
                   || _dbContext.Set<ValidRelationship>()
                                .Any(_ => _.Country.Id == validProperty.CountryId &&
                                          _.PropertyType.Code == validProperty.PropertyTypeId)
                   || _dbContext.Set<ValidStatus>()
                                .Any(_ => _.Country.Id == validProperty.CountryId &&
                                          _.PropertyType.Code == validProperty.PropertyTypeId)
                   || _dbContext.Set<ValidSubType>()
                                .Any(_ => _.Country.Id == validProperty.CountryId &&
                                          _.PropertyType.Code == validProperty.PropertyTypeId)
                   || _dbContext.Set<DateOfLaw>()
                                .Any(_ => _.Country.Id == validProperty.CountryId &&
                                          _.PropertyType.Code == validProperty.PropertyTypeId);
        }
    }

    public class PropertyTypeSaveDetails
    {
        public PropertyTypeSaveDetails()
        {
            SkipDuplicateCheck = false;
        }
        public CountryModel[] Jurisdictions { get; set; }
        public PropertyType PropertyType { get; set; }
        public string ValidDescription { get; set; }
        public AnnuityType AnnuityType { get; set; }
        public int? Offset { get; set; }
        public byte? CycleOffset { get; set; }

        public bool SkipDuplicateCheck { get; set; }
    }

    public enum AnnuityType
    {
        NoAnnuity = 0,
        NextRenewalDate = 2,
        BetweenRenewalDate = 1
    }

    public class ValidPropertyIdentifier
    {
        public ValidPropertyIdentifier(string countryId, string propertyTypeId)
        {
            CountryId = countryId;
            PropertyTypeId = propertyTypeId;
        }
        public string CountryId { get; set; }
        public string PropertyTypeId { get; set; }
    }
}
