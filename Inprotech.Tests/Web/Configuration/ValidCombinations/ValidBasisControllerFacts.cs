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
    public class ValidBasisControllerFacts
    {
        public class ValidBasisControllerFixture : IFixture<ValidBasisController>
        {
            readonly InMemoryDbContext _db;

            public ValidBasisControllerFixture(InMemoryDbContext db)
            {
                _db = db;

                ValidBasisImp = Substitute.For<IValidBasisImp>();

                Exporter = Substitute.For<ISimpleExcelExporter>();

                Subject = new ValidBasisController(_db, ValidBasisImp, Exporter);
            }

            public IValidBasisImp ValidBasisImp { get; }
            public ISimpleExcelExporter Exporter { get; }

            public ValidBasisController Subject { get; }

            public dynamic SetupValidBasis()
            {
                var validBasis1 = new ValidBasisBuilder
                {
                    Country = new CountryBuilder {Id = "NZ", Name = "New Zealand"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "P", Name = "Patent"}.Build(),
                    Basis = new ApplicationBasisBuilder {Id = "C", Name = "Convention"}.Build(),
                    BasisDesc = "Claiming NZ Convention"
                }.Build().In(_db);

                var validBasisEx1 = new ValidBasisExBuilder
                {
                    ValidBasis = validBasis1,
                    CaseType = new CaseTypeBuilder {Id = "I", Name = "Internal"}.Build(),
                    CaseCategory = new CaseCategoryBuilder {CaseTypeId = "P", Name = ".COM", CaseCategoryId = "P"}.Build()
                }.Build().In(_db);

                var validBasis2 = new ValidBasisBuilder
                {
                    Country = new CountryBuilder {Id = "AU", Name = "Australia"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "P", Name = "Patent"}.Build(),
                    Basis = new ApplicationBasisBuilder {Id = "N", Name = "Non Convention"}.Build(),
                    BasisDesc = "Non Aus Convention"
                }.Build().In(_db);

                var validBasisEx2 = new ValidBasisExBuilder
                {
                    ValidBasis = validBasis2,
                    CaseType = new CaseTypeBuilder {Id = "D", Name = "Design"}.Build(),
                    CaseCategory = new CaseCategoryBuilder {CaseTypeId = "D", Name = "Domain", CaseCategoryId = "D"}.Build()
                }.Build().In(_db);

                var validBasis3 = new ValidBasisBuilder
                {
                    Country = new CountryBuilder {Id = "US", Name = "United States of America"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "P", Name = "Patent"}.Build(),
                    Basis = new ApplicationBasisBuilder {Id = "C", Name = "Convention"}.Build(),
                    BasisDesc = "Aus Convention"
                }.Build().In(_db);

                var validBasisEx3 = new ValidBasisExBuilder
                {
                    ValidBasis = validBasis3,
                    CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build(),
                    CaseCategory = new CaseCategoryBuilder {CaseTypeId = "P", Name = ".COM", CaseCategoryId = "D"}.Build()
                }.Build().In(_db);

                var validBasis4 = new ValidBasisBuilder
                {
                    Country = new CountryBuilder {Id = "GB", Name = "Great Britain"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "P", Name = "Patent"}.Build(),
                    Basis = new ApplicationBasisBuilder {Id = "C", Name = "Convention"}.Build(),
                    BasisDesc = "Convention"
                }.Build().In(_db);

                var validBasisEx4 = new ValidBasisExBuilder
                {
                    ValidBasis = validBasis4,
                    CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build(),
                    CaseCategory = new CaseCategoryBuilder {CaseTypeId = "P", Name = ".COM", CaseCategoryId = "D"}.Build()
                }.Build().In(_db);

                return new
                {
                    validBasis1,
                    validBasis2,
                    validBasis3,
                    validBasis4,
                    validBasisEx1,
                    validBasisEx2,
                    validBasisEx3,
                    validBasisEx4
                };
            }
        }

        public class GetPagedResultsMethod : FactBase
        {
            [Fact]
            public void OrdersByCountry()
            {
                var f = new ValidBasisControllerFixture(Db);
                f.SetupValidBasis();

                var allResult = f.Subject.SearchValidBasis(new ValidCombinationSearchCriteria());

                var result = f.Subject.GetPagedResults(allResult,
                                                       new CommonQueryParameters {SortBy = "Country", SortDir = "asc", Skip = 0, Take = 10});

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(4, results.Length);
                Assert.Equal(allResult.OrderBy(st => st.CountryCode).First().ValidDescription, results[0].ValidDescription);
            }

            [Fact]
            public void SkipsAndTakes()
            {
                var f = new ValidBasisControllerFixture(Db);
                f.SetupValidBasis();

                var allResult = f.Subject.SearchValidBasis(new ValidCombinationSearchCriteria());

                var result = f.Subject.GetPagedResults(allResult,
                                                       new CommonQueryParameters {SortBy = "Country", SortDir = "asc", Skip = 1, Take = 3});

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(3, results.Length);
                Assert.Equal(allResult.OrderBy(_ => _.Country).Skip(1).Take(3).First().ValidDescription, results[0].ValidDescription);
            }
        }

        public class SearchValidBasis : FactBase
        {
            [Fact]
            public void SearchAllBasis()
            {
                var f = new ValidBasisControllerFixture(Db);
                f.SetupValidBasis();
                var searchCriteria = new ValidCombinationSearchCriteria();

                var result = f.Subject.SearchValidBasis(searchCriteria);
                Assert.Equal(4, result.Count());
            }

            [Fact]
            public void SearchBasedOnAllFilter()
            {
                var f = new ValidBasisControllerFixture(Db);
                f.SetupValidBasis();
                var searchCriteria = new ValidCombinationSearchCriteria
                {
                    PropertyType = "P",
                    CaseType = "I",
                    Basis = "C",
                    CaseCategory = "P",
                    Jurisdictions = new[] {"NZ"}
                };

                var result = f.Subject.SearchValidBasis(searchCriteria);

                Assert.Equal(1, result.Count());
                Assert.Equal(searchCriteria.Basis, result.First().BasisId);
                Assert.Equal(searchCriteria.CaseType, result.First().CaseTypeId);
                Assert.Equal(searchCriteria.PropertyType, result.First().PropertyTypeId);
                Assert.Contains(result.First().CountryCode, searchCriteria.Jurisdictions);
            }

            [Fact]
            public void SearchBasedOnBasis()
            {
                var f = new ValidBasisControllerFixture(Db);
                f.SetupValidBasis();
                var searchCriteria = new ValidCombinationSearchCriteria {Basis = "N"};

                var result = f.Subject.SearchValidBasis(searchCriteria);

                var filteredBasis =
                    f.Subject.SearchValidBasis(new ValidCombinationSearchCriteria())
                     .Where(_ => _.BasisId == searchCriteria.Basis);

                Assert.Equal(filteredBasis.Count(), result.Count());
                foreach (var vc in result) Assert.Equal(searchCriteria.Basis, vc.BasisId);
            }

            [Fact]
            public void SearchBasedOnCaseCategory()
            {
                var f = new ValidBasisControllerFixture(Db);
                f.SetupValidBasis();
                var searchCriteria = new ValidCombinationSearchCriteria {CaseCategory = "R"};

                var result = f.Subject.SearchValidBasis(searchCriteria);

                var filteredBasis =
                    f.Subject.SearchValidBasis(new ValidCombinationSearchCriteria())
                     .Where(_ => _.CategoryId == searchCriteria.CaseCategory);

                Assert.Equal(filteredBasis.Count(), result.Count());
                foreach (var vc in result) Assert.Equal(searchCriteria.CaseCategory, vc.CategoryId);
            }

            [Fact]
            public void SearchBasedOnCaseType()
            {
                var f = new ValidBasisControllerFixture(Db);
                f.SetupValidBasis();
                var searchCriteria = new ValidCombinationSearchCriteria {CaseType = "I"};

                var result = f.Subject.SearchValidBasis(searchCriteria);

                var filteredBasis =
                    f.Subject.SearchValidBasis(new ValidCombinationSearchCriteria())
                     .Where(_ => _.CaseTypeId == searchCriteria.CaseType);

                Assert.Equal(filteredBasis.Count(), result.Count());
                foreach (var vc in result) Assert.Equal(searchCriteria.CaseType, vc.CaseTypeId);
            }

            [Fact]
            public void SearchBasedOnMultipleCountries()
            {
                var f = new ValidBasisControllerFixture(Db);
                f.SetupValidBasis();
                var searchCriteria = new ValidCombinationSearchCriteria {Jurisdictions = new[] {"AU", "GB"}};

                var result = f.Subject.SearchValidBasis(searchCriteria);

                var filteredBasis =
                    f.Subject.SearchValidBasis(new ValidCombinationSearchCriteria())
                     .Where(_ => searchCriteria.Jurisdictions.Contains(_.CountryCode));

                Assert.Equal(filteredBasis.Count(), result.Count());

                foreach (var item in filteredBasis) Assert.Contains(item.CountryCode, searchCriteria.Jurisdictions);
            }

            [Fact]
            public void SearchBasedOnPropertyType()
            {
                var f = new ValidBasisControllerFixture(Db);
                f.SetupValidBasis();
                var searchCriteria = new ValidCombinationSearchCriteria {PropertyType = "N"};

                var result = f.Subject.SearchValidBasis(searchCriteria);

                var filteredBasis =
                    f.Subject.SearchValidBasis(new ValidCombinationSearchCriteria())
                     .Where(_ => _.PropertyTypeId == searchCriteria.PropertyType);

                Assert.Equal(filteredBasis.Count(), result.Count());
                foreach (var vc in result) Assert.Equal(searchCriteria.PropertyType, vc.PropertyTypeId);
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void ThrowsExceptionWhenValidCategoryNotFoundForGivenValues()
            {
                var f = new ValidBasisControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.ValidBasis(new ValidBasisIdentifier("XXX", "YYY", "ZZZ", "AA", "BB")));

                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void CallsValidPropertyTypeSave()
            {
                var f = new ValidBasisControllerFixture(Db);

                var model = new BasisSaveDetails();
                var result = new object();

                f.ValidBasisImp.Save(model).Returns(result);

                f.Subject.Save(model);

                f.ValidBasisImp.ReceivedWithAnyArgs().Save(model);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void CallsValidPropertyTypeUpdate()
            {
                var f = new ValidBasisControllerFixture(Db);

                var model = new BasisSaveDetails();

                var returnValue = new object();
                f.ValidBasisImp.Update(model).Returns(returnValue);

                f.Subject.Update(model);

                f.ValidBasisImp.ReceivedWithAnyArgs().Update(model);
            }

            [Fact]
            public void ThrowsExceptionWhenResponseIsNullForDelete()
            {
                var f = new ValidBasisControllerFixture(Db);

                var model = new BasisSaveDetails();
                f.ValidBasisImp.Update(Arg.Any<BasisSaveDetails>()).Returns(null as object);

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
                var f = new ValidBasisControllerFixture(Db);

                var model = new ValidBasisIdentifier[] { };

                var returnValue = new DeleteResponseModel<ValidBasisIdentifier>();
                f.ValidBasisImp.Delete(Arg.Any<ValidBasisIdentifier[]>()).Returns(returnValue);

                f.Subject.Delete(model);

                f.ValidBasisImp.ReceivedWithAnyArgs().Delete(Arg.Any<ValidBasisIdentifier[]>());
            }

            [Fact]
            public void ThrowsExceptionWhenResponseIsNullForDelete()
            {
                var f = new ValidBasisControllerFixture(Db);

                var model = new ValidBasisIdentifier[] { };

                f.ValidBasisImp.Delete(Arg.Any<ValidBasisIdentifier[]>()).Returns(null as DeleteResponseModel<ValidBasisIdentifier>);

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
                var f = new ValidBasisControllerFixture(Db);
                f.SetupValidBasis();

                var toCountries = new[] {new CountryModel {Code = "AUT"}, new CountryModel {Code = "IT"}};

                f.Subject.Copy(new CountryModel {Code = "US"}, toCountries);

                var validBasisForAmerica = Db.Set<ValidBasis>()
                                             .Where(_ => _.CountryId == "US");

                foreach (var vb in validBasisForAmerica)
                {
                    var validBasis = vb;

                    Assert.NotNull(
                                   Db.Set<ValidBasis>()
                                     .Where(_ => _.CountryId == "AUT" && _.PropertyTypeId == validBasis.PropertyTypeId
                                                                      && _.BasisId == validBasis.BasisId));
                    Assert.NotNull(
                                   Db.Set<ValidBasis>()
                                     .Where(_ => _.CountryId == "IT" && _.PropertyTypeId == validBasis.PropertyTypeId
                                                                     && _.BasisId == validBasis.BasisId));
                }

                var validBasisExForAmerica = Db.Set<ValidBasisEx>()
                                               .Where(_ => _.CountryId == "US");

                foreach (var vbx in validBasisExForAmerica)
                {
                    var validBasisEx = vbx;

                    Assert.NotNull(
                                   Db.Set<ValidBasisEx>()
                                     .Where(_ => _.CountryId == "AUT" && _.PropertyTypeId == validBasisEx.PropertyTypeId && _.CaseTypeId == validBasisEx.CaseTypeId
                                                 && _.CaseCategoryId == validBasisEx.CaseCategoryId && _.BasisId == validBasisEx.BasisId));
                    Assert.NotNull(
                                   Db.Set<ValidBasisEx>()
                                     .Where(_ => _.CountryId == "IT" && _.PropertyTypeId == validBasisEx.PropertyTypeId && _.CaseTypeId == validBasisEx.CaseTypeId
                                                 && _.CaseCategoryId == validBasisEx.CaseCategoryId && _.BasisId == validBasisEx.BasisId));
                }
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenFromCountryNotPassed()
            {
                var f = new ValidBasisControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Copy(null, new[] {new CountryModel {Code = "GB"}}));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("fromJurisdiction", exception.Message);
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenToCountriesNotPassed()
            {
                var f = new ValidBasisControllerFixture(Db);

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
                var f = new ValidBasisControllerFixture(Db);
                f.SetupValidBasis();

                f.Subject
                 .ExportToExcel(new ValidCombinationSearchCriteria());

                var totalInDb = Db.Set<ValidBasis>().Count();

                f.Exporter.Export(Arg.Is<PagedResults>(x => x.Data.Count() == totalInDb), "Search Result.xslx");
            }
        }
    }
}