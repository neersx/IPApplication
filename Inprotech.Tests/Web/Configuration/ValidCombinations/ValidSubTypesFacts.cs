using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web.Configuration.ValidCombinations;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;
using CaseCategory = Inprotech.Web.Picklists.CaseCategory;
using CaseType = Inprotech.Web.Picklists.CaseType;
using PropertyType = Inprotech.Web.Picklists.PropertyType;
using SubType = Inprotech.Web.Picklists.SubType;

namespace Inprotech.Tests.Web.Configuration.ValidCombinations
{
    public class ValidSubTypesFacts
    {
        public class ValidSubTypesFixture : IFixture<ValidSubTypes>
        {
            readonly InMemoryDbContext _db;

            public ValidSubTypesFixture(InMemoryDbContext db)
            {
                _db = db;
                Validator = Substitute.For<IValidCombinationValidator>();

                Subject = new ValidSubTypes(_db, Validator);
            }

            public IValidCombinationValidator Validator { get; set; }
            public ValidSubTypes Subject { get; }

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

        public class GetMethod : FactBase
        {
            [Fact]
            public void ReturnsNullWhenValidSubTypeNotFoundForGivenCriteria()
            {
                var f = new ValidSubTypesFixture(Db);

                Assert.Null(f.Subject.GetValidSubType(new ValidSubTypeIdentifier("XXX", "YYY", "ZZZ", "AAA", "ZZ")));
            }

            [Fact]
            public void ReturnValidSubTypeForGivenCountryPropertyCaseTypeCategoryAndSubType()
            {
                var f = new ValidSubTypesFixture(Db);
                f.SetupValidSubTypes();
                var data =
                    Db.Set<ValidSubType>()
                      .First(
                             c =>
                                 c.Country.Id == "NZ" && c.PropertyTypeId == "T" && c.CaseTypeId == "I" && c.CaseCategoryId == "P" &&
                                 c.SubtypeId == "5");

                var result = f.Subject.GetValidSubType(new ValidSubTypeIdentifier("NZ", "T", "I", "P", "5"));

                Assert.NotNull(result);
                Assert.Equal(data.CountryId, result.Jurisdictions.First().Code);
                Assert.Equal(data.PropertyTypeId, result.PropertyType.Code);
                Assert.Equal(data.CaseTypeId, result.CaseType.Code);
                Assert.Equal(data.CaseCategoryId, result.CaseCategory.Code);
                Assert.Equal(data.SubtypeId, result.SubType.Code);
            }
        }

        public class SaveMethod : FactBase
        {
            SubTypeSaveDetails PrepareSave()
            {
                var countryId1 = Fixture.String("CountryId1");
                var countryId2 = Fixture.String("CountryId2");
                new Country(countryId1, Fixture.String("countryName1")).In(Db);
                new Country(countryId2, Fixture.String("countryName2")).In(Db);

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

                return new SubTypeSaveDetails
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
                    CaseCategory = new CaseCategory {Code = "P"},
                    CaseType = new CaseType {Code = "P"},
                    SubType = new SubType {Code = "~3"},
                    ValidDescription = "New Valid Sub Type"
                };
            }

            [Fact]
            public void AddsValidSubTypeForGivenJurisdictions()
            {
                var f = new ValidSubTypesFixture(Db);
                f.SetupValidSubTypes();
                var inputModel = PrepareSave();

                f.Validator.CheckValidPropertyCombination(inputModel).Returns((ValidationResult) null);
                f.Validator.CheckValidCategoryCombination(inputModel).Returns((ValidationResult) null);

                var result = f.Subject.Save(inputModel);

                Assert.Equal(result.Result, "success");
                Assert.Equal(2, ((IEnumerable<ValidSubTypeIdentifier>) result.UpdatedKeys).Count());
                Assert.Equal(6, Db.Set<ValidSubType>().Count());
                Assert.Equal(inputModel.ValidDescription, Db.Set<ValidSubType>().First(_ => _.CountryId.Contains("CountryId1")).SubTypeDescription);
                Assert.Equal(inputModel.ValidDescription, Db.Set<ValidSubType>().First(_ => _.CountryId.Contains("CountryId2")).SubTypeDescription);
            }

