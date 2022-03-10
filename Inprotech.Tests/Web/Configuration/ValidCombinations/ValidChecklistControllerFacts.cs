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
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;
using CaseType = Inprotech.Web.Picklists.CaseType;
using PropertyType = Inprotech.Web.Picklists.PropertyType;

namespace Inprotech.Tests.Web.Configuration.ValidCombinations
{
    public class ValidChecklistControllerFacts
    {
        public class ValidChecklistControllerFixture : IFixture<ValidChecklistController>
        {
            readonly InMemoryDbContext _db;

            public ValidChecklistControllerFixture(InMemoryDbContext db)
            {
                _db = db;

                Validator = Substitute.For<IValidCombinationValidator>();

                Exporter = Substitute.For<ISimpleExcelExporter>();

                Subject = new ValidChecklistController(_db, Validator, Exporter);
            }

            public IValidCombinationValidator Validator { get; }
            public ISimpleExcelExporter Exporter { get; }

            public ValidChecklistController Subject { get; }

            public dynamic GetChecklists()
            {
                var country = new CountryBuilder {Id = "NZ", Name = "New Zealand"}.Build();
                var propertyType = new PropertyTypeBuilder {Id = "P", Name = "Patents"}.Build();
                var caseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build();
                var chk = new ChecklistBuilder {Id = Fixture.Short(), Description = Fixture.String("checklist")}.Build();
                var checklist = new ValidChecklistBuilder
                {
                    Country = country,
                    PropertyType = propertyType,
                    CaseType = caseType,
                    CheckList = chk
                }.Build().In(_db);

                var country1 = new CountryBuilder {Id = "US", Name = "United States of America"}.Build();
                var checklist1 = new ValidChecklistBuilder
                {
                    Country = country1,
                    PropertyType = propertyType,
                    CaseType = caseType,
                    CheckList = chk
                }.Build().In(_db);

                var caseType2 = new CaseTypeBuilder {Id = "D", Name = "Designs"}.Build();
                var checklist2 = new ValidChecklistBuilder
                {
                    Country = country1,
                    PropertyType = propertyType,
                    CaseType = caseType2,
                    ChecklistType = Fixture.Short(),
                    CheckList = chk,
                    ChecklistDesc = "Checklist 3"
                }.Build().In(_db);

                var country3 = new CountryBuilder {Id = "IN", Name = "India"}.Build();
                var propertyType3 = new PropertyTypeBuilder {Id = "T", Name = "Trade Marks"}.Build();
                var caseType3 = new CaseTypeBuilder {Id = "I", Name = "Internal"}.Build();
                var checklistTypeId = Fixture.Short();
                var checklist3 = new ValidChecklistBuilder
                {
                    Country = country3,
                    PropertyType = propertyType3,
                    CaseType = caseType3,
                    ChecklistType = checklistTypeId,
                    ChecklistDesc = "Checklist 4"
                }.Build().In(_db);

                var checklist4 = new ValidChecklistBuilder
                {
                    Country = country3,
                    PropertyType = propertyType,
                    CaseType = caseType2,
                    ChecklistType = Fixture.Short(),
                    ChecklistDesc = "Checklist 5"
                }.Build().In(_db);

                new CountryBuilder {Id = "AU", Name = "Australia"}.Build().In(_db);
                new CountryBuilder {Id = "IT", Name = "Italy"}.Build().In(_db);
                new ValidPropertyBuilder {PropertyTypeId = "P", CountryCode = "AU", CountryName = "Australia"}.Build().In(_db);
                new ValidPropertyBuilder {PropertyTypeId = "P", CountryCode = "IT", CountryName = "Italy"}.Build().In(_db);

                return new
                {
                    country,
                    checklistTypeId,
                    propertyType,
                    caseType,
                    checklist,
                    checklist1,
                    checklist2,
                    checklist3,
                    checklist4
                };
            }
        }

