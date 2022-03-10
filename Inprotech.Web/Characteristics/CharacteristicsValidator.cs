using System;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Web.CaseSupportData;

namespace Inprotech.Web.Characteristics
{
    public interface IValidateCharacteristicsValidator
    {
        ValidatedCharacteristic ValidatePropertyType(string propertyType = null, string jurisdiction = null);
        ValidatedCharacteristic ValidateCaseCategory(string caseCategory = null, string caseType = null, string jurisdiction = null, string propertyType = null);
        ValidatedCharacteristic ValidateSubType(string subType = null, string caseType = null, string jurisdiction = null, string propertyType = null, string caseCategory = null);
        ValidatedCharacteristic ValidateBasis(string basis = null, string caseType = null, string jurisdiction = null, string propertyType = null, string caseCategory = null);
        ValidatedCharacteristic ValidateAction(string action = null, string caseType = null, string jurisdiction = null, string propertyType = null);
        ValidatedCharacteristic ValidateChecklist(short? checklist = null, string caseType = null, string jurisdiction = null, string propertyType = null);
    }

    public class ValidateCharacteristicsValidator : IValidateCharacteristicsValidator
    {
        readonly IPropertyTypes _propertyTypes;
        readonly ICaseCategories _caseCategories;
        readonly ISubTypes _subTypes;
        readonly IBasis _basis;
        readonly IActions _actions;
        readonly IChecklists _checklists;

        public ValidateCharacteristicsValidator(IPropertyTypes propertyTypes,
                                                ICaseCategories caseCategories,
                                                ISubTypes subTypes,
                                                IBasis basis, IActions actions, IChecklists checklists)
        {
            if (propertyTypes == null) throw new ArgumentNullException(nameof(propertyTypes));
            if (caseCategories == null) throw new ArgumentNullException(nameof(caseCategories));
            if (subTypes == null) throw new ArgumentNullException(nameof(subTypes));
            if (actions == null) throw new ArgumentNullException(nameof(actions));

            _propertyTypes = propertyTypes;
            _caseCategories = caseCategories;
            _subTypes = subTypes;
            _basis = basis;
            _actions = actions;
            _checklists = checklists;
        }

        public ValidatedCharacteristic ValidatePropertyType(string propertyType = null, string jurisdiction = null)
        {
            if (string.IsNullOrWhiteSpace(propertyType))
                return new ValidatedCharacteristic();

            var propertyTypes = _propertyTypes.Get(null, jurisdiction.AsArrayOrNull());

            var validProperty = propertyTypes
                .FirstOrDefault(_ => _.Key == propertyType);
            var isValid = validProperty.Key != null;

            return new ValidatedCharacteristic(validProperty.Key, validProperty.Value, isValid);
        }

        public ValidatedCharacteristic ValidateCaseCategory(string caseCategory = null, string caseType = null, string jurisdiction = null, string propertyType = null)
        {
            if (string.IsNullOrWhiteSpace(caseCategory)) return new ValidatedCharacteristic();
            if (string.IsNullOrEmpty(caseType)) return new ValidatedCharacteristic(isValid: false);

            var categories = _caseCategories.Get(null,
                                                 caseType,
                                                 jurisdiction.AsArrayOrNull(),
                                                 propertyType.AsArrayOrNull());

            var validCategory = categories.FirstOrDefault(_ => _.Key == caseCategory);
            var isValid = validCategory.Key != null;
            return new ValidatedCharacteristic(validCategory.Key, validCategory.Value, isValid) {Code = validCategory.Key};
        }

        public ValidatedCharacteristic ValidateSubType(string subType = null, string caseType = null, string jurisdiction = null, string propertyType = null, string caseCategory = null)
        {
            if (string.IsNullOrWhiteSpace(subType)) return new ValidatedCharacteristic();

            var types = _subTypes.Get(caseType,
                                      jurisdiction.AsArrayOrNull(),
                                      propertyType.AsArrayOrNull(),
                                      caseCategory.AsArrayOrNull());

            var validSubType = types.FirstOrDefault(_ => _.Key == subType);
            var isValid = validSubType.Key != null;
            return new ValidatedCharacteristic(validSubType.Key, validSubType.Value, isValid);
        }

        public ValidatedCharacteristic ValidateBasis(string basis = null, string caseType = null, string jurisdiction = null, string propertyType = null, string caseCategory = null)
        {
            if (string.IsNullOrWhiteSpace(basis)) return new ValidatedCharacteristic();

            var basisList = _basis.Get(
                                       caseType,
                                       jurisdiction.AsArrayOrNull(),
                                       propertyType.AsArrayOrNull(),
                                       caseCategory.AsArrayOrNull());

            var validBasis = basisList.FirstOrDefault(_ => _.Key == basis);
            var isValid = validBasis.Key != null;
            return new ValidatedCharacteristic(validBasis.Key, validBasis.Value, isValid);
        }

        public ValidatedCharacteristic ValidateAction(string action = null, string caseType = null, string jurisdiction = null, string propertyType = null)
        {
            if (string.IsNullOrWhiteSpace(action)) return new ValidatedCharacteristic();

            var actions = _actions.Get(jurisdiction, propertyType, caseType);

            var validAction = actions.FirstOrDefault(_ => _.Code == action);

            return validAction == null
                ? new ValidatedCharacteristic(isValid: false)
                : new ValidatedCharacteristic(validAction.Code, validAction.Name);
        }

        public ValidatedCharacteristic ValidateChecklist(short? checklist = null, string caseType = null, string jurisdiction = null, string propertyType = null)
        {
            if (checklist == null) return new ValidatedCharacteristic();

            var checklists = _checklists.Get(jurisdiction, propertyType, caseType);

            var validChecklist = checklists.FirstOrDefault(_ => _.Id == checklist);
            var isValid = validChecklist != null;
            return new ValidatedCharacteristic(validChecklist?.Id.ToString(), validChecklist?.Description, isValid);
        }
        
    }
}