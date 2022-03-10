using System.Collections.Generic;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Configuration.ValidCombinations;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.ValidCombinations
{
    public class ValidCombinationValidatorFacts
    {
        public class ValidCombinationValidatorFixture : IFixture<ValidCombinationValidator>
        {
            readonly InMemoryDbContext _db;

            public ValidCombinationValidatorFixture(InMemoryDbContext db)
            {
                _db = db;
                CaseCategories = Substitute.For<ICaseCategories>();
                CaseCategories.WhenForAnyArgs(c => c.Get(null, null, null, null)).Do(c => CaseCategoriesArgs = c.Args());

                Subject = new ValidCombinationValidator(db, CaseCategories);
            }

            public ICaseCategories CaseCategories { get; }
            public dynamic CaseCategoriesArgs { get; set; }

            public ValidCombinationValidator Subject { get; }

            public dynamic SetupData()
            {
                var country1 = new CountryBuilder {Id = "NZ", Name = "New Zealand"}.Build().In(_db);
                var country2 = new CountryBuilder {Id = "US", Name = "United States Of America"}.Build().In(_db);
                var propertyType1 = new PropertyTypeBuilder {Id = "T", Name = "TradeMark"}.Build().In(_db);
                var propertyType2 = new PropertyTypeBuilder {Id = "P", Name = "Patent"}.Build().In(_db);
                new ValidPropertyBuilder
                {
                    CountryCode = country1.Id,
                    PropertyTypeId = propertyType1.Code
                }.Build().In(_db);

                var validCategory1 = new ValidCategoryBuilder
                {
                    Country = country1,
                    PropertyType = propertyType1,
                    CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build().In(_db),
                    CaseCategory = new CaseCategoryBuilder {CaseTypeId = "P", Name = ".COM", CaseCategoryId = "P"}.Build().In(_db)
                }.Build().In(_db);

                return new
                {
                    country1,
                    country2,
                    propertyType1,
                    propertyType2,
                    validCategory1
                };
            }

            public class CheckValidPropertyCombinationMethod : FactBase
            {
                [Fact]
                public void ReturnsConfirmationWhenValidPropertyTypeDoesnotExistsForSomeGivenCountries()
                {
                    var f = new ValidCombinationValidatorFixture(Db);
                    var data = f.SetupData();

                    var input = new CaseCategorySaveDetails
                    {
                        Jurisdictions = new[]
                        {
                            new CountryModel {Code = data.country1.Id},
                            new CountryModel {Code = data.country2.Id}
                        },
                        PropertyType = new PropertyType {Code = data.propertyType1.Code}
                    };

                    var validationResult = f.Subject.CheckValidPropertyCombination(input);

                    Assert.Equal("confirmation", validationResult.Result);
                    Assert.Equal(ConfigurationResources.InValidPorpertyTypes, validationResult.ValidationMessage);
                    Assert.Equal(ConfigurationResources.ConfirmSaveForValidCombination, validationResult.ConfirmationMessage);
                    Assert.Equal(new string[] {data.country2.Id}, validationResult.CountryKeys);
                }

                [Fact]
                public void ReturnsErrorWhenValidPropertyTypeDoesnotExistsForAllGivenCountries()
                {
                    var f = new ValidCombinationValidatorFixture(Db);
                    var data = f.SetupData();

                    var input = new CaseCategorySaveDetails
                    {
                        Jurisdictions = new[]
                        {
                            new CountryModel {Code = data.country1.Id},
                            new CountryModel {Code = data.country2.Id}
                        },
                        PropertyType = new PropertyType {Code = data.propertyType2.Code}
                    };

                    var validationResult = f.Subject.CheckValidPropertyCombination(input);

                    Assert.Equal("Error", validationResult.Result);
                    Assert.Equal(ConfigurationResources.ErrorInvalidPropertyTypes, validationResult.Message);
                }

                [Fact]
                public void ReturnsNullWhenValidPropertyTypeExistsForGivenCountries()
                {
                    var f = new ValidCombinationValidatorFixture(Db);
                    var data = f.SetupData();

                    var input = new CaseCategorySaveDetails
                    {
                        Jurisdictions = new[]
                        {
                            new CountryModel {Code = data.country1.Id}
                        },
                        PropertyType = new PropertyType {Code = data.propertyType1.Code}
                    };

                    var result = f.Subject.CheckValidPropertyCombination(input);

                    Assert.Null(result);
                }
            }

            public class CheckForValidCategoryCombinationMethod : FactBase
            {
                [Fact]
                public void ReturnsErrorWhenValidCategoryDoesnotExistsForAllGivenCountries()
                {
                    var f = new ValidCombinationValidatorFixture(Db);
                    var data = f.SetupData();

                    var input = new CaseCategorySaveDetails
                    {
                        Jurisdictions = new[]
                        {
                            new CountryModel {Code = data.country2.Id}
                        },
                        PropertyType = new PropertyType {Code = data.propertyType1.Code},
                        CaseType = new CaseType {Code = data.validCategory1.CaseType.Code},
                        CaseCategory = new CaseCategory {Code = data.validCategory1.CaseCategory.CaseCategoryId}
                    };

                    var validationResult = f.Subject.CheckValidCategoryCombination(input);

                    Assert.Equal("Error", validationResult.Result);
                    Assert.Equal(ConfigurationResources.ErrorInvalidCaseCategories, validationResult.Message);
                }

                [Fact]
                public void ReturnsNullWhenValidCategoryExistsForGivenCountries()
                {
                    var f = new ValidCombinationValidatorFixture(Db);
                    var data = f.SetupData();

                    var input = new SubTypeSaveDetails
                    {
                        Jurisdictions = new[]
                        {
                            new CountryModel {Code = data.country1.Id}
                        },
                        PropertyType = new PropertyType {Code = data.propertyType1.Code},
                        CaseType = new CaseType {Code = data.validCategory1.CaseType.Code},
                        CaseCategory = new CaseCategory {Code = data.validCategory1.CaseCategory.CaseCategoryId}
                    };

                    var validationResult = f.Subject.CheckValidCategoryCombination(input);

                    Assert.Null(validationResult);
                }

                [Fact]
                public void ReturnsWarningWhenValidCategoryDoesnotExistsForSomeGivenCountries()
                {
                    var f = new ValidCombinationValidatorFixture(Db);
                    var data = f.SetupData();

                    var input = new CaseCategorySaveDetails
                    {
                        Jurisdictions = new[]
                        {
                            new CountryModel {Code = data.country1.Id},
                            new CountryModel {Code = data.country2.Id}
                        },
                        PropertyType = new PropertyType {Code = data.propertyType1.Code},
                        CaseType = new CaseType {Code = data.validCategory1.CaseType.Code},
                        CaseCategory = new CaseCategory {Code = data.validCategory1.CaseCategory.CaseCategoryId}
                    };

                    var validationResult = f.Subject.CheckValidCategoryCombination(input);

                    Assert.Equal("confirmation", validationResult.Result);
                    Assert.Equal(ConfigurationResources.InvalidCaseCategory, validationResult.ValidationMessage);
                    Assert.Equal(ConfigurationResources.ConfirmSaveForValidCombination, validationResult.ConfirmationMessage);
                    Assert.Equal(new string[] {data.country2.Id}, validationResult.CountryKeys);
                }
            }

            public class DuplicateCombinationValidationResult : FactBase
            {
                [Fact]
                public void ReturnsConfirmationWhenValidPropertyTypeDoesnotExistsForSomeGivenCountries()
                {
                    var f = new ValidCombinationValidatorFixture(Db);
                    var data = f.SetupData();

                    var countries = new[]
                    {
                        new CountryModel {Code = data.country1.Id},
                        new CountryModel {Code = data.country2.Id}
                    };

                    var validationResult = f.Subject.DuplicateCombinationValidationResult(countries, 3);

                    Assert.Equal("confirmation", validationResult.Result);
                    Assert.Equal(ConfigurationResources.DuplicateValidCombination, validationResult.ValidationMessage);
                    Assert.Equal(ConfigurationResources.ConfirmSaveForValidCombination, validationResult.ConfirmationMessage);
                    Assert.Equal(new string[] {data.country1.Id, data.country2.Id}, validationResult.CountryKeys);
                }

                [Fact]
                public void ReturnsErrorWhenValidPropertyTypeDoesnotExistsForAllGivenCountries()
                {
                    var f = new ValidCombinationValidatorFixture(Db);
                    var data = f.SetupData();

                    var countries = new[]
                    {
                        new CountryModel {Code = data.country1.Id},
                        new CountryModel {Code = data.country2.Id}
                    };

                    var validationResult = f.Subject.DuplicateCombinationValidationResult(countries, 2);

                    Assert.Equal("Error", validationResult.Result);
                    Assert.Equal(ConfigurationResources.ErrorDuplicateValidCombination, validationResult.Message);
                }

                [Fact]
                public void ReturnsNullWhenNoDuplicateCombinationExists()
                {
                    var f = new ValidCombinationValidatorFixture(Db);
                    f.SetupData();

                    var result = f.Subject.DuplicateCombinationValidationResult(new CountryModel[0], 1);

                    Assert.Null(result);
                }
            }

            public class ValidateCaseCategory : FactBase
            {
                [Fact]
                public void ShouldGetCaseCategoriesForCaseType()
                {
                    var f = new ValidCombinationValidatorFixture(Db);

                    f.Subject.ValidateCaseCategory("A", "C");

                    f.CaseCategories.Received(1);
                    Assert.Null(f.CaseCategoriesArgs[0]);
                    Assert.Equal("A", f.CaseCategoriesArgs[1]);
                    Assert.Null(f.CaseCategoriesArgs[2]);
                    Assert.Null(f.CaseCategoriesArgs[3]);
                }

                [Fact]
                public void ShouldReturnInvalidIfNoCaseType()
                {
                    var f = new ValidCombinationValidatorFixture(Db);

                    var caseCategories = new[]
                    {
                        new KeyValuePair<string, string>("A", "DEFGHI")
                    };
                    f.CaseCategories.Get(null, null, null, null).ReturnsForAnyArgs(caseCategories);

                    var result = f.Subject.ValidateCaseCategory(string.Empty, "A");
                    Assert.False(result.IsValid);
                }

                [Fact]
                public void ShouldReturnNotValid()
                {
                    var f = new ValidCombinationValidatorFixture(Db);

                    var caseCategories = new[]
                    {
                        new KeyValuePair<string, string>("A", "DEFGHI"),
                        new KeyValuePair<string, string>("B", "ABCDEFG")
                    };
                    f.CaseCategories.Get(null, null, null, null).ReturnsForAnyArgs(caseCategories);

                    var result = f.Subject.ValidateCaseCategory("A", "C");
                    Assert.False(result.IsValid);
                    Assert.Null(result.Code);
                    Assert.Null(result.Value);
                }

                [Fact]
                public void ShouldReturnValid()
                {
                    var f = new ValidCombinationValidatorFixture(Db);

                    var caseCategories = new[]
                    {
                        new KeyValuePair<string, string>("A", "DEFGHI"),
                        new KeyValuePair<string, string>("B", "ABCDEFG"),
                        new KeyValuePair<string, string>("C", "GHIJKL")
                    };
                    f.CaseCategories.Get(null, null, null, null).ReturnsForAnyArgs(caseCategories);

                    var result = f.Subject.ValidateCaseCategory("A", "C");
                    Assert.True(result.IsValid);
                    Assert.Equal("C", result.Code);
                    Assert.Equal("GHIJKL", result.Value);
                }

                [Fact]
                public void ShouldReturnValidIfNull()
                {
                    var f = new ValidCombinationValidatorFixture(Db);

                    var result = f.Subject.ValidateCaseCategory("A", string.Empty);

                    Assert.True(result.IsValid);
                    Assert.Null(result.Code);
                    Assert.Null(result.Value);
                }
            }
        }
    }
}