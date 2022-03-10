using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web.Configuration.ValidCombinations;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;
using CaseCategory = Inprotech.Web.Picklists.CaseCategory;
using CaseType = Inprotech.Web.Picklists.CaseType;
using PropertyType = Inprotech.Web.Picklists.PropertyType;

namespace Inprotech.Tests.Web.Configuration.ValidCombinations
{
    public class ValidBasisImpFacts
    {
        public class ValidBasisImpFixture : IFixture<ValidBasisImp>
        {
            readonly InMemoryDbContext _db;

            public ValidBasisImpFixture(InMemoryDbContext db)
            {
                _db = db;

                Validator = Substitute.For<IValidCombinationValidator>();

                Subject = new ValidBasisImp(_db, Validator);
            }

            public IValidCombinationValidator Validator { get; }

            public ValidBasisImp Subject { get; }

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

        public class GetMethod : FactBase
        {
            [Fact]
            public void ReturnsNullWhenValidBasisNotFoundForGivenCriteria()
            {
                var f = new ValidBasisImpFixture(Db);

                Assert.Null(f.Subject.GetValidBasis(new ValidBasisIdentifier("XXX", "YYY", "ZZZ", "AAA", "ZZ")));
            }

            [Fact]
            public void ReturnValidBasisForGivenCountryPropertyCaseTypeCategoryAndBasis()
            {
                var f = new ValidBasisImpFixture(Db);
                f.SetupValidBasis();

                var validBasis =
                    Db.Set<ValidBasis>()
                      .First(
                             c =>
                                 c.CountryId == "NZ" && c.PropertyTypeId == "P" && c.BasisId == "C");

                var validBasisEx =
                    Db.Set<ValidBasisEx>()
                      .First(
                             c =>
                                 c.CountryId == "NZ" && c.PropertyTypeId == "P" && c.BasisId == "C" && c.CaseTypeId == "I" && c.CaseCategoryId == "P");

                var result =
                    f.Subject.GetValidBasis(new ValidBasisIdentifier("NZ", "P", "C", "I", "P"));

                Assert.NotNull(result);
                Assert.Equal(validBasis.CountryId, result.Jurisdictions.First().Code);
                Assert.Equal(validBasis.PropertyTypeId, result.PropertyType.Code);
                Assert.Equal(validBasis.BasisId, result.Basis.Code);
                Assert.Equal(validBasisEx.CaseTypeId, result.CaseType.Code);
                Assert.Equal(validBasisEx.CaseCategoryId, result.CaseCategory.Code);
            }
        }

        public class SaveMethod : FactBase
        {
            BasisSaveDetails PrepareSave()
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

                return new BasisSaveDetails
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
                    Basis = new Basis {Code = "C"},
                    ValidDescription = "New Valid Basis"
                };
            }

            [Fact]
            public void AddsValidBasisForGivenJurisdictions()
            {
                var f = new ValidBasisImpFixture(Db);
                f.SetupValidBasis();

                var inputModel = PrepareSave();

                f.Validator.CheckValidPropertyCombination(inputModel).Returns((ValidationResult) null);
                f.Validator.CheckValidCategoryCombination(inputModel).Returns((ValidationResult) null);

                var result = f.Subject.Save(inputModel);

                Assert.Equal(result.Result, "success");
                Assert.Equal(2, ((IEnumerable<ValidBasisIdentifier>) result.UpdatedKeys).Count());
                Assert.Equal(6, Db.Set<ValidBasis>().Count());
                Assert.Equal(inputModel.ValidDescription, Db.Set<ValidBasis>().First(_ => _.CountryId.Contains("CountryId1")).BasisDescription);
                Assert.Equal(inputModel.ValidDescription, Db.Set<ValidBasis>().First(_ => _.CountryId.Contains("CountryId2")).BasisDescription);
            }

