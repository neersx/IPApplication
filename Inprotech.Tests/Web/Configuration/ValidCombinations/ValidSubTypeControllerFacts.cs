using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web.Configuration.ValidCombinations;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.ValidCombinations
{
    public class ValidSubTypeControllerFacts
    {
        public class ValidSubTypeControllerFixture : IFixture<ValidSubTypeController>
        {
            readonly InMemoryDbContext _db;

            public ValidSubTypeControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                ValidSubTypes = Substitute.For<IValidSubTypes>();

                Exporter = Substitute.For<ISimpleExcelExporter>();

                Subject = new ValidSubTypeController(db, ValidSubTypes, Exporter);
            }

            public IValidSubTypes ValidSubTypes { get; }
            public ISimpleExcelExporter Exporter { get; }
            public ValidSubTypeController Subject { get; }

            public dynamic SetupValidSubTypes()
            {
                var validSubType1 = new ValidSubTypeBuilder
                {
                    Country = new CountryBuilder {Id = "NZ", Name = "New Zealand"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "T", Name = "TradeMark"}.Build(),
                    CaseType = new CaseTypeBuilder {Id = "I", Name = "Properties"}.Build(),
                    SubType = new SubTypeBuilder {Id = "5", Name = "5 yearly renewals"}.Build(),
                    ValidCategory = new ValidCategoryBuilder
                    {
                        Country = new CountryBuilder {Id = "NZ", Name = "New Zealand"}.Build(),
                        PropertyType = new PropertyTypeBuilder {Id = "T", Name = "TradeMark"}.Build(),
                        CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build(),
                        CaseCategory = new CaseCategoryBuilder {CaseTypeId = "P", Name = ".COM", CaseCategoryId = "P"}.Build()
                    }.Build().In(_db),
                    SubTypeDescription = "5 yearly renewals"
                }.Build().In(_db);

                var validSubType2 = new ValidSubTypeBuilder
                {
                    Country = new CountryBuilder {Id = "GB", Name = "United Kingdom"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "D", Name = "Design"}.Build(),
                    CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build(),
                    SubType = new SubTypeBuilder {Id = "D", Name = "Defensive Mark"}.Build(),
                    ValidCategory = new ValidCategoryBuilder
                    {
                        Country = new CountryBuilder {Id = "GB", Name = "United Kingdom"}.Build(),
                        PropertyType = new PropertyTypeBuilder {Id = "D", Name = "Design"}.Build(),
                        CaseType = new CaseTypeBuilder {Id = "Q", Name = "Properties"}.Build(),
                        CaseCategory = new CaseCategoryBuilder {CaseTypeId = "Q", Name = ".Net", CaseCategoryId = "Q"}.Build()
                    }.Build().In(_db),
                    SubTypeDescription = "Certification Mark"
                }.Build().In(_db);

                var validSubType3 = new ValidSubTypeBuilder
                {
                    Country = new CountryBuilder {Id = "US", Name = "United States of America"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "D", Name = "Design"}.Build(),
                    CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build(),
                    SubType = new SubTypeBuilder {Id = "D", Name = "Defensive Mark"}.Build(),
                    ValidCategory = new ValidCategoryBuilder
                    {
                        Country = new CountryBuilder {Id = "US", Name = "United States of America"}.Build(),
                        PropertyType = new PropertyTypeBuilder {Id = "D", Name = "Design"}.Build(),
                        CaseType = new CaseTypeBuilder {Id = "Q", Name = "Properties"}.Build(),
                        CaseCategory = new CaseCategoryBuilder {CaseTypeId = "Q", Name = ".NET", CaseCategoryId = "Q"}.Build()
                    }.Build().In(_db),
                    SubTypeDescription = "Defensive Mark"
                }.Build().In(_db);

                var validSubType4 = new ValidSubTypeBuilder
                {
                    Country = new CountryBuilder {Id = "US", Name = "United States of America"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "ND", Name = "Domain Name"}.Build(),
                    CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build(),
                    SubType = new SubTypeBuilder {Id = "L", Name = "Collective Mark"}.Build(),
                    ValidCategory = new ValidCategoryBuilder
                    {
                        Country = new CountryBuilder {Id = "US", Name = "United States of America"}.Build(),
                        PropertyType = new PropertyTypeBuilder {Id = "ND", Name = "Domain Name"}.Build(),
                        CaseType = new CaseTypeBuilder {Id = "R", Name = "Properties"}.Build(),
                        CaseCategory = new CaseCategoryBuilder {CaseTypeId = "R", Name = "Normal", CaseCategoryId = "R"}.Build()
                    }.Build().In(_db),
                    SubTypeDescription = "Collective Mark"
                }.Build().In(_db);

                return new
                {
                    validSubType1,
                    validSubType2,
                    validSubType3,
                    validSubType4
                };
            }
        }

        public class GetPagedResultsMethod : FactBase
        {
            [Fact]
            public void OrdersByCountry()
            {
                var f = new ValidSubTypeControllerFixture(Db);
                f.SetupValidSubTypes();

                var result = f.Subject.GetPagedResults(Db.Set<ValidSubType>(),
                                                       new CommonQueryParameters {SortBy = "Country", SortDir = "asc", Skip = 0, Take = 10});

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(4, results.Length);
                Assert.Equal(Db.Set<ValidSubType>().OrderBy(st => st.Country.Name).First().SubTypeDescription, results[0].ValidDescription);
            }

            [Fact]
            public void SkipsAndTakes()
            {
                var f = new ValidSubTypeControllerFixture(Db);
                f.SetupValidSubTypes();

                var result = f.Subject.GetPagedResults(Db.Set<ValidSubType>(),
                                                       new CommonQueryParameters {SortBy = "Country", SortDir = "asc", Skip = 1, Take = 3});

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(3, results.Length);
                Assert.Equal(Db.Set<ValidSubType>()
                               .OrderBy(_ => _.Country.Name).Skip(1).Take(3).First().SubTypeDescription, results[0].ValidDescription);
            }
        }

        public class SearchValidSubType : FactBase
        {
            [Fact]
            public void SearchAllSubTypes()
            {
                var searchCriteria = new ValidCombinationSearchCriteria();
                var f = new ValidSubTypeControllerFixture(Db);
                f.SetupValidSubTypes();

                var result = f.Subject.SearchValidSubType(searchCriteria);
                Assert.Equal(4, result.Count());
            }

            [Fact]
            public void SearchBasedOnAllFilter()
            {
                var searchCriteria = new ValidCombinationSearchCriteria
                {
                    PropertyType = "D",
                    CaseType = "P",
                    SubType = "D",
                    CaseCategory = "Q",
                    Jurisdictions = new[] {"US"}
                };

                var f = new ValidSubTypeControllerFixture(Db);
                f.SetupValidSubTypes();

                var results = f.Subject.SearchValidSubType(searchCriteria);

                Assert.Equal(1, results.Count());
                Assert.Contains(Db.Set<ValidSubType>()
                                  .First(c => c.PropertyType.Code == searchCriteria.PropertyType
                                              && c.CaseType.Code == searchCriteria.CaseType
                                              && searchCriteria.Jurisdictions.Contains(c.Country.Id)
                                              && c.CaseCategoryId == searchCriteria.CaseCategory).SubTypeDescription, results.First().SubTypeDescription);
            }

            [Fact]
            public void SearchBasedOnCaseCategory()
            {
                var searchCriteria = new ValidCombinationSearchCriteria {CaseCategory = "Q"};
                var f = new ValidSubTypeControllerFixture(Db);
                f.SetupValidSubTypes();

                var result = f.Subject.SearchValidSubType(searchCriteria);

                Assert.Equal(2, result.Count());
                Assert.Contains(Db.Set<ValidSubType>()
                                  .First(c => c.CaseCategoryId == searchCriteria.CaseCategory), result);
            }

            [Fact]
            public void SearchBasedOnCaseType()
            {
                var searchCriteria = new ValidCombinationSearchCriteria {CaseType = "I"};
                var f = new ValidSubTypeControllerFixture(Db);
                f.SetupValidSubTypes();

                var results = f.Subject.SearchValidSubType(searchCriteria);

                Assert.Equal(1, results.Count());
                Assert.Contains(Db.Set<ValidSubType>().First(c => c.CaseTypeId == searchCriteria.CaseType).SubTypeDescription, results.First().SubTypeDescription);
            }

            [Fact]
            public void SearchBasedOnMultipleCountries()
            {
                var searchCriteria = new ValidCombinationSearchCriteria {Jurisdictions = new[] {"GB", "US"}};
                var f = new ValidSubTypeControllerFixture(Db);
                f.SetupValidSubTypes();

                var result = f.Subject.SearchValidSubType(searchCriteria);

                var filteredSubTypes = Db.Set<ValidSubType>().Where(_ => searchCriteria.Jurisdictions.Contains(_.CountryId));

                Assert.Equal(filteredSubTypes.Count(), result.Count());

                foreach (var item in filteredSubTypes) Assert.Contains(item, result);
            }

            [Fact]
            public void SearchBasedOnPropertyType()
            {
                var searchCriteria = new ValidCombinationSearchCriteria {PropertyType = "T"};
                var f = new ValidSubTypeControllerFixture(Db);
                f.SetupValidSubTypes();

                var results = f.Subject.SearchValidSubType(searchCriteria);

                Assert.Equal(1, results.Count());
                Assert.Contains(Db.Set<ValidSubType>().First(c => c.PropertyTypeId == searchCriteria.PropertyType).SubTypeDescription, results.First().SubTypeDescription);
            }

            [Fact]
            public void SearchBasedOnSubType()
            {
                var searchCriteria = new ValidCombinationSearchCriteria {SubType = "5"};
                var f = new ValidSubTypeControllerFixture(Db);
                f.SetupValidSubTypes();

                var results = f.Subject.SearchValidSubType(searchCriteria);

                Assert.Equal(1, results.Count());
                Assert.Contains(Db.Set<ValidSubType>().First(c => c.SubtypeId == searchCriteria.SubType).SubTypeDescription, results.First().SubTypeDescription);
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void ThrowsExceptionWhenValidSubTypeNotFoundForGivenCriteria()
            {
                var f = new ValidSubTypeControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.ValidSubType(
                                                                  new ValidSubTypeIdentifier("XXX", "YYY", "ZZZ", "AAA", "ZZ")));

                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void CallsValidSubTypeSave()
            {
                var f = new ValidSubTypeControllerFixture(Db);

                var model = new SubTypeSaveDetails();
                var result = new object();

                f.ValidSubTypes.Save(model).Returns(result);

                f.Subject.Save(model);

                f.ValidSubTypes.ReceivedWithAnyArgs().Save(model);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void CallsValidPropertyTypeUpdate()
            {
                var f = new ValidSubTypeControllerFixture(Db);

                var model = new SubTypeSaveDetails();

                var returnValue = new object();
                f.ValidSubTypes.Update(model).Returns(returnValue);

                f.Subject.Update(model);

                f.ValidSubTypes.ReceivedWithAnyArgs().Update(model);
            }

            [Fact]
            public void ThrowsExceptionWhenResponseIsNullForDelete()
            {
                var f = new ValidSubTypeControllerFixture(Db);

                var model = new SubTypeSaveDetails();
                f.ValidSubTypes.Update(Arg.Any<SubTypeSaveDetails>()).Returns(null as object);

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
                var f = new ValidSubTypeControllerFixture(Db);

                var model = new ValidSubTypeIdentifier[] { };

                var returnValue = new DeleteResponseModel<ValidSubTypeIdentifier>();
                f.ValidSubTypes.Delete(Arg.Any<ValidSubTypeIdentifier[]>()).Returns(returnValue);

                f.Subject.Delete(model);

                f.ValidSubTypes.ReceivedWithAnyArgs().Delete(Arg.Any<ValidSubTypeIdentifier[]>());
            }

            [Fact]
            public void ThrowsExceptionWhenResponseIsNullForDelete()
            {
                var f = new ValidSubTypeControllerFixture(Db);

                var model = new ValidSubTypeIdentifier[] { };

                f.ValidSubTypes.Delete(Arg.Any<ValidSubTypeIdentifier[]>()).Returns(null as DeleteResponseModel<ValidSubTypeIdentifier>);

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
                var f = new ValidSubTypeControllerFixture(Db);
                f.SetupValidSubTypes();

                var toCountries = new[] {new CountryModel {Code = "AUT"}, new CountryModel {Code = "IT"}};

                f.Subject.Copy(new CountryModel {Code = "US"}, toCountries);

                var validSubtypesForAmerica = Db.Set<ValidSubType>()
                                                .Where(_ => _.CountryId == "US");

                foreach (var vs in validSubtypesForAmerica)
                {
                    var validSubtype = vs;

                    Assert.NotNull(
                                   Db.Set<ValidSubType>()
                                     .Where(_ => _.CountryId == "AUT" && _.PropertyTypeId == validSubtype.PropertyTypeId
                                                                      && _.CaseTypeId == validSubtype.CaseTypeId && _.SubtypeId == validSubtype.SubtypeId));
                    Assert.NotNull(
                                   Db.Set<ValidSubType>()
                                     .Where(_ => _.CountryId == "IT" && _.PropertyTypeId == validSubtype.PropertyTypeId
                                                                     && _.CaseTypeId == validSubtype.CaseTypeId && _.SubtypeId == validSubtype.SubtypeId));
                }
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenFromCountryNotPassed()
            {
                var f = new ValidSubTypeControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Copy(null, new[] {new CountryModel {Code = "GB"}}));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("fromJurisdiction", exception.Message);
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenToCountriesNotPassed()
            {
                var f = new ValidSubTypeControllerFixture(Db);

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
                var fixture = new ValidSubTypeControllerFixture(Db);
                fixture.SetupValidSubTypes();

                fixture
                    .Subject
                    .ExportToExcel(new ValidCombinationSearchCriteria());

                var totalInDb = Db.Set<ValidSubType>().Count();

                fixture.Exporter.Received(1).Export(Arg.Is<PagedResults>(x => x.Data.Count() == totalInDb), "Search Result.xlsx");
            }
        }
    }
}