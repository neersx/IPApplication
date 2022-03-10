using System;
using System.Collections.Generic;
using System.Globalization;
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
    public class ValidRelationshipControllerFacts
    {
        public class ValidRelationshipControllerFixture : IFixture<ValidRelationshipController>
        {
            readonly InMemoryDbContext _db;

            public ValidRelationshipControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                Validator = Substitute.For<IValidCombinationValidator>();

                Exporter = Substitute.For<ISimpleExcelExporter>();

                Subject = new ValidRelationshipController(_db, Validator, Exporter);
            }

            public IValidCombinationValidator Validator { get; }
            public ISimpleExcelExporter Exporter { get; }
            public ValidRelationshipController Subject { get; }

            public dynamic SetupRelationship()
            {
                new ValidProperty {CountryId = "NZ", PropertyTypeId = "T", PropertyName = "Valid Property"}.In(_db);

                var validRelationship1 = new ValidRelationshipBuilder
                {
                    Country = new CountryBuilder {Id = "NZ", Name = "New Zealand"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "D", Name = "Design"}.Build(),
                    Relation = new CaseRelationBuilder {RelationshipCode = "AGR", RelationshipDescription = "Agreement"}.Build().In(_db)
                }.Build().In(_db);

                var validRelationship2 = new ValidRelationshipBuilder
                {
                    Country = new CountryBuilder {Id = "GB", Name = "United Kingdom"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "P", Name = "Patent"}.Build(),
                    Relation = new CaseRelationBuilder {RelationshipCode = "ADD", RelationshipDescription = "Patent Of Addition To"}.Build()
                }.Build().In(_db);

                var validRelationship3 = new ValidRelationshipBuilder
                {
                    Country = new CountryBuilder {Id = "US", Name = "United States of America"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "D", Name = "Design"}.Build(),
                    Relation = new CaseRelationBuilder {RelationshipCode = "AGR", RelationshipDescription = "Agreement"}.Build()
                }.Build().In(_db);

                var validRelationship4 = new ValidRelationshipBuilder
                {
                    Country = new CountryBuilder {Id = "US", Name = "United States of America"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "ND", Name = "Domain Name"}.Build(),
                    Relation = new CaseRelationBuilder {RelationshipCode = "BAS", RelationshipDescription = "Basic Application"}.Build()
                }.Build().In(_db);

                var validRelationship5 = new ValidRelationshipBuilder
                {
                    Country = new CountryBuilder {Id = "IN", Name = "India"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "U", Name = "Utility"}.Build(),
                    Relation = new CaseRelationBuilder {RelationshipCode = "DIV", RelationshipDescription = "Divisional"}.Build().In(_db)
                }.Build().In(_db);

                return new
                {
                    validRelationship1,
                    validRelationship2,
                    validRelationship3,
                    validRelationship4,
                    validRelationship5
                };
            }
        }

        public class GetPagedResultsMethod : FactBase
        {
            [Fact]
            public void OrdersByDescription()
            {
                var f = new ValidRelationshipControllerFixture(Db);
                f.SetupRelationship();

                var result = f.Subject.GetPagedResults(Db.Set<ValidRelationship>(),
                                                       new CommonQueryParameters {SortBy = "PropertyType", SortDir = "asc", Skip = 0, Take = 10});

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(5, results.Length);
                Assert.Equal(Db.Set<ValidRelationship>().OrderBy(c => c.PropertyType.Name).First().Relationship.Description, results[0].Relationship);
            }

            [Fact]
            public void SkipsAndTakes()
            {
                var f = new ValidRelationshipControllerFixture(Db);
                for (var i = 0; i < 10; i++)
                {
                    new ValidRelationshipBuilder
                    {
                        Relation = new CaseRelationBuilder
                        {
                            RelationshipCode = i.ToString(CultureInfo.InvariantCulture),
                            RelationshipDescription = Fixture.String("Name" + i)
                        }.Build().In(Db)
                    }.Build().In(Db);
                }

                var result = f.Subject.GetPagedResults(Db.Set<ValidRelationship>(),
                                                       new CommonQueryParameters {SortBy = "relationship", SortDir = "asc", Skip = 3, Take = 7});
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(7, results.Length);
                Assert.Equal(Db.Set<ValidRelationship>().First(_ => _.Relationship.Relationship == "3").Relationship.Description, results[0].Relationship);
            }
        }

        public class SearchValidRelationship : FactBase
        {
            [Fact]
            public void SearchAllRelationship()
            {
                var searchCriteria = new ValidCombinationSearchCriteria();
                var f = new ValidRelationshipControllerFixture(Db);
                f.SetupRelationship();

                var result = f.Subject.SearchValidRelationships(searchCriteria);
                Assert.Equal(Db.Set<ValidRelationship>().Count(), result.Count());
            }

            [Fact]
            public void SearchBasedOnAllFilter()
            {
                var searchCriteria = new ValidCombinationSearchCriteria
                {
                    PropertyType = "U",
                    Relationship = "DIV",
                    Jurisdictions = new List<string> {"IN"}
                };
                var f = new ValidRelationshipControllerFixture(Db);
                f.SetupRelationship();

                var result = f.Subject.SearchValidRelationships(searchCriteria);

                var filteredRelationship =
                    Db.Set<ValidRelationship>()
                      .Where(c => c.PropertyType.Code == "U" && c.Country.Id == "IN" && c.RelationshipCode == "DIV");

                Assert.Equal(filteredRelationship.Count(), result.Count());
                Assert.Contains(filteredRelationship.FirstOrDefault(), result);
            }

            [Fact]
            public void SearchBasedOnMultipleCountries()
            {
                var searchCriteria = new ValidCombinationSearchCriteria {Jurisdictions = new List<string> {"GB", "US"}};
                var f = new ValidRelationshipControllerFixture(Db);
                f.SetupRelationship();

                var result = f.Subject.SearchValidRelationships(searchCriteria);
                var filteredRelationship = Db.Set<ValidRelationship>().Where(c => c.Country.Id == "GB" || c.Country.Id == "US");

                Assert.Equal(filteredRelationship.Count(), result.Count());

                foreach (var validRelationship in filteredRelationship) Assert.Contains(validRelationship, result);
            }

            [Fact]
            public void SearchBasedOnProperty()
            {
                var searchCriteria = new ValidCombinationSearchCriteria {PropertyType = "P"};
                var f = new ValidRelationshipControllerFixture(Db);
                f.SetupRelationship();

                var result = f.Subject.SearchValidRelationships(searchCriteria);
                var filteredRelationship = Db.Set<ValidRelationship>().Where(c => c.PropertyTypeId == "P");
                Assert.Equal(filteredRelationship.Count(), result.Count());
                Assert.Contains(filteredRelationship.FirstOrDefault(), result);
            }

            [Fact]
            public void SearchBasedOnRelationship()
            {
                var searchCriteria = new ValidCombinationSearchCriteria {Relationship = "DIV"};
                var f = new ValidRelationshipControllerFixture(Db);
                f.SetupRelationship();

                var result = f.Subject.SearchValidRelationships(searchCriteria);
                var filteredRelationship = Db.Set<ValidRelationship>().Where(c => c.RelationshipCode == "DIV");
                Assert.Equal(filteredRelationship.Count(), result.Count());
                Assert.Contains(filteredRelationship.FirstOrDefault(), result);
            }
        }

        public class SearchMethod : FactBase
        {
            [Fact]
            public void ShouldReturnSearchInCorrectOrder()
            {
                var filter = new ValidCombinationSearchCriteria();
                var f = new ValidRelationshipControllerFixture(Db);
                f.SetupRelationship();

                var result = f.Subject.Search(filter);
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();
                Assert.Equal(5, results.Length);
                Assert.Equal(Db.Set<ValidRelationship>().OrderBy(c => c.Country.Name).First().Relationship.Description, results[0].Relationship);
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void ReturnValidRelationshipForGivenKeys()
            {
                var f = new ValidRelationshipControllerFixture(Db);
                var data = f.SetupRelationship();

                var result = (ValidRelationshipController.RelationshipSaveDetails) f.Subject.ValidRelationship(
                                                                                                               new ValidRelationshipController.ValidRelationshipIdentifier(
                                                                                                                                                                           data.validRelationship1.CountryId, data.validRelationship1.PropertyTypeId, data.validRelationship1.RelationshipCode));

                Assert.NotNull(result);
                Assert.Equal(data.validRelationship1.CountryId, result.Jurisdictions.First().Code);
                Assert.Equal(data.validRelationship1.PropertyTypeId, result.PropertyType.Code);
                Assert.Equal(data.validRelationship1.RelationshipCode, result.Relationship.Key);
            }

            [Fact]
            public void ThrowsExceptionWhenValidRelationshipNotFoundForGivenValues()
            {
                var f = new ValidRelationshipControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.ValidRelationship(
                                                                       new ValidRelationshipController.ValidRelationshipIdentifier("XXX", "YYY", "ZZZ")));

                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class SaveMethod : FactBase
        {
            ValidRelationshipController.RelationshipSaveDetails PrepareSave()
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

                return new ValidRelationshipController.RelationshipSaveDetails
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
                    Relationship = new Relationship {Code = Fixture.String("RelationshipId")},
                    RecipRelationship = new Relationship {Code = Fixture.String("RecipRelationshipId")}
                };
            }

            [Fact]
            public void AddValidRelationshipForGivenValues()
            {
                var f = new ValidRelationshipControllerFixture(Db);
                f.SetupRelationship();
                var input = PrepareSave();

                f.Validator.CheckValidPropertyCombination(input).Returns((ValidationResult) null);

                var result = f.Subject.Save(input);

                var firstRelationship =
                    Db.Set<ValidRelationship>().First(_ => _.CountryId.Contains("CountryId1"));

                Assert.Equal("success", result.Result);
                Assert.Equal(2, ((IEnumerable<ValidRelationshipController.ValidRelationshipIdentifier>) result.UpdatedKeys).Count());
                Assert.Equal(7, Db.Set<ValidRelationship>().Count());
                Assert.Equal(input.RecipRelationship.Key, Convert.ToString(firstRelationship.ReciprocalRelationshipCode));
                Assert.Equal(input.RecipRelationship.Key, Db.Set<ValidRelationship>().First(_ => _.CountryId.Contains("CountryId2")).ReciprocalRelationshipCode);
            }

            [Fact]
            public void ReturnsConfirmationValidationResultIfValidCategoryExistForSome()
            {
                var f = new ValidRelationshipControllerFixture(Db);
                var data = f.SetupRelationship();

                var input = new ValidRelationshipController.RelationshipSaveDetails
                {
                    Jurisdictions = new[]
                    {
                        new CountryModel {Code = data.validRelationship1.CountryId, Value = data.validRelationship1.Country.Name},
                        new CountryModel {Code = Fixture.String(), Value = Fixture.String()}
                    },
                    PropertyType = new PropertyType {Code = data.validRelationship1.PropertyTypeId},
                    Relationship = new Relationship {Code = data.validRelationship1.RelationshipCode},
                    RecipRelationship = new Relationship {Code = Fixture.String("RecipRelationship")}
                };
                f.Validator.CheckValidPropertyCombination(input).Returns((ValidationResult) null);
                f.Validator.DuplicateCombinationValidationResult(null, 0).ReturnsForAnyArgs(new ValidationResult {Result = "confirmation"});

                var result = f.Subject.Save(input);

                Assert.Equal("confirmation", result.Result);
            }

            [Fact]
            public void ReturnsValidationResultIfValidPropertyTypeDoesnotExistForSelectedCombination()
            {
                var f = new ValidRelationshipControllerFixture(Db);
                var data = f.SetupRelationship();

                var input = new ValidRelationshipController.RelationshipSaveDetails
                {
                    Jurisdictions = new[] {new CountryModel {Code = data.validRelationship1.CountryId, Value = data.validRelationship1.Country.Name}},
                    PropertyType = new PropertyType {Code = "P"},
                    Relationship = new Relationship {Code = data.validRelationship1.RelationshipCode},
                    RecipRelationship = new Relationship {Code = Fixture.String("RecipRelationship")}
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
            public void ReturnsValidationResultIfValidRelationshipAlreadyExist()
            {
                var f = new ValidRelationshipControllerFixture(Db);
                var data = f.SetupRelationship();

                var input = new ValidRelationshipController.RelationshipSaveDetails
                {
                    Jurisdictions = new[] {new CountryModel {Code = data.validRelationship1.CountryId, Value = data.validRelationship1.Country.Name}},
                    PropertyType = new PropertyType {Code = data.validRelationship1.PropertyTypeId},
                    Relationship = new Relationship {Code = data.validRelationship1.RelationshipCode},
                    RecipRelationship = new Relationship {Code = Fixture.String("RecipRelationship")}
                };
                f.Validator.CheckValidPropertyCombination(input).Returns((ValidationResult) null);
                f.Validator.DuplicateCombinationValidationResult(null, 0).ReturnsForAnyArgs(new ValidationResult {Result = "Error"});

                var result = f.Subject.Save(input);

                Assert.Equal("Error", result.Result);
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenSaveModelNotPassed()
            {
                var f = new ValidRelationshipControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Save(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("saveDetails", exception.Message);
            }
        }

        public class UpdateMethod : FactBase
        {
            ValidRelationshipController.RelationshipSaveDetails PrepareUpdate(ValidRelationship validRelationship)
            {
                return new ValidRelationshipController.RelationshipSaveDetails
                {
                    Jurisdictions = new[]
                    {
                        new CountryModel
                        {
                            Code = validRelationship.CountryId
                        }
                    },
                    PropertyType = new PropertyType {Code = validRelationship.PropertyTypeId},
                    Relationship = new Relationship {Code = validRelationship.RelationshipCode},
                    RecipRelationship = new Relationship {Code = Fixture.String("RecipRelationship")}
                };
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenSaveModelNotPassed()
            {
                var f = new ValidRelationshipControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Update(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("saveDetails", exception.Message);
            }

            [Fact]
            public void UpdateExistingValidRelationship()
            {
                var f = new ValidRelationshipControllerFixture(Db);
                var data = f.SetupRelationship();
                var modelToUpdate = PrepareUpdate(data.validRelationship1);

                var result = f.Subject.Update(modelToUpdate);
                var validRelationship1 = (ValidRelationship) data.validRelationship1;

                var relationshipUpdated = Db.Set<ValidRelationship>()
                                            .First(
                                                   _ =>
                                                       _.CountryId == validRelationship1.CountryId &&
                                                       _.PropertyTypeId == validRelationship1.PropertyTypeId &&
                                                       _.RelationshipCode == validRelationship1.RelationshipCode);

                Assert.Equal("success", result.Result);
                Assert.Equal(validRelationship1.CountryId, ((ValidRelationshipController.ValidRelationshipIdentifier) result.UpdatedKeys).CountryId);
                Assert.Equal(validRelationship1.PropertyTypeId, ((ValidRelationshipController.ValidRelationshipIdentifier) result.UpdatedKeys).PropertyTypeId);
                Assert.Equal(validRelationship1.RelationshipCode, ((ValidRelationshipController.ValidRelationshipIdentifier) result.UpdatedKeys).RelationshipCode);
                Assert.Equal(modelToUpdate.RecipRelationship.Key, relationshipUpdated.ReciprocalRelationshipCode);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeleteValidRelationshipForGivenIdentifiers()
            {
                var f = new ValidRelationshipControllerFixture(Db);
                var data = f.SetupRelationship();

                var identifiers = new[]
                {
                    new ValidRelationshipController.ValidRelationshipIdentifier(data.validRelationship1.CountryId,
                                                                                data.validRelationship1.PropertyTypeId, data.validRelationship1.RelationshipCode),
                    new ValidRelationshipController.ValidRelationshipIdentifier(data.validRelationship3.CountryId,
                                                                                data.validRelationship3.PropertyTypeId, data.validRelationship3.RelationshipCode)
                };

                var result = f.Subject.Delete(identifiers);

                Assert.False(result.HasError);
                Assert.False(result.InUseIds.Any());
                Assert.Equal(3, Db.Set<ValidRelationship>().Count());
            }

            [Fact]
            public void ReturnsErrorWithListOfIdsIfValidCombinationIsInUse()
            {
                var f = new ValidRelationshipControllerFixture(Db);
                var data = f.SetupRelationship();
                var @case = new CaseBuilder
                {
                    CountryCode = data.validRelationship1.CountryId,
                    PropertyType = new PropertyTypeBuilder {Id = data.validRelationship1.PropertyTypeId}.Build()
                }.Build().In(Db);

                @case.RelatedCases.Add(new RelatedCase(@case.Id, data.validRelationship1.RelationshipCode));

                var identifiers = new[]
                {
                    new ValidRelationshipController.ValidRelationshipIdentifier(data.validRelationship1.CountryId,
                                                                                data.validRelationship1.PropertyTypeId, data.validRelationship1.RelationshipCode)
                };
                var result = f.Subject.Delete(identifiers);

                Assert.True(result.HasError);
                Assert.True(result.InUseIds.Any());
                Assert.Equal(5, Db.Set<ValidRelationship>().Count());
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenCollectionOfValidIdentifiersNotPassed()
            {
                var f = new ValidRelationshipControllerFixture(Db);

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
                var f = new ValidRelationshipControllerFixture(Db);
                f.SetupRelationship();

                var toCountries = new[] {new CountryModel {Code = "AUT"}, new CountryModel {Code = "IT"}};

                f.Subject.Copy(new CountryModel {Code = "US"}, toCountries);

                var validRelationshipsForAmerica = Db.Set<ValidRelationship>()
                                                     .Where(_ => _.CountryId == "US");

                foreach (var vr in validRelationshipsForAmerica)
                {
                    var validRelationship = vr;

                    Assert.NotNull(
                                   Db.Set<ValidRelationship>()
                                     .Where(_ => _.CountryId == "AUT" && _.PropertyTypeId == validRelationship.PropertyTypeId
                                                                      && _.RelationshipCode == validRelationship.RelationshipCode));
                    Assert.NotNull(
                                   Db.Set<ValidRelationship>()
                                     .Where(_ => _.CountryId == "IT" && _.PropertyTypeId == validRelationship.PropertyTypeId
                                                                     && _.RelationshipCode == validRelationship.RelationshipCode));
                }
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenFromCountryNotPassed()
            {
                var f = new ValidRelationshipControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Copy(null, new[] {new CountryModel {Code = "GB"}}));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("fromJurisdiction", exception.Message);
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenToCountriesNotPassed()
            {
                var f = new ValidRelationshipControllerFixture(Db);

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
                var fixture = new ValidRelationshipControllerFixture(Db);
                fixture.SetupRelationship();

                fixture
                    .Subject
                    .ExportToExcel(new ValidCombinationSearchCriteria());

                var totalInDb = Db.Set<ValidRelationship>().Count();

                fixture.Exporter.Received(1).Export(Arg.Is<PagedResults>(x => x.Data.Count() == totalInDb), "Search Result.xlsx");
            }
        }
    }
}