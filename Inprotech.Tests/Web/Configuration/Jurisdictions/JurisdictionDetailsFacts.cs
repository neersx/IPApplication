using System.Collections.Generic;
using System.Linq;
using System.Web;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Configuration.Jurisdictions;
using Inprotech.Web.Configuration.ValidCombinations;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;
using JurisdictionSearch = Inprotech.Web.Configuration.ValidCombinations.JurisdictionSearch;
using TaxRate = InprotechKaizen.Model.Accounting.Tax.TaxRate;

namespace Inprotech.Tests.Web.Configuration.Jurisdictions
{
    public class JurisdictionDetailsFacts
    {
        public class JurisdictionDetailsFixture : IFixture<JurisdictionDetails>
        {
            public JurisdictionDetailsFixture(InMemoryDbContext db)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                ValidJurisdictionDetails = Substitute.For<IValidJurisdictionsDetails>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                Subject = new JurisdictionDetails(db, PreferredCultureResolver, ValidJurisdictionDetails, TaskSecurityProvider);
                CommonQueryParameters = CommonQueryParameters.Default;
                CommonQueryParameters.SortBy = null;
                CommonQueryParameters.SortDir = null;
            }

            public CommonQueryParameters CommonQueryParameters { get; set; }
            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public IValidJurisdictionsDetails ValidJurisdictionDetails { get; set; }
            public ITaskSecurityProvider TaskSecurityProvider { get; set; }
            public JurisdictionDetails Subject { get; set; }
        }

        public class GetOverviewMethod : FactBase
        {
            [Fact]
            public void ReturnsAddressSettingsForMatchingJurisdiction()
            {
                const string validCountryCode = "BB";
                var validCountryName = Fixture.String(validCountryCode);
                var nameStyle = new TableCode(Fixture.Integer(), Fixture.Short(), "Surname Last").In(Db);
                var addressStyle = new TableCode(Fixture.Integer(), Fixture.Short(), "City before PostCode - Full State").In(Db);
                var f = new JurisdictionDetailsFixture(Db);

                var j = Db.Set<Country>();
                j.Add(new Country("AX", Fixture.String("AX"), Fixture.String()));
                j.Add(new Country(validCountryCode, validCountryName, Fixture.String()) {NameStyle = nameStyle, AddressStyle = addressStyle});

                var r = f.Subject.GetOverview(validCountryCode);
                Assert.Equal(r.Id, validCountryCode);
                Assert.Equal(r.Name, validCountryName);
                Assert.Equal(r.NameStyle.Value, nameStyle.Name);
                Assert.Equal(r.AddressStyle.Value, addressStyle.Name);
            }

            [Fact]
            public void ReturnsDefaultsForMatchingJurisdiction()
            {
                const string validCountryCode = "ABC";
                const string invalidCountryCode = "XYZ";
                var taxRate = Fixture.String();
                var currencyCode = Fixture.String();
                var validCountryName = Fixture.String(validCountryCode);

                var t = new TaxRate(taxRate) {Description = Fixture.String(), DescriptionTId = Fixture.Integer()}.In(Db);
                var c = new Currency(currencyCode) {Description = Fixture.String(), DescriptionTId = Fixture.Integer()}.In(Db);

                var f = new JurisdictionDetailsFixture(Db);
                var j = Db.Set<Country>();
                j.Add(new Country(invalidCountryCode, Fixture.String(), Fixture.String()));
                j.Add(new Country(validCountryCode, validCountryName, Fixture.String()) {DefaultTaxRate = t, DefaultCurrency = c});

                var r = f.Subject.GetOverview(validCountryCode);
                Assert.Equal(r.Id, validCountryCode);
                Assert.Equal(r.Name, validCountryName);
                Assert.Equal(r.DefaultTaxRate.Description, t.Description);
                Assert.Equal(r.DefaultCurrency.Description, c.Description);

                r = f.Subject.GetOverview(invalidCountryCode);
                Assert.Equal(r.Id, invalidCountryCode);
                Assert.Null(r.DefaultTaxRate);
                Assert.Null(r.DefaultCurrency);
            }

