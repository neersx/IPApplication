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
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;
using CaseType = Inprotech.Web.Picklists.CaseType;
using PropertyType = Inprotech.Web.Picklists.PropertyType;

namespace Inprotech.Tests.Web.Configuration.ValidCombinations
{
    public class ValidStatusControllerFacts
    {
        public class ValidStatusControllerFixture : IFixture<ValidStatusController>
        {
            readonly InMemoryDbContext _db;

            public ValidStatusControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                Validator = Substitute.For<IValidCombinationValidator>();

                Exporter = Substitute.For<ISimpleExcelExporter>();

                Subject = new ValidStatusController(_db, Validator, Exporter);
            }

            public IValidCombinationValidator Validator { get; }
            public ISimpleExcelExporter Exporter { get; }
            public ValidStatusController Subject { get; }

            public dynamic SetupValidStatuses()
            {
                var country = new CountryBuilder {Id = "NZ", Name = "New Zealand"}.Build();
                var propertyType = new PropertyTypeBuilder {Id = "T", Name = "TradeMark"}.Build();
                var caseType = new CaseTypeBuilder {Id = "I", Name = "Licensing"}.Build();

                var renewalStatus1 = new Status(Fixture.Short(), "CPA to be notified")
                {
                    RenewalFlag = 1,
                    ExternalName = "CPA to be notified"
                }.In(_db);

                var caseStatus1 = new Status(Fixture.Short(), "EP Granted")
                {
                    RenewalFlag = 0,
                    ExternalName = "Granted"
                }.In(_db);

                var renewalStatus2 = new Status(Fixture.Short(), "Renewal overdue")
                {
                    RenewalFlag = 1,
                    ExternalName = "Renewable with extensions"
                }.In(_db);

                var caseStatus2 = new Status(Fixture.Short(), "Certificate received")
                {
                    RenewalFlag = 0,
                    ExternalName = "Registered"
                }.In(_db);

                var validStatus1 = new ValidStatusBuilder
                {
                    Country = country,
                    PropertyType = propertyType,
                    CaseType = caseType,
                    Status = renewalStatus1
                }.Build().In(_db);

                var validStatus2 = new ValidStatusBuilder
                {
                    Country = new CountryBuilder {Id = "GB", Name = "United Kingdom"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "P", Name = "Patent"}.Build(),
                    CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build(),
                    Status = caseStatus1
                }.Build().In(_db);

                var validStatus3 = new ValidStatusBuilder
                {
                    Country = new CountryBuilder {Id = "US", Name = "United States of America"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "D", Name = "Design"}.Build(),
                    CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build(),
                    Status = renewalStatus2
                }.Build().In(_db);

                var validStatus4 = new ValidStatusBuilder
                {
                    Country = new CountryBuilder {Id = "US", Name = "United States of America"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "ND", Name = "Domain Name"}.Build(),
                    CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build(),
                    Status = caseStatus2
                }.Build().In(_db);

                var validStatus5 = new ValidStatusBuilder
                {
                    Country = new CountryBuilder {Id = "IN", Name = "India"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "ND", Name = "Domain Name"}.Build(),
                    CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build(),
                    Status = caseStatus2
                }.Build().In(_db);

                return new
                {
                    country,
                    propertyType,
                    caseType,
                    renewalStatus1,
                    caseStatus1,
                    renewalStatus2,
                    caseStatus2,
                    validStatus1,
                    validStatus2,
                    validStatus3,
                    validStatus4,
                    validStatus5
                };
            }
        }

        public class GetPagedResultsMethod : FactBase
        {
            [Fact]
            public void OrdersByCountryAndReturnsStatusType()
            {
                var f = new ValidStatusControllerFixture(Db);
                f.SetupValidStatuses();

                var result = f.Subject.GetPagedResults(Db.Set<ValidStatus>(),
                                                       new CommonQueryParameters {SortBy = "Country", SortDir = "asc", Skip = 0, Take = 10});

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(5, results.Length);
                Assert.Equal(Db.Set<ValidStatus>().OrderBy(c => c.Country.Name).First().Country.Name, results[0].Country);
                Assert.True(results.All(_ => !string.IsNullOrEmpty(_.StatusType)));
            }

            [Fact]
            public void SkipsAndTakes()
            {
                var f = new ValidStatusControllerFixture(Db);
                f.SetupValidStatuses();

                var result = f.Subject.GetPagedResults(Db.Set<ValidStatus>(),
                                                       new CommonQueryParameters {SortBy = "Country", SortDir = "asc", Skip = 2, Take = 2});

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(2, results.Length);
                Assert.Equal(Db.Set<ValidStatus>()
                               .OrderBy(_ => _.Country.Name).Skip(2).Take(2).First().Country.Name, results[0].Country);
            }
        }