        public class GetPagedResultsMethod : FactBase
        {
            [Fact]
            public void OrdersByCountryName()
            {
                var f = new ValidChecklistControllerFixture(Db);
                f.GetChecklists();

                var result = f.Subject.GetPagedResults(Db.Set<ValidChecklist>(),
                                                       new CommonQueryParameters {SortBy = "Country", SortDir = "asc", Skip = 0, Take = 10});

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();
                var filteredData = Db.Set<ValidChecklist>().OrderBy(c => c.Country.Name).First();

                Assert.Equal(5, results.Length);
                Assert.Equal(filteredData.Country.Name, results[0].Country);
            }

            [Fact]
            public void SkipsAndTakes()
            {
                var f = new ValidChecklistControllerFixture(Db);
                var data = f.GetChecklists();
                for (var i = 0; i < 10; i++)
                {
                    new ValidChecklistBuilder
                    {
                        Country = data.country,
                        PropertyType = new PropertyTypeBuilder {Id = Fixture.String("property type " + i), Name = Fixture.String("TradeMark " + i)}.Build(),
                        CaseType = data.caseType,
                        ChecklistType = Fixture.Short(),
                        ChecklistDesc = Fixture.String("checklist" + i)
                    }.Build().In(Db);
                }

                var result = f.Subject.GetPagedResults(Db.Set<ValidChecklist>(),
                                                       new CommonQueryParameters {SortBy = "PropertyType", SortDir = "asc", Skip = 2, Take = 7});
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();
                Assert.Equal(7, results.Length);
                Assert.Equal(Db.Set<ValidChecklist>().OrderBy(x => x.PropertyType.Name).Skip(2).Take(7).First().PropertyType.Name, results[0].PropertyType);
            }
        }

        public class SearchValidChecklist : FactBase
        {
            [Fact]
            public void SearchBasedOnAllCountries()
            {
                var f = new ValidChecklistControllerFixture(Db);
                f.GetChecklists();
                var searchCriteria = new ValidCombinationSearchCriteria();

                var result = f.Subject.SearchValidChecklist(searchCriteria);
                Assert.Equal(5, result.Count());
            }

            [Fact]
            public void SearchBasedOnAllParameters()
            {
                var f = new ValidChecklistControllerFixture(Db);
                var data = f.GetChecklists();
                var searchCriteria = new ValidCombinationSearchCriteria
                {
                    PropertyType = "T",
                    Jurisdictions = new List<string> {"IN"},
                    CaseType = "I",
                    Checklist = data.checklistTypeId
                };

                var result = f.Subject.SearchValidChecklist(searchCriteria);
                Assert.Equal(1, result.Count());
                Assert.Contains(data.checklist3, result);
            }

            [Fact]
            public void SearchBasedOnCaseType()
            {
                var f = new ValidChecklistControllerFixture(Db);
                var data = f.GetChecklists();
                var searchCriteria = new ValidCombinationSearchCriteria {CaseType = "I"};

                var result = f.Subject.SearchValidChecklist(searchCriteria);
                Assert.Equal(1, result.Count());
                Assert.Contains(data.checklist3, result);
            }

            [Fact]
            public void SearchBasedOnMultipleCountries()
            {
                var f = new ValidChecklistControllerFixture(Db);
                var data = f.GetChecklists();
                var searchCriteria = new ValidCombinationSearchCriteria {Jurisdictions = new List<string> {"GB", "US"}};

                var result = f.Subject.SearchValidChecklist(searchCriteria);
                Assert.Equal(2, result.Count());
                Assert.Contains(data.checklist1, result);
                Assert.Contains(data.checklist2, result);
            }

            [Fact]
            public void SearchBasedOnPropertyType()
            {
                var f = new ValidChecklistControllerFixture(Db);
                var data = f.GetChecklists();
                var searchCriteria = new ValidCombinationSearchCriteria {PropertyType = "P"};

                var result = f.Subject.SearchValidChecklist(searchCriteria);
                Assert.Equal(4, result.Count());
                Assert.Contains(data.checklist, result);
                Assert.Contains(data.checklist1, result);
                Assert.Contains(data.checklist2, result);
                Assert.Contains(data.checklist4, result);
            }
        }

