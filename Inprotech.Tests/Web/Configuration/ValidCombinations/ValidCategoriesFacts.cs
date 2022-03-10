using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web.Configuration.ValidCombinations;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.ValidCombinations
{
    public class ValidCategoriesFacts
    {
        public class ValidCategoriesFixture : IFixture<ValidCategories>
        {
            readonly InMemoryDbContext _db;

            public ValidCategoriesFixture(InMemoryDbContext db)
            {
                _db = db;
                Validator = Substitute.For<IValidCombinationValidator>();
                MultipleClassAppCountries = Substitute.For<IMultipleClassApplicationCountries>();

                Subject = new ValidCategories(_db, Validator, MultipleClassAppCountries);
            }

            public IValidCombinationValidator Validator { get; }
            public IMultipleClassApplicationCountries MultipleClassAppCountries { get; set; }

            public ValidCategories Subject { get; }

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

        public class GetMethod : FactBase
        {
            [Fact]
            public void ReturnsNullWhenValidCategoryNotFoundForGivenCriteria()
            {
                var f = new ValidCategoriesFixture(Db);

                Assert.Null(f.Subject.ValidCaseCategory(new ValidCategoryIdentifier("XXX", "YYY", "ZZZ", "AAA")));
            }

            [Fact]
            public void ReturnValidCategoryForGivenKeys()
            {
                var f = new ValidCategoriesFixture(Db);
                var data = f.SetupCategories();

                var result = f.Subject.ValidCaseCategory(new ValidCategoryIdentifier(
                                                                                     data.validCategory1.CountryId, data.validCategory1.PropertyTypeId, data.validCategory1.CaseTypeId, data.validCategory1.CaseCategoryId));

                Assert.NotNull(result);
                Assert.Equal(data.validCategory1.CountryId, result.Jurisdictions.First().Code);
                Assert.Equal(data.validCategory1.PropertyTypeId, result.PropertyType.Code);
                Assert.Equal(data.validCategory1.CaseTypeId, result.CaseType.Code);
                Assert.Equal(data.validCategory1.CaseCategoryId, result.CaseCategory.Code);
            }
        }

        public class Save : FactBase
        {
            CaseCategorySaveDetails PrepareSave()
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

                return new CaseCategorySaveDetails
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
                    CaseCategory = new CaseCategory {Code = Fixture.String("CategoryId")},
                    ValidDescription = "New Valid Category",
                    MultiClassPropertyApp = true,
                    PropertyEvent = new Event {Key = 1}
                };
            }

            [Fact]
            public void AddValidCategoryForGivenValues()
            {
                var f = new ValidCategoriesFixture(Db);
                f.SetupCategories();
                var input = PrepareSave();

                f.Validator.CheckValidPropertyCombination(input).Returns((ValidationResult) null);
                f.MultipleClassAppCountries.Resolve().Returns(new[] { input.Jurisdictions.First().Code, "AD", "AF" }.AsQueryable<string>());

                var result = f.Subject.Save(input);

                var firstCategory =
                    Db.Set<ValidCategory>().First(_ => _.CountryId.Contains("CountryId1"));

                Assert.Equal("success", result.Result);
                Assert.Equal(2, ((IEnumerable<ValidCategoryIdentifier>) result.UpdatedKeys).Count());
                Assert.Equal(7, Db.Set<ValidCategory>().Count());
                Assert.Equal(input.ValidDescription, firstCategory.CaseCategoryDesc);
                Assert.Equal(input.ValidDescription, Db.Set<ValidCategory>().First(_ => _.CountryId.Contains("CountryId2")).CaseCategoryDesc);
                Assert.Equal(input.PropertyEvent.Key, firstCategory.PropertyEventNo);
                Assert.Null(firstCategory.MultiClassPropertyApp);
            }

            [Fact]
            public void ReturnsConfirmationValidationResultIfValidCategoryExistForSome()
            {
                var f = new ValidCategoriesFixture(Db);
                var data = f.SetupCategories();

                var input = new CaseCategorySaveDetails
                {
                    Jurisdictions = new[]
                    {
                        new CountryModel {Code = data.validCategory1.CountryId, Value = data.validCategory1.Country.Name},
                        new CountryModel {Code = Fixture.String(), Value = Fixture.String()}
                    },
                    PropertyType = new PropertyType {Code = data.validCategory1.PropertyTypeId},
                    CaseType = new CaseType {Code = data.validCategory1.CaseTypeId},
                    CaseCategory = new CaseCategory {Code = data.validCategory1.CaseCategoryId},
                    ValidDescription = Fixture.String("Valid Description")
                };
                f.Validator.CheckValidPropertyCombination(input).Returns((ValidationResult) null);
                f.Validator.DuplicateCombinationValidationResult(null, 0).ReturnsForAnyArgs(new ValidationResult {Result = "confirmation"});

                var result = f.Subject.Save(input);

                Assert.Equal("confirmation", result.Result);
            }

            [Fact]
            public void ReturnsValidationResultIfValidCategoryAlreadyExist()
            {
                var f = new ValidCategoriesFixture(Db);
                var data = f.SetupCategories();

                var input = new CaseCategorySaveDetails
                {
                    Jurisdictions = new[] {new CountryModel {Code = data.validCategory1.CountryId, Value = data.validCategory1.Country.Name}},
                    PropertyType = new PropertyType {Code = data.validCategory1.PropertyTypeId},
                    CaseType = new CaseType {Code = data.validCategory1.CaseTypeId},
                    CaseCategory = new CaseCategory {Code = data.validCategory1.CaseCategoryId},
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
                var f = new ValidCategoriesFixture(Db);
                var data = f.SetupCategories();

                var input = new CaseCategorySaveDetails
                {
                    Jurisdictions = new[] {new CountryModel {Code = data.validCategory1.CountryId, Value = data.validCategory1.Country.Name}},
                    PropertyType = new PropertyType {Code = "P"},
                    CaseType = new CaseType {Code = data.validCategory1.CaseTypeId},
                    CaseCategory = new CaseCategory {Code = data.validCategory1.CaseCategoryId},
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
                var f = new ValidCategoriesFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Save(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("saveDetails", exception.Message);
            }
        }

        public class UpdateMethod : FactBase
        {
            CaseCategorySaveDetails PrepareUpdate(ValidCategory validCategory)
            {
                return new CaseCategorySaveDetails
                {
                    Jurisdictions = new[]
                    {
                        new CountryModel
                        {
                            Code = validCategory.CountryId
                        }
                    },
                    PropertyType = new PropertyType {Code = validCategory.PropertyTypeId},
                    CaseType = new CaseType {Code = validCategory.CaseTypeId},
                    CaseCategory = new CaseCategory {Code = validCategory.CaseCategoryId},
                    ValidDescription = "Updated Valid Category",
                    MultiClassPropertyApp = true,
                    PropertyEvent = new Event {Key = 1}
                };
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenSaveModelNotPassed()
            {
                var f = new ValidCategoriesFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Update(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("saveDetails", exception.Message);
            }

            [Fact]
            public void UpdateExistingValidCategory()
            {
                var f = new ValidCategoriesFixture(Db);
                var data = f.SetupCategories();
                var modelToUpdate = PrepareUpdate(data.validCategory1);

                var result = f.Subject.Update(modelToUpdate);
                var validCategory1 = (ValidCategory) data.validCategory1;

                var categoryUpdated = Db.Set<ValidCategory>()
                                        .First(
                                               _ =>
                                                   _.CountryId == validCategory1.CountryId &&
                                                   _.PropertyTypeId == validCategory1.PropertyTypeId &&
                                                   _.CaseTypeId == validCategory1.CaseTypeId &&
                                                   _.CaseCategoryId == validCategory1.CaseCategoryId);

                Assert.Equal("success", result.Result);
                Assert.Equal(validCategory1.CountryId, ((ValidCategoryIdentifier) result.UpdatedKeys).CountryId);
                Assert.Equal(validCategory1.PropertyTypeId, ((ValidCategoryIdentifier) result.UpdatedKeys).PropertyTypeId);
                Assert.Equal(validCategory1.CaseTypeId, ((ValidCategoryIdentifier) result.UpdatedKeys).CaseTypeId);
                Assert.Equal(validCategory1.CaseCategoryId, ((ValidCategoryIdentifier) result.UpdatedKeys).CategoryId);
                Assert.Equal(modelToUpdate.ValidDescription, categoryUpdated.CaseCategoryDesc);
                Assert.Equal(modelToUpdate.MultiClassPropertyApp, categoryUpdated.MultiClassPropertyApp);
                Assert.Equal(modelToUpdate.PropertyEvent.Key, categoryUpdated.PropertyEventNo);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Theory]
            [InlineData("Case")]
            [InlineData("ValidBasisEx")]
            [InlineData("ValidSubType")]
            public void ReturnsErrorWithListOfIdsIfValidCombinationIsInUse(string entityName)
            {
                var f = new ValidCategoriesFixture(Db);
                var data = f.SetupCategories();

                InitializeDataForInUseTests(entityName, data);

                var identifiers = new[]
                {
                    new ValidCategoryIdentifier(data.validCategory1.CountryId,
                                                data.validCategory1.PropertyTypeId, data.validCategory1.CaseTypeId,
                                                data.validCategory1.CaseCategoryId)
                };
                var result = f.Subject.Delete(identifiers);

                Assert.True(result.HasError);
                Assert.True(result.InUseIds.Any());
                Assert.Equal(5, Db.Set<ValidCategory>().Count());
            }

            void InitializeDataForInUseTests(string entityName, dynamic data)
            {
                var country = new CountryBuilder {Id = data.validCategory1.CountryId}.Build();
                var propertyType = new PropertyTypeBuilder {Id = data.validCategory1.PropertyTypeId}.Build();
                var caseCategory = new CaseCategoryBuilder {CaseCategoryId = data.validCategory1.CaseCategoryId, CaseTypeId = data.validCategory1.CaseTypeId}.Build();
                var caseType = new CaseTypeBuilder {Id = data.validCategory1.CaseTypeId}.Build();
                switch (entityName)
                {
                    case "Case":
                        var @case = new CaseBuilder
                        {
                            CountryCode = country.Id,
                            PropertyType = propertyType,
                            CaseType = caseType
                        }.Build().In(Db);
                        @case.SetCaseCategory(new CaseCategoryBuilder {CaseCategoryId = data.validCategory1.CaseCategoryId}.Build());
                        break;
                    case "ValidBasisEx":
                        var validBasis = new ValidBasisBuilder
                        {
                            Country = country,
                            PropertyType = propertyType
                        }.Build().In(Db);
                        new ValidBasisExBuilder
                        {
                            ValidBasis = validBasis,
                            CaseCategory = caseCategory,
                            CaseType = caseType
                        }.Build().In(Db);
                        break;
                    case "ValidSubType":
                        new ValidSubTypeBuilder
                        {
                            Country = country,
                            PropertyType = propertyType,
                            CaseType = new CaseTypeBuilder {Id = data.validCategory1.CaseTypeId}.Build(),
                            ValidCategory = data.validCategory1
                        }.Build().In(Db);
                        break;
                }
            }

            [Fact]
            public void DeleteValidCategoriesForGivenIdentifiers()
            {
                var f = new ValidCategoriesFixture(Db);
                var data = f.SetupCategories();

                var identifiers = new[]
                {
                    new ValidCategoryIdentifier(data.validCategory1.CountryId,
                                                data.validCategory1.PropertyTypeId, data.validCategory1.CaseTypeId,
                                                data.validCategory1.CaseCategoryId),
                    new ValidCategoryIdentifier(data.validCategory3.CountryId,
                                                data.validCategory3.PropertyTypeId, data.validCategory3.CaseTypeId,
                                                data.validCategory3.CaseCategoryId)
                };

                var result = f.Subject.Delete(identifiers);

                Assert.False(result.HasError);
                Assert.False(result.InUseIds.Any());
                Assert.Equal(3, Db.Set<ValidCategory>().Count());
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenCollectionOfValidIdentifiersNotPassed()
            {
                var f = new ValidCategoriesFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Delete(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("deleteRequestModel", exception.Message);
            }
        }
    }
}