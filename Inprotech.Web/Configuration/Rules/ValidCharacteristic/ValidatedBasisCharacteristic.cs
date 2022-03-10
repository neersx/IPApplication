using System.Linq;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Characteristics;

namespace Inprotech.Web.Configuration.Rules.ValidCharacteristic
{
    public interface IValidatedBasisCharacteristic
    {
        ValidatedCharacteristic GetBasis(string basis, string caseType, string caseCategoryId,
                                                         string propertyTypeId,
                                                         string countryCode);
    }

    public class ValidatedBasisCharacteristic : IValidatedBasisCharacteristic
    {
        readonly IBasis _basis;

        public ValidatedBasisCharacteristic(IBasis basis)
        {
            _basis = basis;
        }

        public ValidatedCharacteristic GetBasis(string basis, string caseType, string caseCategoryId,
                                         string propertyTypeId,
                                         string countryCode)
        {
            if (string.IsNullOrWhiteSpace(basis))
                return new ValidatedCharacteristic();

            var b = _basis.Get(caseType,
                               new[] { countryCode },
                               new[] { propertyTypeId },
                               new[] { caseCategoryId }).Where(_ => _.Key == basis).FirstOrDefault(_ => _.Key == basis);
            if (b.Key != null) return new ValidatedCharacteristic(b.Key, b.Value);

            b = _basis.Get(null, new string[0], new string[0], new string[0]).FirstOrDefault(_ => _.Key.ToString() == basis);
            return new ValidatedCharacteristic(b.Key, b.Value, false);
        }
    }
}