            [Fact]
            public void ReturnsDetailsForMatchingJurisdiction()
            {
                const string validCountryCode = "BB";
                var validCountryName = Fixture.String(validCountryCode);
                var f = new JurisdictionDetailsFixture(Db);

                var j = Db.Set<Country>();
                j.Add(new Country("AX", Fixture.String("AX"), Fixture.String()));
                j.Add(new Country(validCountryCode, validCountryName, Fixture.String()));

                var r = f.Subject.GetOverview(validCountryCode);

                Assert.Equal(r.Id, validCountryCode);
                Assert.Equal(r.Name, validCountryName);
            }

            [Fact]
            public void ThrowsExceptionIfNonExistent()
            {
                const string invalidCountryCode = "ZZ";
                const string validCountryCode = "BB";
                var validCountryName = Fixture.String(validCountryCode);

                var f = new JurisdictionDetailsFixture(Db);
                var j = Db.Set<Country>();
                j.Add(new Country("AX", Fixture.String("AX"), Fixture.String()));
                j.Add(new Country(validCountryCode, validCountryName, Fixture.String()));

                Assert.Throws<HttpException>(() => { f.Subject.GetOverview(invalidCountryCode); });
            }
        }

        public class GetGroupsMethod : FactBase
        {
            [Fact]
            public void ReturnsGroupsForParentJurisdiction()
            {
                var f = new JurisdictionDetailsFixture(Db);
                var j = Db.Set<Country>();
                var p = CommonQueryParameters.Default;
                var c1 = new Country("AP", Fixture.String("AP"), Fixture.String());
                var c2 = new Country("BW", Fixture.String("BW"), Fixture.String());
                j.Add(c1);
                j.Add(c2);
                Db.Set<CountryGroup>().Add(new CountryGroup(c1, c2));

                var r = f.Subject.GetGroups("BW", p);

                var results = ((IEnumerable<dynamic>) r).ToArray();

                Assert.Single(results);
                Assert.Equal(c1.Name, results[0].Name);
            }
        }

        public class GetMembersMethod : FactBase
        {
            [Fact]
            public void ReturnsAllMembersForParentJurisdiction()
            {
                var f = new JurisdictionDetailsFixture(Db);
                var j = Db.Set<Country>();
                var p = CommonQueryParameters.Default;
                var c1 = new Country("AP", Fixture.String("AP"), Fixture.String());
                var c2 = new Country("BW", Fixture.String("BW"), Fixture.String());
                var c3 = new Country("VC", Fixture.String("VC"), Fixture.String());
                j.Add(c1);
                j.Add(c2);
                j.Add(c3);
                Db.Set<CountryGroup>().Add(new CountryGroup(c1, c2));
                Db.Set<CountryGroup>().Add(new CountryGroup(c1, c3));

                var r = f.Subject.GetMembers("AP", p);

                var results = ((IEnumerable<dynamic>) r).ToArray();

                Assert.Equal(2, results.Length);
                Assert.Equal(c2.Name, results[0].Name);
                Assert.Equal(c3.Name, results[1].Name);
            }

            [Fact]
            public void ReturnsMembersForParentJurisdiction()
            {
                var f = new JurisdictionDetailsFixture(Db);
                var j = Db.Set<Country>();
                var p = CommonQueryParameters.Default;
                var c1 = new Country("AP", Fixture.String("AP"), Fixture.String());
                var c2 = new Country("BW", Fixture.String("BW"), Fixture.String());
                j.Add(c1);
                j.Add(c2);
                Db.Set<CountryGroup>().Add(new CountryGroup(c1, c2));

                var r = f.Subject.GetMembers("AP", p);

                var results = ((IEnumerable<dynamic>) r).ToArray();

                Assert.Single(results);
                Assert.Equal(c2.Name, results[0].Name);
            }

