using Inprotech.Web.Characteristics;
using Inprotech.Web.Configuration.Rules;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;

namespace Inprotech.Web.Configuration.SanityCheck
{
    public class SanityCheckCaseCharacteristicsValidator : ICharacteristicsValidator
    {
        readonly IValidateCharacteristicsValidator _validateCharacteristicsValidator;

        public SanityCheckCaseCharacteristicsValidator(IValidateCharacteristicsValidator validateCharacteristicsValidator)
        {
            _validateCharacteristicsValidator = validateCharacteristicsValidator;
        }

        public ValidatedCharacteristics Validate(WorkflowCharacteristics criteria)
        {
            return new ValidatedCharacteristics
            {
                PropertyType = _validateCharacteristicsValidator.ValidatePropertyType(criteria.PropertyType, criteria.Jurisdiction),
                CaseCategory = _validateCharacteristicsValidator.ValidateCaseCategory(criteria.CaseCategory, criteria.CaseType, criteria.Jurisdiction, criteria.PropertyType),
                SubType = _validateCharacteristicsValidator.ValidateSubType(criteria.SubType, criteria.CaseType, criteria.Jurisdiction, criteria.PropertyType, criteria.CaseCategory),
                Basis = _validateCharacteristicsValidator.ValidateBasis(criteria.Basis, criteria.CaseType, criteria.Jurisdiction, criteria.PropertyType, criteria.CaseCategory)
            };
        }
    }
}