        public class SearchValidStatus : FactBase
        {
            [Fact]
            public void SearchAllValidStatuses()
            {
                var searchCriteria = new ValidCombinationSearchCriteria();
                var f = new ValidStatusControllerFixture(Db);
                f.SetupValidStatuses();

                var result = f.Subject.SearchValidStatus(searchCriteria);
                Assert.Equal(5, result.Count());
            }

            [Fact]
            public void SearchBasedOnAllFilter()
            {
                var f = new ValidStatusControllerFixture(Db);
                var statusList = f.SetupValidStatuses();

                var searchCriteria = new ValidCombinationSearchCriteria
                {
                    PropertyType = "P",
                    CaseType = "P",
                    Status = statusList.caseStatus1.Id,
                    Jurisdictions = new[] {"GB"}
                };

                var result = f.Subject.SearchValidStatus(searchCriteria);

                var filteredStatuses =
                    Db.Set<ValidStatus>()
                      .Where(c => c.PropertyType.Code == searchCriteria.PropertyType
                                  && c.CaseType.Code == searchCriteria.CaseType
                                  && searchCriteria.Jurisdictions.Contains(c.Country.Id)
                                  && c.Status.Id == (short) searchCriteria.Status);

                Assert.Equal(filteredStatuses.Count(), result.Count());
                Assert.Contains(filteredStatuses.FirstOrDefault(), result);
            }

            [Fact]
            public void SearchBasedOnCaseType()
            {
                var searchCriteria = new ValidCombinationSearchCriteria {CaseType = "I"};
                var f = new ValidStatusControllerFixture(Db);
                f.SetupValidStatuses();

                var result = f.Subject.SearchValidStatus(searchCriteria);
                var filteredStatuses = Db.Set<ValidStatus>().Where(c => c.CaseTypeId == "I");

                Assert.Equal(filteredStatuses.Count(), result.Count());
                Assert.Contains(filteredStatuses.FirstOrDefault(), result);
            }

            [Fact]
            public void SearchBasedOnMultipleCountries()
            {
                var searchCriteria = new ValidCombinationSearchCriteria {Jurisdictions = new[] {"GB", "US"}};
                var f = new ValidStatusControllerFixture(Db);
                f.SetupValidStatuses();

                var result = f.Subject.SearchValidStatus(searchCriteria);
                var filteredStatuses = Db.Set<ValidStatus>().Where(c => c.Country.Id == "GB" || c.Country.Id == "US");

                Assert.Equal(filteredStatuses.Count(), result.Count());

                foreach (var validStatus in filteredStatuses) Assert.Contains(validStatus, result);
            }

            [Fact]
            public void SearchBasedOnProperty()
            {
                var searchCriteria = new ValidCombinationSearchCriteria {PropertyType = "P"};
                var f = new ValidStatusControllerFixture(Db);
                f.SetupValidStatuses();

                var result = f.Subject.SearchValidStatus(searchCriteria);
                var filteredStatuses = Db.Set<ValidStatus>().Where(c => c.PropertyTypeId == "P");

                Assert.Equal(filteredStatuses.Count(), result.Count());
                Assert.Contains(filteredStatuses.FirstOrDefault(), result);
            }