            [Fact]
            public void ReturnsSortedListOfValidPropertiesOnlyForMemberJurisdiction()
            {
                var f = new JurisdictionDetailsFixture(Db);
                var j = Db.Set<Country>();
                var p = CommonQueryParameters.Default;
                var c1 = new Country("AP", Fixture.String("AP"), Fixture.String());
                var c2 = new Country("BW", Fixture.String("BW"), Fixture.String());
                j.Add(c1);
                j.Add(c2);
                var property1Code = "T";
                var property2Code = "P";
                var property1Name = "TradeMark";
                var property2Name = "Patent";
                Db.Set<ValidProperty>().Add(new ValidProperty {CountryId = "AP", PropertyTypeId = property1Code, PropertyName = property1Name, PropertyType = new PropertyType(property1Code, "xxx")});
                Db.Set<ValidProperty>().Add(new ValidProperty {CountryId = "AP", PropertyTypeId = property2Code, PropertyName = property2Name, PropertyType = new PropertyType(property2Code, "yyy")});
                Db.Set<CountryGroup>().Add(new CountryGroup(c1, c2) {PropertyTypes = "T,P,I"});

                var r = f.Subject.GetMembers("AP", p);

                var results = ((IEnumerable<dynamic>) r).ToArray();
                var propertyTypesArray = ((IEnumerable<JurisdictionDetails.ValidPropertyPickList>) results[0].PropertyTypeCollection).ToArray();
                Assert.Single(results);
                Assert.True(results[0].Name == c2.Name);
                Assert.Equal(results[0].PropertyTypes, "T,P,I");
                Assert.Equal(results[0].PropertyTypesName, $"{property2Name}, {property1Name}");
                Assert.True(propertyTypesArray.Length == 2);
                Assert.True(propertyTypesArray[0].Value == property2Name);
                Assert.True(propertyTypesArray[1].Value == property1Name);
            }
        }

        public class GetAttributesMethod : FactBase
        {
            [Fact]
            public void ReturnsCorrectAttributes()
            {
                const string validCountryCode = "BB";
                const string invalidCountryCode = "ZZ";
                var validCountryName = Fixture.String(validCountryCode);
                var j = Db.Set<Country>();
                var country = j.Add(new Country(validCountryCode, validCountryName, Fixture.String()));
                j.Add(new Country(invalidCountryCode, Fixture.String("ZZ"), Fixture.String()));

                var tableType = new TableTypeBuilder(Db) {Id = (short?) TableTypes.CountryAttribute, Name = KnownTableAttributes.Country}.Build().In(Db);
                var tableCode = new TableCodeBuilder {TableType = tableType.Id, Description = "XYZ"}.Build().In(Db);
                TableAttributesBuilder
                    .ForCountry(country)
                    .WithAttribute(TableTypes.CountryAttribute, tableCode.Id)
                    .Build().In(Db);

                var tableCode2 = new TableCodeBuilder {TableType = tableType.Id, Description = "ABC"}.Build().In(Db);
                TableAttributesBuilder
                    .ForCountry(country)
                    .WithAttribute(TableTypes.CountryAttribute, tableCode2.Id)
                    .Build().In(Db);

                var tableType3 = new TableTypeBuilder(Db) {Id = (short?) TableTypes.Language, Name = "Language"}.Build().In(Db);
                var tableCode3 = new TableCodeBuilder {TableType = tableType3.Id, Description = "English"}.Build().In(Db);
                TableAttributesBuilder
                    .ForCountry(country)
                    .WithAttribute(TableTypes.Language, tableCode3.Id)
                    .Build().In(Db);

                var f = new JurisdictionDetailsFixture(Db);
                var r = f.Subject.GetAttributes(validCountryCode, f.CommonQueryParameters);

                var results = ((IEnumerable<dynamic>) r).ToArray();

                Assert.Equal(3, results.Length);
                //SortBy Type and then Value
                Assert.Equal(KnownTableAttributes.Country, results.First().TypeName);
                Assert.Equal("ABC", results.First().Value);
                Assert.Equal("Language", results[2].TypeName);
            }

            [Fact]
            public void ThrowsExceptionIfNonExistent()
            {
                const string invalidCountryCode = "ZZ";
                const string validCountryCode = "BB";
                var validCountryName = Fixture.String(validCountryCode);

                var f = new JurisdictionDetailsFixture(Db);
                var j = Db.Set<Country>();
                j.Add(new Country("AX", Fixture.String("AX"), Fixture.String()));
                j.Add(new Country(validCountryCode, validCountryName, Fixture.String()));

                Assert.Throws<HttpException>(() => { f.Subject.GetOverview(invalidCountryCode); });
            }
        }

