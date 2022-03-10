using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web.Configuration.ValidCombinations;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.ValidCombinations
{
    public class ValidCategoryControllerFacts
    {
        public class ValidCategoryControllerFixture : IFixture<ValidCategoryController>
        {
            readonly InMemoryDbContext _db;

            public ValidCategoryControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                ValidCategories = Substitute.For<IValidCategories>();

                Exporter = Substitute.For<ISimpleExcelExporter>();

                Subject = new ValidCategoryController(_db, ValidCategories, Exporter);
            }

            public IValidCategories ValidCategories { get; }
            public ISimpleExcelExporter Exporter { get; }

            public ValidCategoryController Subject { get; }

            public dynamic SetupCategories()
            {
                var validCategory1 = new ValidCategoryBuilder
                {
                    Country = new CountryBuilder {Id = "NZ", Name = "New Zealand"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "ND", Name = "Domain Name"}.Build(),
                    CaseType = new CaseTypeBuilder {Id = "R", Name = "Properties"}.Build(),
                    CaseCategory = new CaseCategoryBuilder {CaseTypeId = "R", Name = "Normal", CaseCategoryId = "R"}.Build()
                }.Build().In(_db);

                new ValidProperty {CountryId = "NZ", PropertyTypeId = "T", PropertyName = "Valid Property"}.In(_db);

                var validCategory2 = new ValidCategoryBuilder
                {
                    Country = new CountryBuilder {Id = "GB", Name = "United Kingdom"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "P", Name = "Patent"}.Build(),
                    CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build(),
                    CaseCategory = new CaseCategoryBuilder {CaseTypeId = "P", Name = ".COM", CaseCategoryId = "P"}.Build()
                }.Build().In(_db);

                var validCategory3 = new ValidCategoryBuilder
                {
                    Country = new CountryBuilder {Id = "US", Name = "United States of America"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "D", Name = "Design"}.Build(),
                    CaseType = new CaseTypeBuilder {Id = "Q", Name = "Properties"}.Build(),
                    CaseCategory = new CaseCategoryBuilder {CaseTypeId = "Q", Name = ".NET", CaseCategoryId = "Q"}.Build()
                }.Build().In(_db);
                validCategory3.PropertyEventNo = new EventBuilder().Build().In(_db).Id;

                var validCategory4 = new ValidCategoryBuilder
                {
                    Country = new CountryBuilder {Id = "US", Name = "United States of America"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "ND", Name = "Domain Name"}.Build(),
                    CaseType = new CaseTypeBuilder {Id = "R", Name = "Properties"}.Build(),
                    CaseCategory = new CaseCategoryBuilder {CaseTypeId = "R", Name = "Normal", CaseCategoryId = "R"}.Build()
                }.Build().In(_db);

                var validCategory5 = new ValidCategoryBuilder
                {
                    Country = new CountryBuilder {Id = "IN", Name = "India"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "U", Name = "Utility"}.Build(),
                    CaseType = new CaseTypeBuilder {Id = "I", Name = "Internal"}.Build(),
                    CaseCategory = new CaseCategoryBuilder {CaseTypeId = "P", Name = "Normal", CaseCategoryId = "P"}.Build()
                }.Build().In(_db);

                return new
                {
                    validCategory1,
                    validCategory2,
                    validCategory3,
                    validCategory4,
                    validCategory5
                };
            }
        }

        public class GetPagedResultsMethod : FactBase
        {
            [Fact]
            public void OrdersByDescription()
            {
                var f = new ValidCategoryControllerFixture(Db);
                f.SetupCategories();

                var result = f.Subject.GetPagedResults(Db.Set<ValidCategory>(),
                                                       new CommonQueryParameters {SortBy = "CaseCategory", SortDir = "asc", Skip = 0, Take = 10});

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();
                Assert.Equal(5, results.Length);
                Assert.Equal(Db.Set<ValidCategory>().OrderBy(c => c.CaseCategory.Name).First().CaseCategory.Name, results[0].CaseCategory);
            }

            [Fact]
            public void SkipsAndTakes()
            {
                var f = new ValidCategoryControllerFixture(Db);
                for (var i = 0; i < 10; i++)
                {
                    new ValidCategoryBuilder
                        {
                            Country = new CountryBuilder {Id = "GB", Name = "United Kingdom"}.Build(),
                            PropertyType = new PropertyTypeBuilder {Id = "P", Name = "Patent"}.Build(),
                            CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build(),
                            CaseCategory = new CaseCategoryBuilder {CaseTypeId = "P", Name = Fixture.String("Name" + i), CaseCategoryId = "P"}.Build()
                        }.Build()
                         .In(Db);
                }

                var result = f.Subject.GetPagedResults(Db.Set<ValidCategory>(),
                                                       new CommonQueryParameters {SortBy = "CaseCategory", SortDir = "asc", Skip = 3, Take = 7});
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();
                var data = Db.Set<ValidCategory>().OrderBy(c => c.CaseCategoryId).Skip(3).Take(7).First();
                Assert.Equal(data.CaseCategory.Name, results[0].CaseCategory);
            }
        }

        public class SearchValidCategory : FactBase
        {
            [Fact]
            public void SearchAllCategories()
            {
                var f = new ValidCategoryControllerFixture(Db);
                f.SetupCategories();
                var searchCriteria = new ValidCombinationSearchCriteria();

                var result = f.Subject.SearchValidProperty(searchCriteria);
                Assert.Equal(5, result.Count());
            }

            [Fact]
            public void SearchBasedOnAllFilter()
            {
                var f = new ValidCategoryControllerFixture(Db);
                f.SetupCategories();
                var searchCriteria = new ValidCombinationSearchCriteria
                {
                    PropertyType = "D",
                    CaseType = "Q",
                    CaseCategory = "Q",
                    Jurisdictions = new List<string> {"US"}
                };

                var result = f.Subject.SearchValidProperty(searchCriteria);

                var filteredData =
                    Db.Set<ValidCategory>()
                      .Where(c => c.PropertyType.Code == "D" && c.CaseType.Code == "Q" && c.Country.Id == "US" && c.CaseCategoryId == "Q");

                Assert.Equal(filteredData.Count(), result.Count());
                Assert.Contains(filteredData.FirstOrDefault(), result);
            }

            [Fact]
            public void SearchBasedOnCaseType()
            {
                var f = new ValidCategoryControllerFixture(Db);
                f.SetupCategories();
                var searchCriteria = new ValidCombinationSearchCriteria {CaseType = "I"};

                var result = f.Subject.SearchValidProperty(searchCriteria);
                var filteredData = Db.Set<ValidCategory>().Where(c => c.CaseTypeId == "I");
                Assert.Equal(filteredData.Count(), result.Count());
                Assert.Contains(filteredData.FirstOrDefault(), result);
            }

            [Fact]
            public void SearchBasedOnCategory()
            {
                var f = new ValidCategoryControllerFixture(Db);
                f.SetupCategories();
                var searchCriteria = new ValidCombinationSearchCriteria {CaseCategory = "P"};

                var result = f.Subject.SearchValidProperty(searchCriteria);
                var data = Db.Set<ValidCategory>().Where(c => c.CaseCategoryId == "P");
                Assert.Equal(data.Count(), result.Count());
                Assert.Contains(data.FirstOrDefault(), result);
            }

            [Fact]
            public void SearchBasedOnMultipleCountries()
            {
                var f = new ValidCategoryControllerFixture(Db);
                f.SetupCategories();
                var searchCriteria = new ValidCombinationSearchCriteria {Jurisdictions = new List<string> {"GB", "US"}};

                var result = f.Subject.SearchValidProperty(searchCriteria);
                var filteredCategories = Db.Set<ValidCategory>().Where(c => c.Country.Id == "GB" || c.Country.Id == "US");

                Assert.Equal(filteredCategories.Count(), result.Count());

                foreach (var item in filteredCategories) Assert.Contains(item, result);
            }

            [Fact]
            public void SearchBasedOnProperty()
            {
                var f = new ValidCategoryControllerFixture(Db);
                f.SetupCategories();
                var searchCriteria = new ValidCombinationSearchCriteria {PropertyType = "P"};

                var result = f.Subject.SearchValidProperty(searchCriteria);
                var data = Db.Set<ValidCategory>().Where(c => c.PropertyTypeId == "P");
                Assert.Equal(data.Count(), result.Count());
                Assert.Contains(data.FirstOrDefault(), result);
            }
        }

        public class SearchMethod : FactBase
        {
            [Fact]
            public void ShouldReturnSearchInCorrectOrder()
            {
                var filter = new ValidCombinationSearchCriteria();
                var f = new ValidCategoryControllerFixture(Db);
                f.SetupCategories();

                var result = f.Subject.Search(filter);
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();
                Assert.Equal(5, results.Length);
                Assert.Equal(Db.Set<ValidCategory>().OrderBy(c => c.Country.Name).First().Country.Name, results[0].Country);
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void ThrowsExceptionWhenValidCategoryNotFoundForGivenValues()
            {
                var f = new ValidCategoryControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.ValidCaseCategory(
                                                                       new ValidCategoryIdentifier("XXX", "YYY", "ZZZ", "AA")));

                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void CallsValidPropertyTypeSave()
            {
                var f = new ValidCategoryControllerFixture(Db);

                var model = new CaseCategorySaveDetails();
                var result = new object();

                f.ValidCategories.Save(model).Returns(result);

                f.Subject.Save(model);

                f.ValidCategories.ReceivedWithAnyArgs().Save(model);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void CallsValidPropertyTypeUpdate()
            {
                var f = new ValidCategoryControllerFixture(Db);

                var model = new CaseCategorySaveDetails();

                var returnValue = new object();
                f.ValidCategories.Update(model).Returns(returnValue);

                f.Subject.Update(model);

                f.ValidCategories.ReceivedWithAnyArgs().Update(model);
            }

            [Fact]
            public void ThrowsExceptionWhenResponseIsNullForDelete()
            {
                var f = new ValidCategoryControllerFixture(Db);

                var model = new CaseCategorySaveDetails();
                f.ValidCategories.Update(Arg.Any<CaseCategorySaveDetails>()).Returns(null as object);

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
                var f = new ValidCategoryControllerFixture(Db);

                var model = new ValidCategoryIdentifier[] { };

                var returnValue = new DeleteResponseModel<ValidCategoryIdentifier>();
                f.ValidCategories.Delete(Arg.Any<ValidCategoryIdentifier[]>()).Returns(returnValue);

                f.Subject.Delete(model);

                f.ValidCategories.ReceivedWithAnyArgs().Delete(Arg.Any<ValidCategoryIdentifier[]>());
            }

            [Fact]
            public void ThrowsExceptionWhenResponseIsNullForDelete()
            {
                var f = new ValidCategoryControllerFixture(Db);

                var model = new ValidCategoryIdentifier[] { };

                f.ValidCategories.Delete(Arg.Any<ValidCategoryIdentifier[]>()).Returns(null as DeleteResponseModel<ValidCategoryIdentifier>);

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
                var f = new ValidCategoryControllerFixture(Db);
                f.SetupCategories();

                var toCountries = new[] {new CountryModel {Code = "AUT"}, new CountryModel {Code = "IT"}};

                f.Subject.Copy(new CountryModel {Code = "US"}, toCountries);

                var validCategoriesForAmerica = Db.Set<ValidCategory>()
                                                  .Where(_ => _.CountryId == "US");

                foreach (var vc in validCategoriesForAmerica)
                {
                    var validCategory = vc;

                    Assert.NotNull(
                                   Db.Set<ValidCategory>()
                                     .Where(_ => _.CountryId == "AUT" && _.PropertyTypeId == validCategory.PropertyTypeId
                                                                      && _.CaseTypeId == validCategory.CaseTypeId && _.CaseCategoryId == validCategory.CaseCategoryId && _.PropertyEventNo == validCategory.PropertyEventNo));
                    Assert.NotNull(
                                   Db.Set<ValidCategory>()
                                     .Where(_ => _.CountryId == "IT" && _.PropertyTypeId == validCategory.PropertyTypeId
                                                                     && _.CaseTypeId == validCategory.CaseTypeId && _.CaseCategoryId == validCategory.CaseCategoryId && _.PropertyEventNo == validCategory.PropertyEventNo));
                }
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenFromCountryNotPassed()
            {
                var f = new ValidCategoryControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Copy(null, new[] {new CountryModel {Code = "GB"}}));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("fromJurisdiction", exception.Message);
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenToCountriesNotPassed()
            {
                var f = new ValidCategoryControllerFixture(Db);

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
                var fixture = new ValidCategoryControllerFixture(Db);
                fixture.SetupCategories();

                fixture
                    .Subject
                    .ExportToExcel(new ValidCombinationSearchCriteria());

                var totalInDb = Db.Set<ValidCategory>().Count();

                fixture.Exporter.Received(1).Export(Arg.Is<PagedResults>(x => x.Data.Count() == totalInDb), "Search Result.xlsx");
            }
        }
    }
}