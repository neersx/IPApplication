using System.Collections.Generic;
using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class CountryBuilder : IBuilder<Country>
    {
        public string Id { get; set; }

        public string Name { get; set; }
        public string Adjective { get; set; }

        public string Type { get; set; }

        public List<CountryFlag> CountryFlags { get; set; }

        public Country Build()
        {
            var country = new Country(Id ?? Fixture.String("Id"), Name ?? Fixture.String("Name"));

            country.PostalName = country.Name;
            country.CountryAdjective = Adjective ?? Fixture.String("Adjective");
            country.Type = Type;
            country.CountryFlags = CountryFlags;

            return country;
        }
    }
}