        public class GetTextsMethod : FactBase
        {
            [Fact]
            public void ReturnsOnlyCorrectTexts()
            {
                const string invalidCountryCode = "ZZ";
                const string validCountryCode = "BB";
                var validCountryName = Fixture.String(validCountryCode);

                var f = new JurisdictionDetailsFixture(Db);
                var j = Db.Set<Country>();
                j.Add(new Country(invalidCountryCode, Fixture.String(invalidCountryCode), Fixture.String()));
                j.Add(new Country(validCountryCode, validCountryName, Fixture.String()));
                var tableCode = new TableCode(Fixture.Integer(), Fixture.Short(), Fixture.String()).In(Db);
                var property = new PropertyType(Fixture.String(), Fixture.String()).In(Db);
                new CountryText(validCountryCode, tableCode, property).In(Db);
                new CountryText(invalidCountryCode, tableCode, property).In(Db);

                var r = f.Subject.GetTexts(validCountryCode, f.CommonQueryParameters);

                var results = ((IEnumerable<dynamic>) r).ToArray();

                Assert.True(results.All(_ => _.CountryId == validCountryCode && _.TextType.Value == tableCode.Name && _.PropertyType.Value == property.Name));
            }

            [Fact]
            public void ReturnsTextWithNullProperty()
            {
                const string invalidCountryCode = "ZZ";
                const string validCountryCode = "BB";
                var validCountryName = Fixture.String(validCountryCode);

                var f = new JurisdictionDetailsFixture(Db);
                var j = Db.Set<Country>();
                j.Add(new Country(invalidCountryCode, Fixture.String(invalidCountryCode), Fixture.String()));
                j.Add(new Country(validCountryCode, validCountryName, Fixture.String()));
                var tableCode = new TableCode(Fixture.Integer(), Fixture.Short(), Fixture.String()).In(Db);
                var property = new PropertyType(Fixture.String(), Fixture.String()).In(Db);
                new CountryText(validCountryCode, tableCode, property).In(Db);
                new CountryText(validCountryCode, tableCode, null).In(Db);
                new CountryText(invalidCountryCode, tableCode, property).In(Db);

                var r = f.Subject.GetTexts(validCountryCode, f.CommonQueryParameters);

                Assert.NotNull(r);
            }
        }

        public class GetStatusFlagsMethod : FactBase
        {
            [Fact]
            public void ReturnsAllMatchingStatusFlags()
            {
                const string invalidCountryCode = "AA";
                const string validCountryCode = "BB";
                var validCountryName = Fixture.String(validCountryCode);

                var f = new JurisdictionDetailsFixture(Db);
                var j = Db.Set<Country>();
                j.Add(new Country(invalidCountryCode, Fixture.String(invalidCountryCode), Fixture.String()));
                j.Add(new Country(validCountryCode, validCountryName, Fixture.String()));
                new CountryFlag(validCountryCode, 1, Fixture.String(validCountryCode)).In(Db);
                new CountryFlag(validCountryCode, 2, Fixture.String(validCountryCode)).In(Db);
                new CountryFlag(validCountryCode, 4, Fixture.String(validCountryCode)).In(Db);
                new CountryFlag(invalidCountryCode, Fixture.Integer(), Fixture.String(invalidCountryCode)).In(Db);
                new CountryFlag(invalidCountryCode, Fixture.Integer(), Fixture.String(invalidCountryCode)).In(Db);

                var r = f.Subject.GetStatusFlags(validCountryCode, f.CommonQueryParameters);
                var results = ((IEnumerable<dynamic>) r).ToArray();

                Assert.True(results.All(_ => _.CountryId == validCountryCode));
                Assert.Equal(3, results.Length);
                Assert.True(results.First().Id == 1 && results.Last().Id == 4);
            }
        }

        public class GetHolidaysMethod : FactBase
        {
            CountryHoliday PrepareDate(string s, string countryCode)
            {
                var j = Db.Set<Country>();
                j.Add(new Country(s, Fixture.String(s), Fixture.String()));
                j.Add(new Country(countryCode, Fixture.String(countryCode), Fixture.String()));
                var countryHoliday = new CountryHoliday(countryCode, Fixture.FutureDate()).In(Db);
                new CountryHoliday(countryCode, Fixture.FutureDate()).In(Db);
                new CountryHoliday(s, Fixture.FutureDate()).In(Db);
                return countryHoliday;
            }

            [Fact]
            public void ReturnsAllHolidaysForACountry()
            {
                const string countryCode = "BB";
                const string invalidCountryCode = "CC";

                var f = new JurisdictionDetailsFixture(Db);
                PrepareDate(invalidCountryCode, countryCode);

                var r = f.Subject.GetHolidays(countryCode);
                var results = ((IEnumerable<dynamic>) r).ToArray();

                Assert.Equal(2, results.Length);
            }

