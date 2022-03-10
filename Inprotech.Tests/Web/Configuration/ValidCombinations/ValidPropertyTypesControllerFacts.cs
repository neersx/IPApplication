using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web.Configuration.ValidCombinations;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.ValidCombinations
{
    public class ValidPropertyTypesControllerFacts
    {
        public class ValidPropertyTypesControllerFixture : IFixture<ValidPropertyTypesController>
        {
            readonly InMemoryDbContext _db;

            public ValidPropertyTypesControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                ValidPropertyTypes = Substitute.For<IValidPropertyTypes>();
                Exporter = Substitute.For<ISimpleExcelExporter>();

                Subject = new ValidPropertyTypesController(_db, Exporter, ValidPropertyTypes);
            }

            public IValidPropertyTypes ValidPropertyTypes { get; }
            public ISimpleExcelExporter Exporter { get; }
            public ValidPropertyTypesController Subject { get; }

            public dynamic SetUpPropertyTypes()
            {
                var validProperty1 =
                    new ValidPropertyBuilder {PropertyTypeId = "T", CountryCode = "NZ", CountryName = "New Zealand"}.Build()
                                                                                                                    .In(_db);
                var validProperty2 =
                    new ValidPropertyBuilder {PropertyTypeId = "P", CountryCode = "GB", CountryName = "United Kingdom"}.Build()
                                                                                                                       .In(_db);
                var validProperty3 =
                    new ValidPropertyBuilder {PropertyTypeId = "D", CountryCode = "EH", CountryName = "West Sahara"}.Build()
                                                                                                                    .In(_db);
                var validProperty4 =
                    new ValidPropertyBuilder {PropertyTypeId = "P", CountryCode = "US", CountryName = "United States Of America"}.Build()
                                                                                                                                 .In(_db);

                var validProperty5 =
                    new ValidPropertyBuilder {PropertyTypeId = "T", CountryCode = "US", CountryName = "United States Of America"}.Build()
                                                                                                                                 .In(_db);

                return new
                {
                    validProperty1,
                    validProperty2,
                    validProperty3,
                    validProperty4,
                    validProperty5
                };
            }
        }

        public class GetPagedResultsMethod : FactBase
        {
            [Fact]
            public void OrdersByDescription()
            {
                var f = new ValidPropertyTypesControllerFixture(Db);
                f.SetUpPropertyTypes();

                var result = f.Subject.GetPagedResults(Db.Set<ValidProperty>(),
                                                       new CommonQueryParameters {SortBy = "Country", SortDir = "asc", Skip = 0, Take = 10});

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(5, results.Length);
                Assert.Equal(Db.Set<ValidProperty>().OrderBy(c => c.Country.Name).First().PropertyType.Name, results[0].PropertyType);
            }

            [Fact]
            public void SkipsAndTakes()
            {
                var f = new ValidPropertyTypesControllerFixture(Db);
                for (var i = 0; i < 10; i++) new ValidPropertyBuilder {PropertyTypeId = i.ToString(CultureInfo.InvariantCulture), PropertyTypeName = Fixture.String("Name" + i)}.Build().In(Db);

                var result = f.Subject.GetPagedResults(Db.Set<ValidProperty>(),
                                                       new CommonQueryParameters {SortBy = "PropertyType", SortDir = "asc", Skip = 2, Take = 7});
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(7, results.Length);
                Assert.Equal(Db.Set<ValidProperty>().First(_ => _.PropertyTypeId == "2").PropertyType.Name, results[0].PropertyType);
            }
        }

        public class SearchValidProperty : FactBase
        {
            [Fact]
            public void SearchBasedOnAllCountries()
            {
                var f = new ValidPropertyTypesControllerFixture(Db);
                f.SetUpPropertyTypes();
                var searchCriteria = new ValidCombinationSearchCriteria();

                var result = f.Subject.SearchValidProperty(searchCriteria);
                Assert.Equal(5, result.Count());
            }

            [Fact]
            public void SearchBasedOnMultipleCountries()
            {
                var f = new ValidPropertyTypesControllerFixture(Db);
                var data = f.SetUpPropertyTypes();
                var searchCriteria = new ValidCombinationSearchCriteria {Jurisdictions = new List<string> {"GB", "US"}};

                var result = f.Subject.SearchValidProperty(searchCriteria);
                Assert.Equal(3, result.Count());
                Assert.Contains(data.validProperty2, result);
                Assert.Contains(data.validProperty4, result);
                Assert.Contains(data.validProperty5, result);
            }

            [Fact]
            public void SearchBasedOnPropertyType()
            {
                var f = new ValidPropertyTypesControllerFixture(Db);
                var data = f.SetUpPropertyTypes();
                var searchCriteria = new ValidCombinationSearchCriteria {PropertyType = "P"};

                var result = f.Subject.SearchValidProperty(searchCriteria);
                Assert.Equal(2, result.Count());
                Assert.Contains(data.validProperty2, result);
                Assert.Contains(data.validProperty4, result);
            }

            [Fact]
            public void SearchBasedOnPropertyTypeAndCountry()
            {
                var f = new ValidPropertyTypesControllerFixture(Db);
                var data = f.SetUpPropertyTypes();
                var searchCriteria = new ValidCombinationSearchCriteria
                {
                    PropertyType = "P",
                    Jurisdictions = new List<string> {"US"}
                };

                var result = f.Subject.SearchValidProperty(searchCriteria);
                Assert.Equal(1, result.Count());
                Assert.Contains(data.validProperty4, result);
            }
        }

        public class SearchMethod : FactBase
        {
            [Fact]
            public void ShouldReturnSearchInCorrectOrder()
            {
                var filter = new ValidCombinationSearchCriteria();
                var f = new ValidPropertyTypesControllerFixture(Db);
                f.SetUpPropertyTypes();

                var result = f.Subject.Search(filter);
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();
                Assert.Equal(5, results.Length);
                Assert.Equal(Db.Set<ValidProperty>().OrderBy(c => c.Country.Name).First().PropertyType.Name, results[0].PropertyType);
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void ThrowsExceptionWhenValidPropertyNotFoundForGivenCountryAndPropertyCode()
            {
                var f = new ValidPropertyTypesControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.ValidPropertyType(
                                                                       new ValidPropertyIdentifier("XXX", "YYY")));

                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void CallsValidPropertyTypeSave()
            {
                var f = new ValidPropertyTypesControllerFixture(Db);

                var model = new PropertyTypeSaveDetails();
                var result = new object();

                f.ValidPropertyTypes.Save(model).Returns(result);

                f.Subject.Save(model);

                f.ValidPropertyTypes.ReceivedWithAnyArgs().Save(model);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void CallsValidPropertyTypeUpdate()
            {
                var f = new ValidPropertyTypesControllerFixture(Db);

                var model = new PropertyTypeSaveDetails();

                var returnValue = new object();
                f.ValidPropertyTypes.Update(model).Returns(returnValue);

                f.Subject.Update(model);

                f.ValidPropertyTypes.ReceivedWithAnyArgs().Update(model);
            }

            [Fact]
            public void ThrowsExceptionWhenResponseIsNullForDelete()
            {
                var f = new ValidPropertyTypesControllerFixture(Db);

                var model = new PropertyTypeSaveDetails();
                f.ValidPropertyTypes.Update(Arg.Any<PropertyTypeSaveDetails>()).Returns(null as object);

                var exception =
                    Record.Exception(() => f.Subject.Update(model));

                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void CallsPropertyTypesDelete()
            {
                var f = new ValidPropertyTypesControllerFixture(Db);

                var model = new ValidPropertyIdentifier[] { };

                var returnValue = new DeleteResponseModel<ValidPropertyIdentifier>();
                f.ValidPropertyTypes.Delete(Arg.Any<ValidPropertyIdentifier[]>()).Returns(returnValue);

                f.Subject.Delete(model);

                f.ValidPropertyTypes.ReceivedWithAnyArgs().Delete(Arg.Any<ValidPropertyIdentifier[]>());
            }

            [Fact]
            public void ThrowsExceptionWhenResponseIsNullForDelete()
            {
                var f = new ValidPropertyTypesControllerFixture(Db);

                var model = new ValidPropertyIdentifier[] { };

                f.ValidPropertyTypes.Delete(Arg.Any<ValidPropertyIdentifier[]>()).Returns(null as DeleteResponseModel<ValidPropertyIdentifier>);

                var exception =
                    Record.Exception(() => f.Subject.Delete(model));

                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class CopyMethod : FactBase
        {
            [Fact]
            public void ShouldCopyAllValidCombinationsForAllCountriesSpecified()
            {
                var f = new ValidPropertyTypesControllerFixture(Db);
                f.SetUpPropertyTypes();

                var toCountries = new[] {new CountryModel {Code = "IN"}, new CountryModel {Code = "IT"}};

                f.Subject.Copy(new CountryModel {Code = "US"}, toCountries);

                var validPropertiesForAmerica = Db.Set<ValidProperty>()
                                                  .Where(_ => _.CountryId == "US");

                foreach (var vp in validPropertiesForAmerica)
                {
                    var validProperty = vp;

                    Assert.NotNull(
                                   Db.Set<ValidProperty>()
                                     .Where(_ => _.CountryId == "AUT" && _.PropertyTypeId == validProperty.PropertyTypeId));
                    Assert.NotNull(
                                   Db.Set<ValidProperty>()
                                     .Where(_ => _.CountryId == "IT" && _.PropertyTypeId == validProperty.PropertyTypeId));
                }
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenFromCountryNotPassed()
            {
                var f = new ValidPropertyTypesControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Copy(null, new[] {new CountryModel {Code = "GB"}}));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("fromJurisdiction", exception.Message);
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenToCountriesNotPassed()
            {
                var f = new ValidPropertyTypesControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Copy(new CountryModel {Code = "US"}, new CountryModel[] { }));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("toJurisdictions", exception.Message);
            }
        }

        public class ExportToExcelMethod : FactBase
        {
            [Fact]
            public void ShouldExportSearchResults()
            {
                var fixture = new ValidPropertyTypesControllerFixture(Db);
                fixture.SetUpPropertyTypes();

                fixture
                    .Subject
                    .ExportToExcel(new ValidCombinationSearchCriteria());

                var totalInDb = Db.Set<ValidProperty>().Count();

                fixture.Exporter.Received(1).Export(Arg.Is<PagedResults>(x => x.Data.Count() == totalInDb), "Search Result.xlsx");
            }
        }
    }
}