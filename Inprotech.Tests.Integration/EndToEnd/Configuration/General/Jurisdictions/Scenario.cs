using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions
{
    public class Scenario
    {
        const string Country1Code = "ee1";
        const string Country1Name = "e2eCountry 1";
        const string Country1Abbrev = "e2eAbbrev1";
        const string Country1PostalName = "e2eP";
        const string Country1Type = "0";
        const string Country1InformalName = "e2eI";
        const string Country1Adjective = "e2eA";
        const string Country2Code = "ee2";
        const string Country2Name = "e2eCountry 2";
        const string Country2Abbrev = "e2eAbbrev2";
        const string Country2PostalName = "e2ePP";
        const string Country2Type = "1";
        const string Country3Code = "ee3";
        const string Country3Name = "e2eCountry 3";
        const string Country3Abbrev = "e2eAbbrev3";
        const string Country3PostalName = "e2ePPP";
        const string Country3Type = "3";
        const string Country4Code = "ee4";
        const string Country4Name = "e2eCountry 4";
        const string Country4Abbrev = "e2eAbbrev4";
        const string Country4PostalName = "e2ePPPP";
        const string Country4Type = "1";
        const string CountryAttribute = "eeAtt1";

        const string Country5Code = "e2c";
        const string Country5Name = "e2c Country";
        const string Country5PostalName = "e2cP";
        const string Country5Type = "0";

        const int AttrTableType = 50;
        const int AttrTableCode = 5020;
        const string CountryText = "eeText1";
        const int TextTableType = -4901;
        const string TextPropertyType = "P";
        string _isdCode;

        public Scenario()
        {
            DbContext = new SqlDbContext();
        }

        public IDbContext DbContext { get; }

        public dynamic Prepare()
        {
            var nameStyleId = DbContext.Set<TableCode>().First(_ => _.TableTypeId == (int)TableTypes.NameStyle).Id;
            var addressStyleId = DbContext.Set<TableCode>().First(_ => _.TableTypeId == (int)TableTypes.AddressStyle).Id;
            _isdCode = Fixture.String(5);
            var country = new Country(Country1Code, Country1Name, Country1Type)
                          {
                              Abbreviation = Country1Abbrev,
                              PostalName = Country1PostalName,
                              InformalName = Country1InformalName,
                              CountryAdjective = Country1Adjective,
                              IsdCode = _isdCode
                          };
            DbContext.Set<Country>().Add(country);
            DbContext.Set<Country>().Add(new Country(Country2Code, Country2Name, Country2Type) {Abbreviation = Country2Abbrev, PostalName = Country2PostalName});
            DbContext.Set<Country>().Add(new Country(Country3Code, Country3Name, Country3Type) {Abbreviation = Country3Abbrev, PostalName = Country3PostalName});
            DbContext.Set<Country>().Add(new Country(Country4Code, Country4Name, Country4Type) {Abbreviation = Country4Abbrev, PostalName = Country4PostalName});
            DbContext.Set<Country>().Add(new Country(Country5Code, Country5Name, Country5Type) { PostalName = Country5PostalName, NameStyleId = nameStyleId, AddressStyleId = addressStyleId });

            DbContext.Set<State>().Add(new State("e2e1", "e2e State 1", country));
            DbContext.Set<State>().Add(new State("e2e2", "e2e State 2", country));

            var currency = DbContext.Set<Currency>().Add(new Currency("e2e") {Description = "E2E Currency"});
            var taxRate = DbContext.Set<TaxRate>().Add(new TaxRate("e2e") {Description = "E2E Tax Rate"});

            DbContext.Set<CountryFlag>().Add(new CountryFlag(Country2Code, 1, "e2e Flag 1"));
            DbContext.Set<CountryFlag>().Add(new CountryFlag(Country2Code, 2, "e2e Flag 2"));
            DbContext.Set<CountryFlag>().Add(new CountryFlag(Country2Code, 4, "e2e Flag 4"));

            DbContext.Set<TableCode>().Add(new TableCode(AttrTableCode, AttrTableType, CountryAttribute));
            DbContext.Set<TableAttributes>()
                     .Add(new TableAttributes("COUNTRY", Country1Code)
                          {
                              TableCodeId = AttrTableCode,
                              SourceTableId = AttrTableType
                          });
            DbContext.SaveChanges();

            ConfigureGroups();
            ConfigureTexts();

            return new
                   {
                       Searching = new
                                   {
                                       Code = Country1Code,
                                       Description = Country2Name,
                                       ResultCount = 4
                                   },
                       Filtering = new
                                   {
                                       Name = "e2eCountry",
                                       Type = KnownJurisdictionTypes.GetType(Country3Type),
                                       FilterCount = 3, // excludes Internal Use Type
                                       ItemCount = 3
                                   },
                       Details = new
                                 {
                                     Name = Country1Name,
                                     PostalName = Country1PostalName,
                                     InformalName = Country1InformalName,
                                     Adjective = Country1Adjective,
                                     GroupName = Country2Name,
                                     Attribute = CountryAttribute,
                                     Text = CountryText,
                                     Country1Name,
                                     Country2Name,
                                     Country3Name,
                                     Country4Name,
                                     IsdCode = _isdCode,
                                     Currency = currency.Description,
                                     TaxRate = taxRate.Description
                                 }
                   };
        }

        void ConfigureGroups()
        {
            DbContext.Set<CountryGroup>().Add(new CountryGroup(Country2Code, Country1Code));
            DbContext.Set<CountryGroup>().Add(new CountryGroup(Country4Code, Country2Code));
            DbContext.SaveChanges();
        }

        void ConfigureTexts()
        {
            var textType = DbContext.Set<TableCode>().SingleOrDefault(_ => _.Id == TextTableType);
            var propertyType = DbContext.Set<PropertyType>().SingleOrDefault(_ => _.Code == TextPropertyType);
            DbContext.Set<CountryText>()
                     .Add(new CountryText(Country1Code, textType, propertyType) {Text = CountryText});
            DbContext.SaveChanges();
        }
    }
}