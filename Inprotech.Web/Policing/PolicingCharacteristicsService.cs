using Inprotech.Web.Characteristics;

namespace Inprotech.Web.Policing
{
    public interface IPolicingCharacteristicsService
    {
        dynamic ValidateCharacteristics(InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics characteristics);
        ValidatedCharacteristics GetValidatedCharacteristics(InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics characteristics);
    }

    public class PolicingCharacteristicsService : IPolicingCharacteristicsService
    {
        private readonly IValidateCharacteristicsValidator _validateCharacteristicsValidator;
        private readonly IValidCharacteristicsReader _validCharacteristicsReader;

        public PolicingCharacteristicsService(IValidateCharacteristicsValidator validateCharacteristicsValidator, IValidCharacteristicsReader validCharacteristicsReader)
        {
            _validateCharacteristicsValidator = validateCharacteristicsValidator;
            _validCharacteristicsReader = validCharacteristicsReader;
        }

        public dynamic ValidateCharacteristics(InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics characteristics)
        {
            return new
                   {
                       PropertyType = _validateCharacteristicsValidator.ValidatePropertyType(characteristics.PropertyType, characteristics.Jurisdiction),
                       CaseCategory = _validateCharacteristicsValidator.ValidateCaseCategory(characteristics.CaseCategory, characteristics.CaseType, characteristics.Jurisdiction, characteristics.PropertyType),
                       SubType = _validateCharacteristicsValidator.ValidateSubType(characteristics.SubType, characteristics.CaseType, characteristics.Jurisdiction, characteristics.PropertyType, characteristics.CaseCategory),
                       Action = _validateCharacteristicsValidator.ValidateAction(characteristics.Action, characteristics.CaseType, characteristics.Jurisdiction, characteristics.PropertyType)
                   };
        }

        public ValidatedCharacteristics GetValidatedCharacteristics(InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics characteristics)
        {
            return new ValidatedCharacteristics
                   {
                       PropertyType = _validCharacteristicsReader.GetPropertyType(characteristics.PropertyType, characteristics.Jurisdiction),
                       CaseCategory = _validCharacteristicsReader.GetCaseCategory(characteristics.CaseCategory, characteristics.CaseType, characteristics.Jurisdiction, characteristics.PropertyType),
                       SubType = _validCharacteristicsReader.GetSubType(characteristics.SubType, characteristics.CaseType, characteristics.Jurisdiction, characteristics.PropertyType, characteristics.CaseCategory),
                       Action = _validCharacteristicsReader.GetAction(characteristics.Action, characteristics.CaseType, characteristics.Jurisdiction, characteristics.PropertyType)
                   };
        }
    }
}