            [Fact]
            public void ReturnsConfirmationValidationResultIfValidSubTypeExistForSome()
            {
                var f = new ValidSubTypesFixture(Db);
                var data = f.SetupValidSubTypes();

                var input = new SubTypeSaveDetails
                {
                    Jurisdictions = new[]
                    {
                        new CountryModel {Code = data.validSubType1.CountryId},
                        new CountryModel {Code = Fixture.String(), Value = Fixture.String()}
                    },
                    PropertyType = new PropertyType {Code = data.validSubType1.PropertyTypeId},
                    CaseType = new CaseType {Code = data.validSubType1.CaseTypeId},
                    CaseCategory = new CaseCategory {Code = data.validSubType1.CaseCategoryId},
                    SubType = new SubType {Code = data.validSubType1.SubType.Code},
                    ValidDescription = Fixture.String("Valid Description")
                };
                f.Validator.CheckValidPropertyCombination(input).Returns((ValidationResult) null);
                f.Validator.CheckValidCategoryCombination(input).Returns((ValidationResult) null);
                f.Validator.DuplicateCombinationValidationResult(null, 0).ReturnsForAnyArgs(new ValidationResult {Result = "confirmation"});

                var result = f.Subject.Save(input);

                Assert.Equal("confirmation", result.Result);
            }

            [Fact]
            public void ReturnsValidationResultIfValidCategoryDoesnotExistForSelectedCombination()
            {
                var f = new ValidSubTypesFixture(Db);
                var data = f.SetupValidSubTypes();

                var input = new SubTypeSaveDetails
                {
                    Jurisdictions = new[] {new CountryModel {Code = data.validSubType1.CountryId}},
                    PropertyType = new PropertyType {Code = "P"},
                    CaseType = new CaseType {Code = data.validSubType1.CaseTypeId},
                    CaseCategory = new CaseCategory {Code = data.validSubType1.ValidCategory.CaseCategory.CaseCategoryId},
                    SubType = new SubType {Code = "S"},
                    ValidDescription = Fixture.String("Valid Description")
                };

                var validationResult = new ValidationResult
                {
                    Result = "Error"
                };
                f.Validator.CheckValidPropertyCombination(input).Returns((ValidationResult) null);
                f.Validator.CheckValidCategoryCombination(input).Returns(validationResult);

                var result = f.Subject.Save(input);

                Assert.Equal("Error", result.Result);
            }