            [Fact]
            public void ReturnsAllHolidaysForACountryWithOutQueryParameter()
            {

                const string countryCode = "BB";
                const string invalidCountryCode = "CC";

                var f = new JurisdictionDetailsFixture(Db);
                PrepareDate(invalidCountryCode, countryCode);

                var r = f.Subject.GetHolidays(countryCode);
                var results = ((IEnumerable<dynamic>) r).ToArray();

                Assert.Equal(2, results.Length);
            }

            [Fact]
            public void ReturnsHolidayById()
            {
                const string countryCode = "BB";
                const string invalidCountryCode = "CC";

                var f = new JurisdictionDetailsFixture(Db);
                var countryHoliday = PrepareDate(invalidCountryCode, countryCode);
                var r = f.Subject.GetHolidayById(countryCode, countryHoliday.Id);
              
                Assert.NotNull(r);
                Assert.Equal(r.CountryId, countryHoliday.CountryId);
                Assert.Equal(r.Id, countryHoliday.Id);
                Assert.Equal(r.HolidayDate,countryHoliday.HolidayDate);
            }

        }

        public class GetStatesMethod : FactBase
        {
            const string ValidCountryCode = "AU";
            const string InvalidCountryCode = "PCT";

            [Theory]
            [InlineData(ValidCountryCode, 1, 8, 1)]
            [InlineData(ValidCountryCode, 8, 1, 8)]
            [InlineData(InvalidCountryCode, 8, 0, 0)]
            public void ReturnsStatesForACountry(string countryToSearch, int forValid, int forInvalid, int expected)
            {
                var f = new JurisdictionDetailsFixture(Db);
                var j = Db.Set<Country>();
                var validCountry = j.Add(new Country(ValidCountryCode, Fixture.String(ValidCountryCode), Fixture.String()));
                var invalidCountry = j.Add(new Country(InvalidCountryCode, Fixture.String(InvalidCountryCode), Fixture.String()));

                for (var i = 0; i < forValid; i++)
                    new State(Fixture.String(i.ToString()), Fixture.String(), validCountry).In(Db);

                for (var i = 0; i < forInvalid; i++)
                    new State(Fixture.String(i.ToString()), Fixture.String(), invalidCountry).In(Db);

                var r = f.Subject.GetStates(countryToSearch, f.CommonQueryParameters);
                var results = ((IEnumerable<dynamic>) r).ToArray();
                Assert.Equal(results.Length, expected);
                Assert.Equal(results.Count(_ => _.CountryCode == countryToSearch), expected);
            }
        }

        public class GetValidNumbersMethod : FactBase
        {
            [Fact]
            public void ReturnsValidNumberPatternsForACountry()
            {
                const string countryCode = "BB";
                const string invalidCountryCode = "CC";

                var f = new JurisdictionDetailsFixture(Db);
                new Country(invalidCountryCode, Fixture.String(invalidCountryCode), Fixture.String()).In(Db);
                new Country(countryCode, Fixture.String(countryCode), Fixture.String()).In(Db);
                var property = new PropertyType(Fixture.String(), Fixture.String());
                var numberType = new NumberType(Fixture.String(), Fixture.String(), null);
                new CountryValidNumber(1, property.Code, numberType.NumberTypeCode, countryCode, Fixture.String(), Fixture.String()) {Property = property, NumberType = numberType}.In(Db);
                new CountryValidNumber(2, property.Code, numberType.NumberTypeCode, countryCode, Fixture.String(), Fixture.String()) {Property = property, NumberType = numberType}.In(Db);
                new CountryValidNumber(3, property.Code, numberType.NumberTypeCode, invalidCountryCode, Fixture.String(), Fixture.String()).In(Db);

                var r = f.Subject.GetValidNumbers(countryCode, f.CommonQueryParameters);
                var results = ((IEnumerable<dynamic>) r).ToArray();

                Assert.Equal(2, results.Length);
            }
        }

        public class GetClassesMethod : FactBase
        {
            const string Country = "BB";
            const string CountryWithInternationalClass = "VQ";
            const string NonClassCountry = "GG";
            const string DefaultClassA = "V1";
            const string DefaultClassB = "V2";
            const string ClassWithInternationalClasses = "V3";

