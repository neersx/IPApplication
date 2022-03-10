using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Web.Builders.Model.ValidCombinations
{
    public class ValidSubTypeBuilder : IBuilder<ValidSubType>
    {
        public ValidCategory ValidCategory { get; set; }
        public CaseType CaseType { get; set; }
        public Country Country { get; set; }
        public PropertyType PropertyType { get; set; }
        public SubType SubType { get; set; }
        public string SubTypeDescription { get; set; }

        public ValidSubType Build()
        {
            return new ValidSubType(
                                    ValidCategory ?? new ValidCategoryBuilder().Build(),
                                    Country ?? new CountryBuilder().Build(),
                                    CaseType ?? new CaseTypeBuilder().Build(),
                                    PropertyType ?? new PropertyTypeBuilder().Build(),
                                    SubType ?? new SubTypeBuilder().Build()) {SubTypeDescription = SubTypeDescription ?? Fixture.String()};
        }
    }
}