using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Web.Builders.Model.ValidCombinations
{
    public class ValidBasisBuilder : IBuilder<ValidBasis>
    {
        public Country Country { get; set; }
        public PropertyType PropertyType { get; set; }
        public ApplicationBasis Basis { get; set; }
        public string BasisDesc { get; set; }

        public ValidBasis Build()
        {
            return new ValidBasis(
                                  Country ?? new CountryBuilder().Build(),
                                  PropertyType ?? new PropertyTypeBuilder().Build(),
                                  Basis ?? new ApplicationBasis(Fixture.String(), Fixture.String()))
            {
                BasisDescription = BasisDesc ?? (Basis != null ? Basis.Name : Fixture.String("ValidBasis"))
            };
        }
    }
}