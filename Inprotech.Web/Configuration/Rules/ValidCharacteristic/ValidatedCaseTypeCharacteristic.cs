using System.Linq;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Characteristics;

namespace Inprotech.Web.Configuration.Rules.ValidCharacteristic
{
    public interface IValidatedCaseTypeCharacteristic
    {
        ValidatedCharacteristic GetCaseType(string caseTypeId);
    }

    public class ValidatedCaseTypeCharacteristic : IValidatedCaseTypeCharacteristic
    {
        readonly ICaseTypes _caseTypes;

        public ValidatedCaseTypeCharacteristic(ICaseTypes caseTypes)
        {
            _caseTypes = caseTypes;
        }

        public ValidatedCharacteristic GetCaseType(string caseTypeId)
        {
            if (string.IsNullOrWhiteSpace(caseTypeId))
                return new ValidatedCharacteristic();

            var ct = _caseTypes.Get().FirstOrDefault(_ => _.Key == caseTypeId);
            return new ValidatedCharacteristic(ct.Key, ct.Value);
        }
    }
}