            [Fact]
            public void SearchBasedOnStatus()
            {
                var f = new ValidStatusControllerFixture(Db);
                var statusList = f.SetupValidStatuses();

                var searchCriteria = new ValidCombinationSearchCriteria
                {
                    Status = statusList.renewalStatus2.Id
                };

                var result = f.Subject.SearchValidStatus(searchCriteria);

                var filteredStatuses = Db.Set<ValidStatus>()
                                         .Where(c => c.Status.Id == (short) searchCriteria.Status);

                Assert.Equal(filteredStatuses.Count(), result.Count());
                Assert.Contains(filteredStatuses.FirstOrDefault(), result);
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void ReturnValidStatusForGivenKeys()
            {
                var f = new ValidStatusControllerFixture(Db);
                var data = f.SetupValidStatuses();

                var result = (ValidStatusController.StatusSaveDetails) f.Subject.ValidStatus(
                                                                                             new ValidStatusController.ValidStatusIdentifier(
                                                                                                                                             data.validStatus1.CountryId, data.validStatus1.PropertyTypeId, data.validStatus1.CaseTypeId,
                                                                                                                                             data.validStatus1.StatusCode));

                Assert.NotNull(result);
                Assert.Equal(data.validStatus1.CountryId, result.Jurisdictions.First().Code);
                Assert.Equal(data.validStatus1.PropertyTypeId, result.PropertyType.Code);
                Assert.Equal(data.validStatus1.CaseTypeId, result.CaseType.Code);
                Assert.Equal(data.validStatus1.StatusCode, result.Status.Key);
            }

            [Fact]
            public void ThrowsExceptionWhenValidStatusNotFoundForGivenValues()
            {
                var f = new ValidStatusControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.ValidStatus(
                                                                 new ValidStatusController.ValidStatusIdentifier("XXX", "YYY", "ZZZ", 0)));

                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class SaveMethod : FactBase
        {
            ValidStatusController.StatusSaveDetails PrepareSave()
            {
                var countryId1 = Fixture.String("CountryId1");
                var countryId2 = Fixture.String("CountryId2");
                var propertyTypeId = Fixture.String("PropertyTypeId");
                new ValidProperty
                {
                    CountryId = countryId1,
                    PropertyTypeId = propertyTypeId,
                    PropertyName = Fixture.String("ValidProperty")
                }.In(Db);
                new ValidProperty
                {
                    CountryId = countryId2,
                    PropertyTypeId = propertyTypeId,
                    PropertyName = Fixture.String("ValidProperty")
                }.In(Db);

                return new ValidStatusController.StatusSaveDetails
                {
                    Jurisdictions = new[]
                    {
                        new CountryModel
                        {
                            Code = countryId1
                        },
                        new CountryModel
                        {
                            Code = countryId2
                        }
                    },
                    PropertyType = new PropertyType {Code = propertyTypeId},
                    CaseType = new CaseType {Code = Fixture.String("CaseTypeId")},
                    Status = new Inprotech.Web.Picklists.Status {Code = Fixture.Short()}
                };
            }

            [Fact]
            public void AddValidStatusForGivenValues()
            {
                var f = new ValidStatusControllerFixture(Db);
                f.SetupValidStatuses();
                var input = PrepareSave();

                f.Validator.CheckValidPropertyCombination(input).Returns((ValidationResult) null);

                var result = f.Subject.Save(input);

                Assert.Equal("success", result.Result);
                Assert.Equal(2, ((IEnumerable<ValidStatusController.ValidStatusIdentifier>) result.UpdatedKeys).Count());
                Assert.Equal(7, Db.Set<ValidStatus>().Count());
            }

            [Fact]
            public void ReturnsConfirmationValidationResultIfValidCategoryExistForSome()
            {
                var f = new ValidStatusControllerFixture(Db);
                var data = f.SetupValidStatuses();

                var input = new ValidStatusController.StatusSaveDetails
                {
                    Jurisdictions = new[]
                    {
                        new CountryModel {Code = data.validStatus1.CountryId, Value = data.validStatus1.Country.Name},
                        new CountryModel {Code = Fixture.String(), Value = Fixture.String()}
                    },
                    PropertyType = new PropertyType {Code = data.validStatus1.PropertyTypeId},
                    CaseType = new CaseType {Code = data.validStatus1.CaseTypeId},
                    Status = new Inprotech.Web.Picklists.Status {Code = data.validStatus1.StatusCode}
                };
                f.Validator.CheckValidPropertyCombination(input).Returns((ValidationResult) null);
                f.Validator.DuplicateCombinationValidationResult(null, 0).ReturnsForAnyArgs(new ValidationResult {Result = "confirmation"});

                var result = f.Subject.Save(input);

                Assert.Equal("confirmation", result.Result);
            }

            [Fact]
            public void ReturnsValidationResultIfValidPropertyTypeDoesnotExistForSelectedCombination()
            {
                var f = new ValidStatusControllerFixture(Db);
                var data = f.SetupValidStatuses();

                var input = new ValidStatusController.StatusSaveDetails
                {
                    Jurisdictions = new[] {new CountryModel {Code = data.validStatus1.CountryId, Value = data.validStatus1.Country.Name}},
                    PropertyType = new PropertyType {Code = "P"},
                    CaseType = new CaseType {Code = data.validStatus1.CaseTypeId},
                    Status = new Inprotech.Web.Picklists.Status {Code = data.validStatus1.StatusCode}
                };

                var validationResult = new ValidationResult
                {
                    Result = "Error"
                };

                f.Validator.CheckValidPropertyCombination(input).Returns(validationResult);

                var result = f.Subject.Save(input);

                Assert.Equal("Error", result.Result);
            }

            [Fact]
            public void ReturnsValidationResultIfValidStatusAlreadyExist()
            {
                var f = new ValidStatusControllerFixture(Db);
                var data = f.SetupValidStatuses();

                var input = new ValidStatusController.StatusSaveDetails
                {
                    Jurisdictions = new[] {new CountryModel {Code = data.validStatus1.CountryId, Value = data.validStatus1.Country.Name}},
                    PropertyType = new PropertyType {Code = data.validStatus1.PropertyTypeId},
                    CaseType = new CaseType {Code = data.validStatus1.CaseTypeId},
                    Status = new Inprotech.Web.Picklists.Status {Code = data.validStatus1.StatusCode}
                };
                f.Validator.CheckValidPropertyCombination(input).Returns((ValidationResult) null);
                f.Validator.DuplicateCombinationValidationResult(null, 0).ReturnsForAnyArgs(new ValidationResult {Result = "Error"});

                var result = f.Subject.Save(input);

                Assert.Equal("Error", result.Result);
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenSaveModelNotPassed()
            {
                var f = new ValidStatusControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Save(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("saveDetails", exception.Message);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeleteValidStatusesForGivenIdentifiers()
            {
                var f = new ValidStatusControllerFixture(Db);
                var data = f.SetupValidStatuses();

                var identifiers = new[]
                {
                    new ValidStatusController.ValidStatusIdentifier(data.validStatus1.CountryId,
                                                                    data.validStatus1.PropertyTypeId, data.validStatus1.CaseTypeId,
                                                                    data.validStatus1.StatusCode),
                    new ValidStatusController.ValidStatusIdentifier(data.validStatus3.CountryId,
                                                                    data.validStatus3.PropertyTypeId, data.validStatus3.CaseTypeId,
                                                                    data.validStatus3.StatusCode)
                };

                var result = f.Subject.Delete(identifiers);

                Assert.False(result.HasError);
                Assert.False(result.InUseIds.Any());
                Assert.Equal(3, Db.Set<ValidStatus>().Count());
            }

            [Fact]
            public void ReturnsErrorWithListOfIdsIfValidCombinationIsInUse()
            {
                var f = new ValidStatusControllerFixture(Db);
                var data = f.SetupValidStatuses();

                new CaseBuilder
                {
                    CountryCode = data.validStatus1.CountryId,
                    PropertyType = new PropertyTypeBuilder {Id = data.validStatus1.PropertyTypeId}.Build(),
                    CaseType = new CaseTypeBuilder {Id = data.validStatus1.CaseTypeId}.Build(),
                    Status = new StatusBuilder {Id = data.validStatus1.StatusCode}.Build()
                }.Build().In(Db);

                var identifiers = new[]
                {
                    new ValidStatusController.ValidStatusIdentifier(data.validStatus1.CountryId,
                                                                    data.validStatus1.PropertyTypeId, data.validStatus1.CaseTypeId,
                                                                    data.validStatus1.StatusCode)
                };
                var result = f.Subject.Delete(identifiers);

                Assert.True(result.HasError);
                Assert.True(result.InUseIds.Any());
                Assert.Equal(5, Db.Set<ValidStatus>().Count());
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenCollectionOfValidIdentifiersNotPassed()
            {
                var f = new ValidStatusControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Delete(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("deleteRequestModel", exception.Message);
            }
        }

        public class CopyMethod : FactBase
        {
            [Fact]
            public void ShouldCopyAllValidCombinationsForAllCountriesSpecified()
            {
                var f = new ValidStatusControllerFixture(Db);
                f.SetupValidStatuses();

                var toCountries = new[] {new CountryModel {Code = "AUT"}, new CountryModel {Code = "IT"}};

                f.Subject.Copy(new CountryModel {Code = "US"}, toCountries);

                var validStatusForAmerica = Db.Set<ValidStatus>()
                                              .Where(_ => _.CountryId == "US");

                foreach (var vs in validStatusForAmerica)
                {
                    var validStatus = vs;

                    Assert.NotNull(
                                   Db.Set<ValidStatus>()
                                     .Where(_ => _.CountryId == "AUT" && _.PropertyTypeId == validStatus.PropertyTypeId
                                                                      && _.CaseTypeId == validStatus.CaseTypeId && _.StatusCode == validStatus.StatusCode));
                    Assert.NotNull(
                                   Db.Set<ValidStatus>()
                                     .Where(_ => _.CountryId == "IT" && _.PropertyTypeId == validStatus.PropertyTypeId
                                                                     && _.CaseTypeId == validStatus.CaseTypeId && _.StatusCode == validStatus.StatusCode));
                }
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenFromCountryNotPassed()
            {
                var f = new ValidStatusControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Copy(null, new[] {new CountryModel {Code = "GB"}}));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("fromJurisdiction", exception.Message);
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenToCountriesNotPassed()
            {
                var f = new ValidStatusControllerFixture(Db);

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
                var fixture = new ValidStatusControllerFixture(Db);

                fixture.SetupValidStatuses();

                fixture
                    .Subject
                    .ExportToExcel(new ValidCombinationSearchCriteria());

                var totalInDb = Db.Set<ValidStatus>().Count();

                fixture.Exporter.Received(1).Export(Arg.Is<PagedResults>(x => x.Data.Count() == totalInDb), "Search Result.xlsx");
            }
        }
    }
}