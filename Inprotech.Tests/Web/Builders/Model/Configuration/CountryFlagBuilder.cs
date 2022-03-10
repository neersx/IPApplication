using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Configuration
{
    public class CountryFlagBuilder : IBuilder<CountryFlag>
    {
        public Country Country { get; set; }

        public int? FlagNumber { get; set; }

        public string FlagName { get; set; }

        public CountryFlag Build()
        {
            return new CountryFlag((Country ?? new CountryBuilder().Build()).Id,
                                   FlagNumber ?? Fixture.Integer(),
                                   FlagName ?? Fixture.String());
        }
    }
}