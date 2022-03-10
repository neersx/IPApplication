using System.Linq;
using Inprotech.Web.CaseSupportData;

namespace Inprotech.Web.Characteristics
{
    public interface IValidCharacteristicsReader
    {
        ValidatedCharacteristic GetPropertyType(string propertyTypeId, string countryCode = null);
        ValidatedCharacteristic GetCaseCategory(string caseCategory, string caseType = null, string countryCode = null, string propertyTypeId = null);
        ValidatedCharacteristic GetSubType(string subType, string caseType = null, string countryCode = null, string propertyTypeId = null, string caseCategoryId = null);
        ValidatedCharacteristic GetAction(string actionId, string caseType = null, string countryCode = null, string propertyTypeId = null);
        ValidatedCharacteristic GetBasis(string basis, string caseType = null, string caseCategoryId = null, string propertyTypeId = null, string countryCode = null);
    }

    public class ValidCharacteristicsReader : IValidCharacteristicsReader
    {
        private readonly IValidateCharacteristicsValidator _validateCharacteristicsValidator;
        private readonly IPropertyTypes _propertyTypes;
        private readonly ICaseCategories _caseCategories;
        private readonly ISubTypes _subTypes;
        private readonly IBasis _basis;
        private readonly IActions _actions;

        public ValidCharacteristicsReader(IValidateCharacteristicsValidator validateCharacteristicsValidator,
                                          IPropertyTypes propertyTypes, ICaseCategories caseCategories,
                                          ISubTypes subTypes, IBasis basis, IActions actions)
        {
            _validateCharacteristicsValidator = validateCharacteristicsValidator;
            _propertyTypes = propertyTypes;
            _caseCategories = caseCategories;
            _subTypes = subTypes;
            _basis = basis;
            _actions = actions;
        }

        public ValidatedCharacteristic GetPropertyType(string propertyTypeId, string countryCode = null)
        {
            var validPropertyType = _validateCharacteristicsValidator.ValidatePropertyType(propertyTypeId, countryCode);
            if (validPropertyType.IsValid)
                return validPropertyType;

            var p = _propertyTypes.Get(null, new string[0])
                                  .FirstOrDefault(_ => _.Key == propertyTypeId);
            return new ValidatedCharacteristic(p.Key, p.Value, false);
        }

        public ValidatedCharacteristic GetCaseCategory(string caseCategory, string caseType = null, string countryCode = null, string propertyTypeId = null)
        {
            var validCaseCategory = _validateCharacteristicsValidator.ValidateCaseCategory(caseCategory, caseType, countryCode, propertyTypeId);
            if (validCaseCategory.IsValid)
                return validCaseCategory;

            var c = _caseCategories.Get(null, caseType, new string[0], new string[0]).FirstOrDefault(_ => _.Key == caseCategory);
            return new ValidatedCharacteristic(c.Key, c.Value, false);
        }

        public ValidatedCharacteristic GetSubType(string subType, string caseType = null, string countryCode = null, string propertyTypeId = null, string caseCategoryId = null)
        {
            var validSubType = _validateCharacteristicsValidator.ValidateSubType(subType, caseType, countryCode, propertyTypeId, caseCategoryId);
            if (validSubType.IsValid)
                return validSubType;

            var s = _subTypes.Get(null, new string[0], new string[0], new string[0]).FirstOrDefault(_ => _.Key == subType);
            return new ValidatedCharacteristic(s.Key, s.Value, false);
        }

        public ValidatedCharacteristic GetAction(string actionId, string caseType = null, string countryCode = null, string propertyTypeId = null)
        {
            var validAction = _validateCharacteristicsValidator.ValidateAction(actionId, caseType, countryCode, propertyTypeId);
            if (validAction.IsValid)
                return validAction;

            var a = _actions.Get(null, null, null).FirstOrDefault(_ => _.Code == actionId);
            return new ValidatedCharacteristic(a?.Code, a?.Name, false);
        }

        public ValidatedCharacteristic GetBasis(string basis, string caseType = null, string caseCategoryId = null, string propertyTypeId = null, string countryCode = null)
        {
            var validBasis = _validateCharacteristicsValidator.ValidateBasis(basis, caseType, caseCategoryId, propertyTypeId, countryCode);
            if (validBasis.IsValid)
                return validBasis;

            var b = _basis.Get(null, new string[0], new string[0], new string[0]).FirstOrDefault(_ => _.Key.ToString() == basis);
            return new ValidatedCharacteristic(b.Key, b.Value, false);
        }
    }
}