            [Fact]
            public void ReturnsConfirmationValidationResultIfValidBasisExistForSome()
            {
                var f = new ValidBasisImpFixture(Db);
                var data = f.SetupValidBasis();

                var input = new BasisSaveDetails
                {
                    Jurisdictions = new[]
                    {
                        new CountryModel {Code = data.validBasis1.CountryId},
                        new CountryModel {Code = Fixture.String(), Value = Fixture.String()}
                    },
                    PropertyType = new PropertyType {Code = data.validBasis1.PropertyTypeId},
                    CaseType = null,
                    CaseCategory = null,
                    Basis = new Basis {Code = data.validBasis1.Basis.Code},
                    ValidDescription = Fixture.String("Valid Description")
                };

                f.Validator.CheckValidPropertyCombination(input).Returns((ValidationResult) null);
                f.Validator.CheckValidCategoryCombination(input).Returns((ValidationResult) null);
                f.Validator.DuplicateCombinationValidationResult(null, 0).ReturnsForAnyArgs(new ValidationResult {Result = "confirmation"});

                var result = f.Subject.Save(input);

                Assert.Equal("confirmation", result.Result);
            }

            [Fact]
            public void ReturnsConfirmationValidationResultIfValidBasisExtensionExistForSome()
            {
                var f = new ValidBasisImpFixture(Db);
                var data = f.SetupValidBasis();

                var input = new BasisSaveDetails
                {
                    Jurisdictions = new[]
                    {
                        new CountryModel {Code = data.validBasis1.CountryId},
                        new CountryModel {Code = Fixture.String(), Value = Fixture.String()}
                    },
                    PropertyType = new PropertyType {Code = data.validBasis1.PropertyTypeId},
                    CaseType = new CaseType {Code = data.validBasisEx1.CaseTypeId},
                    CaseCategory = new CaseCategory {Code = data.validBasisEx1.CaseCategoryId},
                    Basis = new Basis {Code = data.validBasis1.Basis.Code},
                    ValidDescription = Fixture.String("Valid Description")
                };

                f.Validator.CheckValidPropertyCombination(input).Returns((ValidationResult) null);
                f.Validator.CheckValidCategoryCombination(input).Returns((ValidationResult) null);
                f.Validator.DuplicateCombinationValidationResult(null, 0).ReturnsForAnyArgs(new ValidationResult {Result = "confirmation"});

                var result = f.Subject.Save(input);

                Assert.Equal("confirmation", result.Result);
            }

            [Fact]
            public void ReturnsValidationResultIfValidBasisAlreadyExist()
            {
                var f = new ValidBasisImpFixture(Db);
                var data = f.SetupValidBasis();

                var input = new BasisSaveDetails
                {
                    Jurisdictions = new[] {new CountryModel {Code = data.validBasis1.CountryId}},
                    PropertyType = new PropertyType {Code = data.validBasis1.PropertyTypeId},
                    CaseType = null,
                    CaseCategory = null,
                    Basis = new Basis {Code = data.validBasis1.Basis.Code},
                    ValidDescription = Fixture.String("Valid Description")
                };

                f.Validator.CheckValidPropertyCombination(input).Returns((ValidationResult) null);
                f.Validator.CheckValidCategoryCombination(input).Returns((ValidationResult) null);
                f.Validator.DuplicateCombinationValidationResult(null, 0).ReturnsForAnyArgs(new ValidationResult {Result = "Error"});

                var result = f.Subject.Save(input);

                Assert.Equal("Error", result.Result);
            }

            [Fact]
            public void ReturnsValidationResultIfValidBasisExtensionAlreadyExist()
            {
                var f = new ValidBasisImpFixture(Db);
                var data = f.SetupValidBasis();

                var input = new BasisSaveDetails
                {
                    Jurisdictions = new[] {new CountryModel {Code = data.validBasis1.CountryId}},
                    PropertyType = new PropertyType {Code = data.validBasis1.PropertyTypeId},
                    CaseType = new CaseType {Code = data.validBasisEx1.CaseTypeId},
                    CaseCategory = new CaseCategory {Code = data.validBasisEx1.CaseCategoryId},
                    Basis = new Basis {Code = data.validBasis1.Basis.Code},
                    ValidDescription = Fixture.String("Valid Description")
                };

                f.Validator.CheckValidPropertyCombination(input).Returns((ValidationResult) null);
                f.Validator.CheckValidCategoryCombination(input).Returns((ValidationResult) null);
                f.Validator.DuplicateCombinationValidationResult(null, 0).ReturnsForAnyArgs(new ValidationResult {Result = "Error"});

                var result = f.Subject.Save(input);

                Assert.Equal("Error", result.Result);
            }