            [Fact]
            public void ReturnsValidationResultIfValidPropertyTypeDoesnotExistForSelectedCombination()
            {
                var f = new ValidSubTypesFixture(Db);
                var data = f.SetupValidSubTypes();

                var input = new SubTypeSaveDetails
                {
                    Jurisdictions = new[] {new CountryModel {Code = data.validSubType1.CountryId}},
                    PropertyType = new PropertyType {Code = "P"},
                    CaseType = new CaseType {Code = data.validSubType1.CaseTypeId},
                    CaseCategory = new CaseCategory {Code = data.validSubType1.ValidCategory.CaseCategory.CaseCategoryId},
                    SubType = new SubType {Code = "S"},
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
            public void ReturnsValidationResultIfValidSubTypeAlreadyExist()
            {
                var f = new ValidSubTypesFixture(Db);
                var data = f.SetupValidSubTypes();

                var input = new SubTypeSaveDetails
                {
                    Jurisdictions = new[] {new CountryModel {Code = data.validSubType1.CountryId}},
                    PropertyType = new PropertyType {Code = data.validSubType1.PropertyTypeId},
                    CaseType = new CaseType {Code = data.validSubType1.CaseTypeId},
                    CaseCategory = new CaseCategory {Code = data.validSubType1.CaseCategoryId},
                    SubType = new SubType {Code = data.validSubType1.SubType.Code},
                    ValidDescription = Fixture.String("Valid Description")
                };
                f.Validator.CheckValidPropertyCombination(input).Returns((ValidationResult) null);
                f.Validator.CheckValidCategoryCombination(input).Returns((ValidationResult) null);
                f.Validator.DuplicateCombinationValidationResult(null, 0).ReturnsForAnyArgs(new ValidationResult {Result = "Error"});

                var result = f.Subject.Save(input);

                Assert.Equal("Error", result.Result);
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenSaveModelNotPassed()
            {
                var f = new ValidSubTypesFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Save(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("subTypeSaveDetails", exception.Message);
            }
        }

        public class UpdateMethod : FactBase
        {
            SubTypeSaveDetails PrepareUpdate(ValidSubType validSubType)
            {
                return new SubTypeSaveDetails
                {
                    Jurisdictions = new[]
                    {
                        new CountryModel
                        {
                            Code = validSubType.CountryId
                        }
                    },
                    PropertyType = new PropertyType {Code = validSubType.PropertyTypeId},
                    CaseType = new CaseType {Code = validSubType.CaseTypeId},
                    CaseCategory = new CaseCategory {Code = validSubType.CaseCategoryId},
                    SubType = new SubType {Code = validSubType.SubtypeId},
                    ValidDescription = validSubType.SubTypeDescription + "Updated"
                };
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenSaveModelNotPassed()
            {
                var f = new ValidSubTypesFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Update(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("subTypeSaveDetails", exception.Message);
            }

            [Fact]
            public void UpdatedExistingValidSubType()
            {
                var f = new ValidSubTypesFixture(Db);
                f.SetupValidSubTypes();

                var firstValidSubType = Db.Set<ValidSubType>().First();

                var countryId = firstValidSubType.CountryId;
                var propertyTypeId = firstValidSubType.PropertyTypeId;
                var caseTypeId = firstValidSubType.CaseTypeId;
                var subTypeId = firstValidSubType.SubtypeId;
                var caseCategoryId = firstValidSubType.CaseCategoryId;

                var modelToUpdate = PrepareUpdate(firstValidSubType);

                var result = f.Subject.Update(modelToUpdate);

                Assert.Equal(result.Result, "success");
                Assert.Equal(countryId, ((ValidSubTypeIdentifier) result.UpdatedKeys).CountryId);
                Assert.Equal(propertyTypeId, ((ValidSubTypeIdentifier) result.UpdatedKeys).PropertyTypeId);
                Assert.Equal(caseTypeId, ((ValidSubTypeIdentifier) result.UpdatedKeys).CaseTypeId);
                Assert.Equal(subTypeId, ((ValidSubTypeIdentifier) result.UpdatedKeys).SubTypeId);
                Assert.Equal(caseCategoryId, ((ValidSubTypeIdentifier) result.UpdatedKeys).CaseCategoryId);
                Assert.Contains("Updated", Db.Set<ValidSubType>()
                                             .First(
                                                    _ =>
                                                        _.CountryId == countryId && _.PropertyTypeId == propertyTypeId && _.CaseTypeId == caseTypeId &&
                                                        _.CaseCategoryId == caseCategoryId && _.SubtypeId == subTypeId).SubTypeDescription);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeletesValidSubTypeForGivenIdentifiers()
            {
                var f = new ValidSubTypesFixture(Db);
                f.SetupValidSubTypes();
                var firstValidSubType = Db.Set<ValidSubType>().First(va => va.CountryId == "GB");
                var secondValidSubType = Db.Set<ValidSubType>().First(va => va.CountryId == "NZ");

                var identifiers = new[]
                {
                    new ValidSubTypeIdentifier(
                                               firstValidSubType.CountryId,
                                               firstValidSubType.PropertyTypeId,
                                               firstValidSubType.CaseTypeId,
                                               firstValidSubType.CaseCategoryId,
                                               firstValidSubType.SubtypeId),
                    new ValidSubTypeIdentifier(
                                               secondValidSubType.CountryId,
                                               secondValidSubType.PropertyTypeId,
                                               secondValidSubType.CaseTypeId,
                                               secondValidSubType.CaseCategoryId,
                                               secondValidSubType.SubtypeId)
                };

                var result = f.Subject.Delete(identifiers);

                Assert.False(result.HasError);
                Assert.False(result.InUseIds.Any());
                Assert.Equal(2, Db.Set<ValidSubType>().Count());
            }

            [Fact]
            public void ReturnsErrorWithListOfIdsIfValidCombinationIsInUse()
            {
                var f = new ValidSubTypesFixture(Db);
                f.SetupValidSubTypes();
                var firstValidSubType = Db.Set<ValidSubType>().First(va => va.CountryId == "GB");

                var @case = new CaseBuilder
                {
                    CountryCode = firstValidSubType.CountryId,
                    PropertyType = new PropertyTypeBuilder {Id = firstValidSubType.PropertyTypeId}.Build(),
                    CaseType = new CaseTypeBuilder {Id = firstValidSubType.CaseTypeId}.Build(),
                    SubType = new SubTypeBuilder {Id = firstValidSubType.SubtypeId}.Build()
                }.Build().In(Db);

                @case.SetCaseCategory(new CaseCategoryBuilder {CaseCategoryId = firstValidSubType.CaseCategoryId}.Build());

                var identifiers = new[]
                {
                    new ValidSubTypeIdentifier(
                                               firstValidSubType.CountryId,
                                               firstValidSubType.PropertyTypeId,
                                               firstValidSubType.CaseTypeId,
                                               firstValidSubType.CaseCategoryId,
                                               firstValidSubType.SubtypeId)
                };
                var result = f.Subject.Delete(identifiers);

                Assert.True(result.HasError);
                Assert.True(result.InUseIds.Any());
                Assert.Equal(4, Db.Set<ValidSubType>().Count());
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenCollectionOfValidIdentifiersNotPassed()
            {
                var f = new ValidSubTypesFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Delete(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("deleteRequestModel", exception.Message);
            }
        }
    }
}