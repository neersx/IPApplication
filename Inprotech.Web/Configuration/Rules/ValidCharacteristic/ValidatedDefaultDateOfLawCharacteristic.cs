using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Characteristics;

namespace Inprotech.Web.Configuration.Rules.ValidCharacteristic
{

    public interface IValidatedDefaultDateOfLawCharacteristic
    {
        ValidatedCharacteristic GetDefaultDateOfLaw(int caseId, string action);
    }

    public class ValidatedDefaultDateOfLawCharacteristic : IValidatedDefaultDateOfLawCharacteristic
    {
        readonly IDateOfLaw _dateOfLaw;
        readonly IFormatDateOfLaw _formatDateOfLaw;

        public ValidatedDefaultDateOfLawCharacteristic(IDateOfLaw dateOfLaw, IFormatDateOfLaw formatDateOfLaw)
        {
            _dateOfLaw = dateOfLaw;
            _formatDateOfLaw = formatDateOfLaw;
        }

        public ValidatedCharacteristic GetDefaultDateOfLaw(int caseId, string action)
        {
            if (string.IsNullOrWhiteSpace(action))
                return new ValidatedCharacteristic();

            var dateOfLaw = _dateOfLaw.GetDefaultDateOfLaw(caseId, action);

            return dateOfLaw == null
                ? new ValidatedCharacteristic()
                : new ValidatedCharacteristic(_formatDateOfLaw.AsId(dateOfLaw.Value), _formatDateOfLaw.Format(dateOfLaw.Value));
        }
    }
}