            [Fact]
            public void ReturnsValidationResultIfValidPropertyTypeDoesnotExistForSelectedCombination()
            {
                var f = new ValidBasisImpFixture(Db);
                var data = f.SetupValidBasis();

                var input = new BasisSaveDetails
                {
                    Jurisdictions = new[] {new CountryModel {Code = data.validBasis1.CountryId}},
                    PropertyType = new PropertyType {Code = "P"},
                    CaseType = new CaseType {Code = data.validBasisEx1.CaseTypeId},
                    CaseCategory = new CaseCategory {Code = data.validBasisEx1.CaseCategoryId},
                    Basis = new Basis {Code = "C"},
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
                var f = new ValidBasisImpFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Save(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("basisSaveDetails", exception.Message);
            }
        }

        public class UpdateMethod : FactBase
        {
            BasisSaveDetails PrepareUpdate(ValidBasis validBasis, ValidBasisEx validBasisEx)
            {
                return new BasisSaveDetails
                {
                    Jurisdictions = new[]
                    {
                        new CountryModel
                        {
                            Code = validBasis.CountryId
                        }
                    },
                    PropertyType = new PropertyType {Code = validBasis.PropertyTypeId},
                    CaseType = new CaseType {Code = validBasisEx.CaseTypeId},
                    CaseCategory = new CaseCategory {Code = validBasisEx.CaseCategoryId},
                    Basis = new Basis {Code = validBasis.BasisId},
                    ValidDescription = validBasis.BasisDescription + "Updated"
                };
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenSaveModelNotPassed()
            {
                var f = new ValidBasisImpFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Update(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("basisSaveDetails", exception.Message);
            }

            [Fact]
            public void UpdatedExistingValidBasis()
            {
                var f = new ValidBasisImpFixture(Db);
                var data = f.SetupValidBasis();

                var firstValidBasis = data.validBasis1;
                var firstValidBasisEx = data.validBasisEx1;

                var countryId = (string) firstValidBasis.CountryId;
                var propertyTypeId = (string) firstValidBasisEx.PropertyTypeId;
                var caseTypeId = (string) firstValidBasisEx.CaseTypeId;
                var basisId = (string) firstValidBasis.BasisId;
                var caseCategoryId = (string) firstValidBasisEx.CaseCategoryId;

                var modelToUpdate = PrepareUpdate(firstValidBasis, firstValidBasisEx);

                var result = f.Subject.Update(modelToUpdate);

                Assert.Equal(result.Result, "success");
                Assert.Equal(countryId, ((ValidBasisIdentifier) result.UpdatedKeys).CountryId);
                Assert.Equal(propertyTypeId, ((ValidBasisIdentifier) result.UpdatedKeys).PropertyTypeId);
                Assert.Equal(caseTypeId, ((ValidBasisIdentifier) result.UpdatedKeys).CaseTypeId);
                Assert.Equal(basisId, ((ValidBasisIdentifier) result.UpdatedKeys).BasisId);
                Assert.Equal(caseCategoryId, ((ValidBasisIdentifier) result.UpdatedKeys).CaseCategoryId);
                Assert.Contains("Updated", Db.Set<ValidBasis>()
                                             .First(
                                                    _ =>
                                                        _.CountryId == countryId && _.PropertyTypeId == propertyTypeId && _.BasisId == basisId).BasisDescription);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeletesValidBasisExtensionForGivenIdentifiersWhenCategoryIsNotNull()
            {
                var f = new ValidBasisImpFixture(Db);
                var data = f.SetupValidBasis();

                var firstValidBasis = data.validBasis1;
                var firstValidBasisEx = data.validBasisEx1;
                var secondValidBasis = data.validBasis2;
                var secondValidBasisEx = data.validBasisEx2;

                var identifiers = new[]
                {
                    new ValidBasisIdentifier(
                                             firstValidBasis.CountryId,
                                             firstValidBasis.PropertyTypeId,
                                             firstValidBasis.BasisId,
                                             firstValidBasisEx.CaseTypeId,
                                             firstValidBasisEx.CaseCategoryId),
                    new ValidBasisIdentifier(
                                             secondValidBasis.CountryId,
                                             secondValidBasis.PropertyTypeId,
                                             secondValidBasis.BasisId,
                                             secondValidBasisEx.CaseTypeId,
                                             secondValidBasisEx.CaseCategoryId)
                };

                var result = f.Subject.Delete(identifiers);

                Assert.False(result.HasError);
                Assert.Equal(4, Db.Set<ValidBasis>().Count());
                Assert.Equal(2, Db.Set<ValidBasisEx>().Count());
            }

            [Fact]
            public void DeletesValidBasisForGivenIdentifiersWhenCategoryIsNull()
            {
                var validBasis1 = new ValidBasisBuilder
                {
                    Country = new CountryBuilder {Id = "NZ", Name = "New Zealand"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "P", Name = "Patent"}.Build(),
                    Basis = new ApplicationBasisBuilder {Id = "C", Name = "Convention"}.Build(),
                    BasisDesc = "Claiming NZ Convention"
                }.Build().In(Db);

                var f = new ValidBasisImpFixture(Db);

                var identifiers = new[]
                {
                    new ValidBasisIdentifier(
                                             validBasis1.CountryId,
                                             validBasis1.PropertyTypeId,
                                             validBasis1.BasisId,
                                             null,
                                             null)
                };

                var result = f.Subject.Delete(identifiers);

                Assert.False(result.HasError);
            }

            [Fact]
            public void ReturnsErrorWithListOfIdsIfValidCombinationIsInUseInCase()
            {
                var f = new ValidBasisImpFixture(Db);
                var data = f.SetupValidBasis();
                var firstValidBasis = data.validBasis1;

                new CaseBuilder
                {
                    CountryCode = firstValidBasis.CountryId,
                    PropertyType = new PropertyTypeBuilder {Id = firstValidBasis.PropertyTypeId}.Build(),
                    Property = new CasePropertyBuilder {ApplicationBasis = new ApplicationBasisBuilder {Id = firstValidBasis.BasisId}.Build()}.Build()
                }.Build().In(Db);

                var identifiers = new[]
                {
                    new ValidBasisIdentifier(
                                             firstValidBasis.CountryId,
                                             firstValidBasis.PropertyTypeId,
                                             firstValidBasis.BasisId,
                                             null,
                                             null)
                };
                var result = f.Subject.Delete(identifiers);

                Assert.True(result.HasError);
                Assert.True(result.InUseIds.Any());
                Assert.Equal(4, Db.Set<ValidBasis>().Count());
            }

            [Fact]
            public void ReturnsErrorWithListOfIdsIfValidCombinationIsInUseInValidBasisEx()
            {
                var f = new ValidBasisImpFixture(Db);
                var data = f.SetupValidBasis();
                var firstValidBasis = data.validBasis1;

                var identifiers = new[]
                {
                    new ValidBasisIdentifier(
                                             firstValidBasis.CountryId,
                                             firstValidBasis.PropertyTypeId,
                                             firstValidBasis.BasisId,
                                             null,
                                             null)
                };
                var result = f.Subject.Delete(identifiers);

                Assert.True(result.HasError);
                Assert.True(result.InUseIds.Any());
                Assert.Equal(4, Db.Set<ValidBasis>().Count());
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenCollectionOfValidIdentifiersNotPassed()
            {
                var f = new ValidBasisImpFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Delete(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("deleteRequestModel", exception.Message);
            }
        }
    }
}