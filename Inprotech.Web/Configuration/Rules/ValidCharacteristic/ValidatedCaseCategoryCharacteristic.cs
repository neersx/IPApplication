using System.Linq;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Characteristics;

namespace Inprotech.Web.Configuration.Rules.ValidCharacteristic
{
    public interface IValidatedCaseCategoryCharacteristic
    {
        ValidatedCharacteristic GetCaseCategory(string caseCategory, string caseType, string propertyTypeId,
                                                                string countryCode);
    }

    public class ValidatedCaseCategoryCharacteristic : IValidatedCaseCategoryCharacteristic
    {
        readonly ICaseCategories _caseCategories;

        public ValidatedCaseCategoryCharacteristic(ICaseCategories caseCategories)
        {
            _caseCategories = caseCategories;
        }

        public ValidatedCharacteristic GetCaseCategory(string caseCategory, string caseType, string propertyTypeId,
                                                string countryCode)
        {
            if (string.IsNullOrWhiteSpace(caseCategory))
                return new ValidatedCharacteristic();

            var c = _caseCategories.Get(null,
                                        caseType,
                                        new[] { countryCode },
                                        new[] { propertyTypeId }).FirstOrDefault(_ => _.Key == caseCategory);
            if (c.Key != null) return new ValidatedCharacteristic(c.Key, c.Value);

            c = _caseCategories.Get(null, caseType, new string[0], new string[0]).FirstOrDefault(_ => _.Key == caseCategory);
            return new ValidatedCharacteristic(c.Key, c.Value, false);
        }
    }
}
