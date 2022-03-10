using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Web.Builders.Model.ValidCombinations
{
    public class ValidPropertyBuilder
    {
        public string CountryCode { get; set; }
        public string CountryName { get; set; }
        public string PropertyTypeId { get; set; }
        public string PropertyTypeName { get; set; }

        public ValidProperty Build()
        {
            var countryCode = string.IsNullOrEmpty(CountryCode) ? Fixture.String("Country") : CountryCode;
            var countryName = string.IsNullOrEmpty(CountryName) ? Fixture.String("Country") : CountryName;
            var propertyTypeId = string.IsNullOrEmpty(PropertyTypeId)
                ? Fixture.String("PropertyTypeId")
                : PropertyTypeId;
            var propertyTypeName = string.IsNullOrEmpty(PropertyTypeName)
                ? Fixture.String("PropertyTypeName")
                : PropertyTypeName;

            return new ValidProperty
            {
                CountryId = countryCode,
                PropertyTypeId = propertyTypeId,
                Country = new CountryBuilder {Id = countryCode, Name = countryName}.Build(),
                PropertyType = new PropertyTypeBuilder {Id = propertyTypeId, Name = propertyTypeName}.Build(),
                PropertyName = propertyTypeName
            };
        }
    }
}