        public class SearchMethod : FactBase
        {
            [Fact]
            public void ShouldReturnSearchInCorrectOrder()
            {
                var filter = new ValidCombinationSearchCriteria();
                var f = new ValidChecklistControllerFixture(Db);
                f.GetChecklists();

                var result = f.Subject.Search(filter);
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();
                var filteredData = Db.Set<ValidChecklist>().OrderBy(c => c.Country.Name).First();
                Assert.Equal(5, results.Length);
                Assert.Equal(filteredData.PropertyType.Name, results[0].PropertyType);
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void ReturnValidChecklistForGivenKeys()
            {
                var f = new ValidChecklistControllerFixture(Db);
                var data = f.GetChecklists();

                var result = (ValidChecklistController.ChecklistSaveDetails) f.Subject.ValidChecklist(
                                                                                                      new ValidChecklistController.ValidChecklistIdentifier(
                                                                                                                                                            data.checklist.CountryId, data.checklist.PropertyTypeId, data.checklist.CaseTypeId,
                                                                                                                                                            data.checklist.ChecklistType));

                Assert.NotNull(result);
                Assert.Equal(data.checklist.CountryId, result.Jurisdictions.First().Code);
                Assert.Equal(data.checklist.PropertyTypeId, result.PropertyType.Code);
                Assert.Equal(data.checklist.CaseTypeId, result.CaseType.Code);
                Assert.Equal(data.checklist.ChecklistType, result.Checklist.Key);
            }

            [Fact]
            public void ThrowsExceptionWhenValidChecklistNotFoundForGivenValues()
            {
                var f = new ValidChecklistControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.ValidChecklist(
                                                                    new ValidChecklistController.ValidChecklistIdentifier("XXX", "YYY", "ZZZ", 0)));

                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class SaveMethod : FactBase
        {
            ValidChecklistController.ChecklistSaveDetails PrepareSave()
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

                return new ValidChecklistController.ChecklistSaveDetails
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
                    Checklist = new ChecklistMatcher {Code = Fixture.Short()},
                    ValidDescription = "New Valid Checklist"
                };
            }

            [Fact]
            public void AddValidChecklistForGivenValues()
            {
                var f = new ValidChecklistControllerFixture(Db);
                f.GetChecklists();
                var input = PrepareSave();

                f.Validator.CheckValidPropertyCombination(input).Returns((ValidationResult) null);

                var result = f.Subject.Save(input);

                var firstChecklist =
                    Db.Set<ValidChecklist>().First(_ => _.CountryId.Contains("CountryId1"));

                Assert.Equal("success", result.Result);
                Assert.Equal(2, ((IEnumerable<ValidChecklistController.ValidChecklistIdentifier>) result.UpdatedKeys).Count());
                Assert.Equal(7, Db.Set<ValidChecklist>().Count());
                Assert.Equal(input.ValidDescription, firstChecklist.ChecklistDescription);
                Assert.Equal(input.ValidDescription, Db.Set<ValidChecklist>().First(_ => _.CountryId.Contains("CountryId2")).ChecklistDescription);
            }

            [Fact]
            public void ReturnsConfirmationValidationResultIfValidCategoryExistForSome()
            {
                var f = new ValidChecklistControllerFixture(Db);
                var data = f.GetChecklists();

                var input = new ValidChecklistController.ChecklistSaveDetails
                {
                    Jurisdictions = new[]
                    {
                        new CountryModel {Code = data.checklist.CountryId, Value = data.checklist.Country.Name},
                        new CountryModel {Code = Fixture.String(), Value = Fixture.String()}
                    },
                    PropertyType = new PropertyType {Code = data.checklist.PropertyTypeId},
                    CaseType = new CaseType {Code = data.checklist.CaseTypeId},
                    Checklist = new ChecklistMatcher {Code = data.checklist.ChecklistType},
                    ValidDescription = Fixture.String("Valid Description")
                };
                f.Validator.CheckValidPropertyCombination(input).Returns((ValidationResult) null);
                f.Validator.DuplicateCombinationValidationResult(null, 0).ReturnsForAnyArgs(new ValidationResult {Result = "confirmation"});

                var result = f.Subject.Save(input);

                Assert.Equal("confirmation", result.Result);
            }

