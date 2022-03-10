using System;
using System.Collections.Generic;
using System.Linq;
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
    public class ValidDateOfLawControllerFacts
    {
        public class ValidDateOfLawControllerFixture : IFixture<ValidDateOfLawController>
        {
            readonly InMemoryDbContext _db;

            public ValidDateOfLawControllerFixture(InMemoryDbContext db)
            {
                _db = db;

                Exporter = Substitute.For<ISimpleExcelExporter>();

                Subject = new ValidDateOfLawController(db, Exporter);
            }

            public ISimpleExcelExporter Exporter { get; }
            public ValidDateOfLawController Subject { get; }

            public dynamic GetDateOfLaws()
            {
                var date1 = DateTime.Now.AddYears(-1);
                var dateofLaw1 = new DateOfLawBuilder {PropertyTypeId = "T", CountryCode = "NZ", Date = date1}.Build().In(_db);
                var dateofLaw2 = new DateOfLawBuilder {PropertyTypeId = "P", CountryCode = "GB", Date = DateTime.Now.AddYears(-2)}.Build().In(_db);
                var dateofLaw3 = new DateOfLawBuilder {PropertyTypeId = "D", CountryCode = "EH", Date = DateTime.Now.AddYears(-3)}.Build().In(_db);
                var dateofLaw4 = new DateOfLawBuilder {PropertyTypeId = "P", CountryCode = "US", Date = DateTime.Now.AddYears(-4)}.Build().In(_db);
                var dateofLaw5 = new DateOfLawBuilder {PropertyTypeId = "T", CountryCode = "US", Date = DateTime.Now.AddYears(-5)}.Build().In(_db);

                return new
                {
                    date1,
                    dateofLaw1,
                    dateofLaw2,
                    dateofLaw3,
                    dateofLaw4,
                    dateofLaw5
                };
            }
        }

        public class GetPagedResultsMethod : FactBase
        {
            [Fact]
            public void OrdersByCountryName()
            {
                var f = new ValidDateOfLawControllerFixture(Db);
                f.GetDateOfLaws();

                var result = f.Subject.GetPagedResults(Db.Set<DateOfLaw>(),
                                                       new CommonQueryParameters {SortBy = "Country", SortDir = "asc", Skip = 0, Take = 10});

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();
                var filteredData = Db.Set<DateOfLaw>().OrderBy(c => c.Country.Name).First();

                Assert.Equal(5, results.Length);
                Assert.Equal(filteredData.Country.Name, results[0].Country);
            }

            [Fact]
            public void SkipsAndTakes()
            {
                var f = new ValidDateOfLawControllerFixture(Db);
                for (var i = 0; i < 10; i++)
                {
                    new DateOfLawBuilder
                    {
                        PropertyTypeId = "T",
                        CountryCode = "US",
                        Date = DateTime.Now.AddYears(-i)
                    }.Build().In(Db);
                }

                var result = f.Subject.GetPagedResults(Db.Set<DateOfLaw>(),
                                                       new CommonQueryParameters {SortBy = "PropertyType", SortDir = "asc", Skip = 2, Take = 7});
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();
                Assert.Equal(7, results.Length);
                Assert.Equal(Db.Set<DateOfLaw>().OrderBy(x => x.PropertyType.Name).Skip(2).Take(7).First().PropertyType.Name, results[0].PropertyType);
            }
        }

        public class SearchValidDateOfLaw : FactBase
        {
            [Fact]
            public void SearchBasedOnAllCountries()
            {
                var f = new ValidDateOfLawControllerFixture(Db);
                f.GetDateOfLaws();
                var searchCriteria = new ValidCombinationSearchCriteria();

                var result = f.Subject.SearchDateOfLaw(searchCriteria);
                Assert.Equal(5, result.Count());
            }

            [Fact]
            public void SearchBasedOnMultipleCountries()
            {
                var f = new ValidDateOfLawControllerFixture(Db);
                var data = f.GetDateOfLaws();
                var searchCriteria = new ValidCombinationSearchCriteria {Jurisdictions = new List<string> {"GB", "US"}};

                var result = f.Subject.SearchDateOfLaw(searchCriteria);
                Assert.Equal(3, result.Count());
                Assert.Contains(data.dateofLaw2, result);
                Assert.Contains(data.dateofLaw4, result);
                Assert.Contains(data.dateofLaw5, result);
            }

            [Fact]
            public void SearchBasedOnPropertyType()
            {
                var f = new ValidDateOfLawControllerFixture(Db);
                var data = f.GetDateOfLaws();
                var searchCriteria = new ValidCombinationSearchCriteria {PropertyType = "P"};

                var result = f.Subject.SearchDateOfLaw(searchCriteria);
                Assert.Equal(2, result.Count());
                Assert.Contains(data.dateofLaw2, result);
                Assert.Contains(data.dateofLaw4, result);
            }

            [Fact]
            public void SearchBasedOnPropertyTypeCountryAndDate()
            {
                var f = new ValidDateOfLawControllerFixture(Db);
                var data = f.GetDateOfLaws();
                var searchCriteria = new ValidCombinationSearchCriteria
                {
                    PropertyType = "T",
                    Jurisdictions = new List<string> {"NZ"},
                    DateOfLaw = data.date1
                };

                var result = f.Subject.SearchDateOfLaw(searchCriteria);
                Assert.Equal(1, result.Count());
                Assert.Contains(data.dateofLaw1, result);
            }
        }

        public class SearchMethod : FactBase
        {
            [Fact]
            public void ShouldReturnSearchInCorrectOrder()
            {
                var filter = new ValidCombinationSearchCriteria();
                var f = new ValidDateOfLawControllerFixture(Db);
                f.GetDateOfLaws();

                var result = f.Subject.Search(filter);
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();
                var filteredData = Db.Set<DateOfLaw>().OrderBy(c => c.Country.Name).First();
                Assert.Equal(5, results.Length);
                Assert.Equal(filteredData.PropertyType.Name, results[0].PropertyType);
            }
        }
    }
}