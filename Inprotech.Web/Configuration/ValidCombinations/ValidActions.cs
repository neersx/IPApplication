using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using System;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Web.Configuration.ValidCombinations
{
    public interface IValidActions
    {
        ActionSaveDetails GetValidAction(ValidActionIdentifier validActionIdentifier);
        dynamic Save(ActionSaveDetails actionSaveDetails);
        dynamic Update(ActionSaveDetails actionSaveDetails);
        DeleteResponseModel<ValidActionIdentifier> Delete(ValidActionIdentifier[] deleteRequestModel);
    }

    public class ValidActions : IValidActions
    {
        readonly IDbContext _dbContext;
        readonly IValidCombinationValidator _validator;

        public ValidActions(IDbContext dbContext, IValidCombinationValidator validator)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _validator = validator ?? throw new ArgumentNullException(nameof(validator));
        }

        public ActionSaveDetails GetValidAction(ValidActionIdentifier validActionIdentifier)
        {
            var validAction = _dbContext.Set<ValidAction>()
                                        .SingleOrDefault(
                                                         _ =>
                                                             _.CountryId == validActionIdentifier.CountryId && _.PropertyTypeId == validActionIdentifier.PropertyTypeId &&
                                                             _.CaseTypeId == validActionIdentifier.CaseTypeId && _.ActionId == validActionIdentifier.ActionId);

            if (validAction == null)
                return null;

            var response = new ActionSaveDetails
            {
                Jurisdictions = new[]
                {
                    new CountryModel
                    {
                        Code = validAction.CountryId,
                        Value = validAction.Country.Name
                    }
                },
                Action = new Picklists.Action(validAction.ActionId, validAction.Action.Name),
                PropertyType = new Picklists.PropertyType(validAction.PropertyTypeId, validAction.PropertyType.Name),
                CaseType = new Picklists.CaseType(validAction.CaseTypeId, validAction.CaseType.Name),
                ValidDescription = validAction.ActionName,
                RetrospectiveEvent = validAction.RetrospectiveEvent != null ? new Picklists.Event
                {
                    Key = validAction.RetrospectiveEvent.Id,
                    Code = validAction.RetrospectiveEvent.Code,
                    Value = validAction.RetrospectiveEvent.Description
                }
                : null,
                DeterminingEvent = validAction.DateOfLawEvent != null ? new Picklists.Event
                {
                    Key = validAction.DateOfLawEvent.Id,
                    Code = validAction.DateOfLawEvent.Code,
                    Value = validAction.DateOfLawEvent.Description
                }
                : null
            };

            return response;
        }

        public dynamic Save(ActionSaveDetails actionSaveDetails)
        {
            if (actionSaveDetails == null) throw new ArgumentNullException(nameof(actionSaveDetails));

            var validationResult = CheckForErrors(actionSaveDetails);
            if (validationResult != null) return validationResult;

            var displaySequence = _dbContext.Set<ValidAction>().Max(m => m.DisplaySequence);

            foreach (var entity in actionSaveDetails.Jurisdictions.Select(jurisdiction => TranslateSaveDetailsIntoValidProperty(jurisdiction, actionSaveDetails)))
            {
                entity.DisplaySequence = ++displaySequence;
                _dbContext.Set<ValidAction>().Add(entity);
            }

            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                RerunSearch = true,
                UpdatedKeys = actionSaveDetails.Jurisdictions.Select(_ => new ValidActionIdentifier(_.Code, actionSaveDetails.PropertyType.Code, actionSaveDetails.CaseType.Code, actionSaveDetails.Action.Code))
            };
        }

        public dynamic Update(ActionSaveDetails actionSaveDetails)
        {
            if (actionSaveDetails == null) throw new ArgumentNullException(nameof(actionSaveDetails));

            var countryId = actionSaveDetails.Jurisdictions.First().Code;
            var validAction = _dbContext.Set<ValidAction>()
                                        .SingleOrDefault(
                                                         _ =>
                                                             _.CountryId == countryId &&
                                                             _.PropertyTypeId == actionSaveDetails.PropertyType.Code &&
                                                             _.CaseTypeId == actionSaveDetails.CaseType.Code &&
                                                             _.ActionId == actionSaveDetails.Action.Code);

            if (validAction == null) return null;

            validAction.ActionName = actionSaveDetails.ValidDescription;
            validAction.DateOfLawEventNo = actionSaveDetails.DeterminingEvent?.Key;
            validAction.RetrospectiveEventNo = actionSaveDetails.RetrospectiveEvent?.Key;
            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                RerunSearch = true,
                UpdatedKeys = new ValidActionIdentifier(countryId, actionSaveDetails.PropertyType.Code, actionSaveDetails.CaseType.Code, actionSaveDetails.Action.Code)
            };
        }

        public DeleteResponseModel<ValidActionIdentifier> Delete(ValidActionIdentifier[] deleteRequestModel)
        {
            if (deleteRequestModel == null) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new DeleteResponseModel<ValidActionIdentifier>();

            using (var txScope = _dbContext.BeginTransaction())
            {
                var validActions = deleteRequestModel.Select(deleteReq =>
                                                                 _dbContext.Set<ValidAction>()
                                                                           .SingleOrDefault(
                                                                                            va =>
                                                                                                va.CountryId == deleteReq.CountryId && va.PropertyTypeId == deleteReq.PropertyTypeId &&
                                                                                                va.CaseTypeId == deleteReq.CaseTypeId && va.ActionId == deleteReq.ActionId)).ToArray();

                response.InUseIds = new List<ValidActionIdentifier>();
                if (validActions[0] == null) return null;
                foreach (var validAction in validActions)
                {
                    if (ValidActionInUse(validAction))
                    {
                        response.InUseIds.Add(new ValidActionIdentifier(validAction.CountryId,
                                                                        validAction.PropertyTypeId, validAction.CaseTypeId, validAction.ActionId));
                    }
                    else
                    {
                        _dbContext.Set<ValidAction>().Remove(validAction);
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

        ValidAction TranslateSaveDetailsIntoValidProperty(CountryModel countryModel, ActionSaveDetails saveDetails)
        {
            return new ValidAction(countryModel.Code, saveDetails.PropertyType.Code, saveDetails.CaseType.Code,
                                   saveDetails.Action.Code)
            {
                ActionName = saveDetails.ValidDescription,
                DateOfLawEventNo = saveDetails.DeterminingEvent?.Key,
                RetrospectiveEventNo = saveDetails.RetrospectiveEvent?.Key
            };
        }

        internal ValidationResult CheckForErrors(ActionSaveDetails saveDetails)
        {
            var validationResult = _validator.CheckValidPropertyCombination(saveDetails);
            return validationResult ?? CheckDuplicateValidCombination(saveDetails);
        }

        internal ValidationResult CheckDuplicateValidCombination(ActionSaveDetails saveDetails)
        {
            if (saveDetails.SkipDuplicateCheck) return null;
            var countries = saveDetails.Jurisdictions.Where(country => _dbContext.Set<ValidAction>()
                                                                                 .Any(_ => _.CountryId == country.Code && _.ActionId == saveDetails.Action.Code
                                                                                           && _.CaseTypeId == saveDetails.CaseType.Code && _.PropertyTypeId == saveDetails.PropertyType.Code))
                                       .ToArray();

            return _validator.DuplicateCombinationValidationResult(countries, saveDetails.Jurisdictions.Length);
        }

        internal bool ValidActionInUse(ValidAction validAction)
        {
            return _dbContext.Set<Case>()
                             .Any(_ => (_.Country.Id == validAction.CountryId || validAction.CountryId == KnownValues.DefaultCountryCode) &&
                                       _.PropertyType.Code == validAction.PropertyTypeId && _.Type.Code == validAction.CaseTypeId &&
                                       _.OpenActions.Any(oa => oa.ActionId == validAction.ActionId));
        }
    }

    public class ValidActionIdentifier
    {
        public ValidActionIdentifier() { }
        public ValidActionIdentifier(string countryId, string propertyTypeId, string caseTypeId, string actionId)
        {
            CountryId = countryId;
            CaseTypeId = caseTypeId;
            PropertyTypeId = propertyTypeId;
            ActionId = actionId;
        }
        public string CountryId { get; set; }
        public string ActionId { get; set; }
        public string PropertyTypeId { get; set; }
        public string CaseTypeId { get; set; }
    }

    public class ActionSaveDetails : ValidCombinationSaveModel
    {
        public Picklists.Action Action { get; set; }
        public string ValidDescription { get; set; }
        public Picklists.Event RetrospectiveEvent { get; set; }
        public Picklists.Event DeterminingEvent { get; set; }
    }
}