            void PopulateClasses()
            {
                var trademarkProperty = new PropertyType("T","Trademark");
                var designProperty = new PropertyType("D", "Design");
                var propertyWithAllowSubClass = new PropertyType(Fixture.String(), Fixture.String()){AllowSubClass = 2};

                var defaultClassA = new TmClass(KnownValues.DefaultCountryCode, DefaultClassA, trademarkProperty.Code) {Property = trademarkProperty }.In(Db);
                new TmClass(KnownValues.DefaultCountryCode, DefaultClassA, designProperty.Code) {Property = designProperty}.In(Db);
                new TmClass(KnownValues.DefaultCountryCode, DefaultClassA, designProperty.Code) { Property = designProperty,SubClass = "SC01"}.In(Db);
                new TmClass(KnownValues.DefaultCountryCode, DefaultClassA, designProperty.Code) { Property = designProperty, SubClass = "SC02" }.In(Db);
                var defaultClassB = new TmClass(KnownValues.DefaultCountryCode, DefaultClassB, trademarkProperty.Code) {Property = trademarkProperty}.In(Db);

                new TmClass(KnownValues.DefaultCountryCode, Fixture.String(KnownValues.DefaultCountryCode), trademarkProperty.Code) {Property = trademarkProperty}.In(Db);
                new TmClass(KnownValues.DefaultCountryCode, Fixture.String(KnownValues.DefaultCountryCode), trademarkProperty.Code) {Property = trademarkProperty}.In(Db);
                var classWithAllowSubClass = new TmClass(CountryWithInternationalClass, Fixture.String(CountryWithInternationalClass), propertyWithAllowSubClass.Code) { Property = propertyWithAllowSubClass }.In(Db);

                new Country(Country, Fixture.String(Country), Fixture.String()).In(Db);
                new TmClass(Country, Fixture.String(Country), trademarkProperty.Code) {Property = trademarkProperty}.In(Db);
               
                new Country(CountryWithInternationalClass, Fixture.String(CountryWithInternationalClass), Fixture.String()).In(Db);
                new TmClass(CountryWithInternationalClass, ClassWithInternationalClasses, trademarkProperty.Code) {Property = trademarkProperty, IntClass = defaultClassA.Class + "," + defaultClassB.Class}.In(Db);
                new TmClass(CountryWithInternationalClass, Fixture.String(CountryWithInternationalClass), trademarkProperty.Code) {Property = trademarkProperty}.In(Db);
                new ClassItem("I01", "Description 1", null, classWithAllowSubClass.Id) {Class = classWithAllowSubClass }.In(Db);
                new Country(NonClassCountry, Fixture.String(NonClassCountry), Fixture.String()).In(Db);
            }

            [Fact]
            public void ReturnClassesForACountry()
            {
                PopulateClasses();

                var f = new JurisdictionDetailsFixture(Db);
                var r = f.Subject.GetClasses(Country, f.CommonQueryParameters);
                var results = ((IEnumerable<dynamic>) r).ToArray();

                Assert.Single(results);
            }

            [Fact]
            public void ReturnInternationClassesForACountry()
            {
                PopulateClasses();

                var f = new JurisdictionDetailsFixture(Db);
                var r = f.Subject.GetClasses(CountryWithInternationalClass, f.CommonQueryParameters);
                var results = ((IEnumerable<dynamic>) r).ToArray();

                var theClass = results.Single(v => v.Class == ClassWithInternationalClasses);
                var intClasses = ((IEnumerable<dynamic>) theClass.InternationalClasses).ToArray();

                Assert.Equal(2, intClasses.Length);
            }

            [Fact]
            public void ReturnZeroItemCountWhenItemsAreNotConfigured()
            {
                PopulateClasses();

                var f = new JurisdictionDetailsFixture(Db);
                var r = f.Subject.GetClasses(Country, f.CommonQueryParameters);
                var results = ((IEnumerable<dynamic>)r).ToArray();

                Assert.Equal(0, results[0].ItemsCount);
            }

            [Fact]
            public void ReturnItemCountWhenItemsAreConfigured()
            {
                PopulateClasses();

                var f = new JurisdictionDetailsFixture(Db);
                var r = f.Subject.GetClasses(CountryWithInternationalClass, f.CommonQueryParameters);
                var results = ((IEnumerable<dynamic>)r).Where(_ => _.AllowSubClass == 2).ToArray();

                Assert.Equal(1, results[0].ItemsCount);
            }

