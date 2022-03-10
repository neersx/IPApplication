using System.Linq;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Characteristics;

namespace Inprotech.Web.Configuration.Rules.ValidCharacteristic
{
    public interface IValidatedPropertyTypeCharacteristic
    {
        ValidatedCharacteristic GetPropertyType(string propertyTypeId, string countryCode);
    }

    public class ValidatedPropertyTypeCharacteristic : IValidatedPropertyTypeCharacteristic
    {
        readonly IPropertyTypes _propertyTypes;

        public ValidatedPropertyTypeCharacteristic(IPropertyTypes propertyTypes)
        {
            _propertyTypes = propertyTypes;
        }

        public ValidatedCharacteristic GetPropertyType(string propertyTypeId, string countryCode)
        {
            if (string.IsNullOrWhiteSpace(propertyTypeId))
                return new ValidatedCharacteristic();

            var p = _propertyTypes.Get(null, new[] {countryCode})
                                  .FirstOrDefault(_ => _.Key == propertyTypeId);

            if (p.Key != null)
            {
                return new ValidatedCharacteristic(p.Key, p.Value);
            }
            
            p = _propertyTypes.Get(null, new string[0])
                              .FirstOrDefault(_ => _.Key == propertyTypeId);
            return new ValidatedCharacteristic(p.Key, p.Value, false);
        }
    }
}