            [Fact]
            public void ReturnsValidationResultIfValidChecklistAlreadyExist()
            {
                var f = new ValidChecklistControllerFixture(Db);
                var data = f.GetChecklists();

                var input = new ValidChecklistController.ChecklistSaveDetails
                {
                    Jurisdictions = new[] {new CountryModel {Code = data.checklist.CountryId, Value = data.checklist.Country.Name}},
                    PropertyType = new PropertyType {Code = data.checklist.PropertyTypeId},
                    CaseType = new CaseType {Code = data.checklist.CaseTypeId},
                    Checklist = new ChecklistMatcher {Code = data.checklist.ChecklistType},
                    ValidDescription = Fixture.String("Valid Description")
                };
                f.Validator.CheckValidPropertyCombination(input).Returns((ValidationResult) null);
                f.Validator.DuplicateCombinationValidationResult(null, 0).ReturnsForAnyArgs(new ValidationResult {Result = "Error"});

                var result = f.Subject.Save(input);

                Assert.Equal("Error", result.Result);
            }

            [Fact]
            public void ReturnsValidationResultIfValidPropertyTypeDoesnotExistForSelectedCombination()
            {
                var f = new ValidChecklistControllerFixture(Db);
                var data = f.GetChecklists();

                var input = new ValidChecklistController.ChecklistSaveDetails
                {
                    Jurisdictions = new[] {new CountryModel {Code = data.checklist.CountryId, Value = data.checklist.Country.Name}},
                    PropertyType = new PropertyType {Code = "P"},
                    CaseType = new CaseType {Code = data.checklist.CaseTypeId},
                    Checklist = new ChecklistMatcher {Code = data.checklist.ChecklistType},
                    ValidDescription = Fixture.String("Valid Description")
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
            public void ThrowsArgumentNullExceptionWhenSaveModelNotPassed()
            {
                var f = new ValidChecklistControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Save(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("saveDetails", exception.Message);
            }
        }

        public class UpdateMethod : FactBase
        {
            ValidChecklistController.ChecklistSaveDetails PrepareUpdate(ValidChecklist validChecklist)
            {
                return new ValidChecklistController.ChecklistSaveDetails
                {
                    Jurisdictions = new[]
                    {
                        new CountryModel
                        {
                            Code = validChecklist.CountryId
                        }
                    },
                    PropertyType = new PropertyType {Code = validChecklist.PropertyTypeId},
                    CaseType = new CaseType {Code = validChecklist.CaseTypeId},
                    Checklist = new ChecklistMatcher {Code = validChecklist.ChecklistType},
                    ValidDescription = "Updated Valid Checklist"
                };
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenSaveModelNotPassed()
            {
                var f = new ValidChecklistControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Update(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("saveDetails", exception.Message);
            }

            [Fact]
            public void UpdateExistingValidChecklist()
            {
                var f = new ValidChecklistControllerFixture(Db);
                var data = f.GetChecklists();
                var modelToUpdate = PrepareUpdate(data.checklist);

                var result = f.Subject.Update(modelToUpdate);
                var validChecklist1 = (ValidChecklist) data.checklist;

                var checklistUpdated = Db.Set<ValidChecklist>()
                                         .First(
                                                _ =>
                                                    _.CountryId == validChecklist1.CountryId &&
                                                    _.PropertyTypeId == validChecklist1.PropertyTypeId &&
                                                    _.CaseTypeId == validChecklist1.CaseTypeId &&
                                                    _.ChecklistType == validChecklist1.ChecklistType);

                Assert.Equal("success", result.Result);
                Assert.Equal(validChecklist1.CountryId, ((ValidChecklistController.ValidChecklistIdentifier) result.UpdatedKeys).CountryId);
                Assert.Equal(validChecklist1.PropertyTypeId, ((ValidChecklistController.ValidChecklistIdentifier) result.UpdatedKeys).PropertyTypeId);
                Assert.Equal(validChecklist1.CaseTypeId, ((ValidChecklistController.ValidChecklistIdentifier) result.UpdatedKeys).CaseTypeId);
                Assert.Equal(validChecklist1.ChecklistType, ((ValidChecklistController.ValidChecklistIdentifier) result.UpdatedKeys).ChecklistId);
                Assert.Equal(modelToUpdate.ValidDescription, checklistUpdated.ChecklistDescription);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeleteValidCategoriesForGivenIdentifiers()
            {
                var f = new ValidChecklistControllerFixture(Db);
                var data = f.GetChecklists();

                var identifiers = new[]
                {
                    new ValidChecklistController.ValidChecklistIdentifier(data.checklist.CountryId,
                                                                          data.checklist.PropertyTypeId, data.checklist.CaseTypeId,
                                                                          data.checklist.ChecklistType),
                    new ValidChecklistController.ValidChecklistIdentifier(data.checklist3.CountryId,
                                                                          data.checklist3.PropertyTypeId, data.checklist3.CaseTypeId,
                                                                          data.checklist3.ChecklistType)
                };

                var result = f.Subject.Delete(identifiers);

                Assert.False(result.HasError);
                Assert.False(result.InUseIds.Any());
                Assert.Equal(3, Db.Set<ValidChecklist>().Count());
            }

            [Fact]
            public void ReturnsErrorWithListOfIdsIfValidCombinationIsInUse()
            {
                var f = new ValidChecklistControllerFixture(Db);
                var data = f.GetChecklists();

                var @case = new CaseBuilder
                {
                    CountryCode = data.checklist.CountryId,
                    PropertyType = new PropertyTypeBuilder {Id = data.checklist.PropertyTypeId}.Build(),
                    CaseType = new CaseTypeBuilder {Id = data.checklist.CaseTypeId}.Build()
                }.Build().In(Db);
                @case.CaseChecklists.Add(new CaseChecklist(data.checklist.ChecklistType, @case.Id, 0).In(Db));

                var identifiers = new[]
                {
                    new ValidChecklistController.ValidChecklistIdentifier(data.checklist.CountryId,
                                                                          data.checklist.PropertyTypeId, data.checklist.CaseTypeId,
                                                                          data.checklist.ChecklistType)
                };

                var result = f.Subject.Delete(identifiers);

                Assert.True(result.HasError);
                Assert.True(result.InUseIds.Any());
                Assert.Equal(5, Db.Set<ValidChecklist>().Count());
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenCollectionOfValidIdentifiersNotPassed()
            {
                var f = new ValidChecklistControllerFixture(Db);

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
                var f = new ValidChecklistControllerFixture(Db);
                f.GetChecklists();

                var toCountries = new[] {new CountryModel {Code = "AU"}, new CountryModel {Code = "IT"}};

                f.Subject.Copy(new CountryModel {Code = "US"}, toCountries);

                var validChecklistsForAmerica = Db.Set<ValidChecklist>()
                                                  .Where(_ => _.CountryId == "US");

                foreach (var vc in validChecklistsForAmerica)
                {
                    var validChecklist = vc;

                    Assert.NotNull(
                                   Db.Set<ValidChecklist>()
                                     .Where(_ => _.CountryId == "AU" && _.PropertyTypeId == validChecklist.PropertyTypeId
                                                                     && _.CaseTypeId == validChecklist.CaseTypeId && _.ChecklistType == validChecklist.ChecklistType));
                    Assert.NotNull(
                                   Db.Set<ValidChecklist>()
                                     .Where(_ => _.CountryId == "IT" && _.PropertyTypeId == validChecklist.PropertyTypeId
                                                                     && _.CaseTypeId == validChecklist.CaseTypeId && _.ChecklistType == validChecklist.ChecklistType));
                }
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenFromCountryNotPassed()
            {
                var f = new ValidChecklistControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Copy(null, new[] {new CountryModel {Code = "GB"}}));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("fromJurisdiction", exception.Message);
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenToCountriesNotPassed()
            {
                var f = new ValidChecklistControllerFixture(Db);

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
                var f = new ValidChecklistControllerFixture(Db);
                f.GetChecklists();

                f.Subject
                 .ExportToExcel(new ValidCombinationSearchCriteria());

                var totalInDb = Db.Set<ValidChecklist>().Count();

                f.Exporter.Received(1).Export(Arg.Is<PagedResults>(x => x.Data.Count() == totalInDb), "Search Result.xlsx");
            }
        }
    }
}