            [Fact]
            public void ReturnsDefaultClassesForDefaultCountry()
            {
                PopulateClasses();

                var f = new JurisdictionDetailsFixture(Db);
                var r = f.Subject.GetClasses(KnownValues.DefaultCountryCode, f.CommonQueryParameters);
                var results = ((IEnumerable<dynamic>) r).ToArray();

                Assert.Equal(7, results.Length);
            }

            [Fact]
            public void ReturnsClassesWithDefaultSorting()
            {
                PopulateClasses();

                var f = new JurisdictionDetailsFixture(Db);
                var r = f.Subject.GetClasses(KnownValues.DefaultCountryCode, f.CommonQueryParameters);
                var results = ((IEnumerable<dynamic>)r).ToArray();

                Assert.Equal(7, results.Length);

                Assert.Equal("V1", results[0].Class);
                Assert.Equal("Design", results[0].PropertyType);
                Assert.Null(results[0].SubClass);

                Assert.Equal("V1", results[1].Class);
                Assert.Equal("Design", results[1].PropertyType);
                Assert.Equal("SC01",results[1].SubClass);

                Assert.Equal("V1", results[2].Class);
                Assert.Equal("Design", results[2].PropertyType);
                Assert.Equal("SC02", results[2].SubClass);

                Assert.Equal("V1", results[3].Class);
                Assert.Equal("Trademark", results[3].PropertyType);
                Assert.Null(results[0].SubClass);
           }

            [Fact]
            public void ReturnsClassesWithColumnSorting()
            {
                PopulateClasses();

                var f = new JurisdictionDetailsFixture(Db);
                f.CommonQueryParameters.SortBy = "SubClass";
                f.CommonQueryParameters.SortDir = "desc";
                var r = f.Subject.GetClasses(KnownValues.DefaultCountryCode, f.CommonQueryParameters);
                var results = ((IEnumerable<dynamic>)r).ToArray();

                Assert.Equal(7, results.Length);

                Assert.Equal("V1", results[0].Class);
                Assert.Equal("Design", results[0].PropertyType);
                Assert.Equal("SC02", results[0].SubClass);

                Assert.Equal("V1", results[1].Class);
                Assert.Equal("Design", results[1].PropertyType);
                Assert.Equal("SC01", results[1].SubClass);

                Assert.Equal("V1", results[2].Class);
                Assert.Equal("Trademark", results[2].PropertyType);
                Assert.Null(results[2].SubClass);
            }
        }

        public class GetValidCombinationsMethod : FactBase
        {
            [Theory]
            [InlineData(true, true)]
            [InlineData(false, false)]
            public void ReturnsIfThereAreValidCombinations(bool withValids, bool expected)
            {
                var matches = withValids
                    ? new List<JurisdictionSearch>
                    {
                        new JurisdictionSearch
                        {
                            CountryCode = Fixture.String()
                        }
                    }
                    : new List<JurisdictionSearch>();
                var f = new JurisdictionDetailsFixture(Db);
                f.ValidJurisdictionDetails.SearchValidJurisdiction(Arg.Any<ValidCombinationSearchCriteria>()).Returns(matches.AsQueryable());
                var r = f.Subject.GetValidCombinations(Fixture.String());
                Assert.Equal(expected, r.HasCombinations);
            }

            [Theory]
            [InlineData(true, true)]
            [InlineData(false, false)]
            public void ReturnsIfUserCanAccessValidCombinations(bool hasAccess, bool expected)
            {
                var matches = new List<JurisdictionSearch>
                {
                    new JurisdictionSearch
                    {
                        CountryCode = Fixture.String()
                    }
                }.AsQueryable();
                var f = new JurisdictionDetailsFixture(Db);
                f.ValidJurisdictionDetails.SearchValidJurisdiction(Arg.Any<ValidCombinationSearchCriteria>()).Returns(matches);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainValidCombinations, ApplicationTaskAccessLevel.Execute).Returns(hasAccess);
                var r = f.Subject.GetValidCombinations(Fixture.String());
                Assert.Equal(expected, r.CanAccessValidCombinations);
            }
        }
    }
}