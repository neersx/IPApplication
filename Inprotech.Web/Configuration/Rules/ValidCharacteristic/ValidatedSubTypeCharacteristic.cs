using System.Linq;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Characteristics;

namespace Inprotech.Web.Configuration.Rules.ValidCharacteristic
{
    public interface IValidatedSubTypeCharacteristic
    {
        ValidatedCharacteristic GetSubType(string subType, string caseType, string caseCategoryId,
                                                           string propertyTypeId,
                                                           string countryCode);
    }

    public class ValidatedSubTypeCharacteristic : IValidatedSubTypeCharacteristic
    {
        readonly ISubTypes _subTypes;

        public ValidatedSubTypeCharacteristic(ISubTypes subTypes)
        {
            _subTypes = subTypes;
        }

        public ValidatedCharacteristic GetSubType(string subType, string caseType, string caseCategoryId,
                                           string propertyTypeId,
                                           string countryCode)
        {
            if (string.IsNullOrWhiteSpace(subType))
                return new ValidatedCharacteristic();

            var c = _subTypes.Get(caseType,
                                  new[] { countryCode },
                                  new[] { propertyTypeId },
                                  new[] { caseCategoryId }).FirstOrDefault(_ => _.Key == subType);
            if (c.Key != null) return new ValidatedCharacteristic(c.Key, c.Value);

            c = _subTypes.Get(null, new string[0], new string[0], new string[0]).FirstOrDefault(_ => _.Key == subType);
            return new ValidatedCharacteristic(c.Key, c.Value, false);
        }
    }
}
