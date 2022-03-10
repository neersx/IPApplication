using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Configuration.ValidCombinations;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;
using Action = Inprotech.Web.Picklists.Action;
using CaseType = Inprotech.Web.Picklists.CaseType;
using PropertyType = Inprotech.Web.Picklists.PropertyType;

namespace Inprotech.Tests.Web.Configuration.ValidCombinations
{
    public class ValidActionsFacts
    {
        public class ValidActionsFixture : IFixture<ValidActions>
        {
            readonly InMemoryDbContext _db;

            public ValidActionsFixture(InMemoryDbContext db)
            {
                _db = db;
                Validator = Substitute.For<IValidCombinationValidator>();

                Subject = new ValidActions(_db, Validator);
            }

            public IValidCombinationValidator Validator { get; }
            public ValidActions Subject { get; }

            public dynamic SetupActions()
            {
                var validAction1 = new ValidActionBuilder
                    {
                        Country = new CountryBuilder {Id = "NZ", Name = "New Zealand"}.Build().In(_db),
                        PropertyType = new PropertyTypeBuilder {Id = "T", Name = "TradeMark"}.Build().In(_db),
                        CaseType = new CaseTypeBuilder {Id = "I", Name = "Internal"}.Build().In(_db),
                        Action = new ActionBuilder {Id = "~1", Name = "Filing"}.Build().In(_db),
                        Sequence = 0
                    }.Build()
                     .In(_db);

                var validAction2 = new ValidActionBuilder
                    {
                        Country = new CountryBuilder {Id = "GB", Name = "United Kingdom"}.Build().In(_db),
                        PropertyType = new PropertyTypeBuilder {Id = "P", Name = "Patent"}.Build().In(_db),
                        CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build().In(_db),
                        Action = new ActionBuilder {Id = "~2", Name = "Overview"}.Build().In(_db),
                        Sequence = 1
                    }.Build()
                     .In(_db);

                var validAction3 = new ValidActionBuilder
                    {
                        Country = new CountryBuilder {Id = "US", Name = "United States of America"}.Build().In(_db),
                        PropertyType = new PropertyTypeBuilder {Id = "D", Name = "Design"}.Build().In(_db),
                        CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build().In(_db),
                        Action = new ActionBuilder {Id = "~3", Name = "Examination"}.Build().In(_db),
                        Sequence = 3
                    }.Build()
                     .In(_db);

                new ValidActionBuilder
                    {
                        Country = new CountryBuilder {Id = "US", Name = "United States of America"}.Build().In(_db),
                        PropertyType = new PropertyTypeBuilder {Id = "ND", Name = "Domain Name"}.Build().In(_db),
                        CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build().In(_db),
                        Action = new ActionBuilder {Id = "~4", Name = "Preview"}.Build().In(_db),
                        Sequence = 4
                    }.Build()
                     .In(_db);

                new ValidActionBuilder
                    {
                        Country = new CountryBuilder {Id = "IN", Name = "India"}.Build().In(_db),
                        PropertyType = new PropertyTypeBuilder {Id = "D", Name = "Design"}.Build().In(_db),
                        CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build().In(_db),
                        Action = new ActionBuilder {Id = "~3", Name = "Examination"}.Build().In(_db),
                        Sequence = 5
                    }.Build()
                     .In(_db);

                new CountryBuilder {Id = "FR", Name = "France"}.Build().In(_db);
                new CountryBuilder {Id = "IT", Name = "Italy"}.Build().In(_db);
                new ValidProperty {CountryId = "NZ", PropertyTypeId = "T", PropertyName = "Valid Property"}.In(_db);

                return new
                {
                    validAction1,
                    validAction2,
                    validAction3
                };
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void ReturnsNullWhenValidActionNotFoundForGivenCriteria()
            {
                var f = new ValidActionsFixture(Db);

                Assert.Null(f.Subject.GetValidAction(new ValidActionIdentifier("XXX", "YYY", "ZZZ", "~2")));
            }

            [Fact]
            public void ReturnValidActionForGivenCountryPropertyCaseTypeAndAction()
            {
                var f = new ValidActionsFixture(Db);
                f.SetupActions();

                var data =
                    Db.Set<ValidAction>()
                      .First(
                             c =>
                                 c.Country.Id == "GB" && c.PropertyTypeId == "P" && c.CaseTypeId == "P" &&
                                 c.ActionId == "~2");

                var result =
                    f.Subject.GetValidAction(new ValidActionIdentifier("GB", "P", "P", "~2"));

                Assert.NotNull(result);
                Assert.Equal(data.CountryId, result.Jurisdictions.First().Code);
                Assert.Equal(data.PropertyTypeId, result.PropertyType.Code);
                Assert.Equal(data.CaseTypeId, result.CaseType.Code);
                Assert.Equal(data.ActionId, result.Action.Code);
            }
        }

        public class SaveMethod : FactBase
        {
            ActionSaveDetails PrepareSave()
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

                return new ActionSaveDetails
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
                    CaseType = new CaseType {Code = "P"},
                    Action = new Action {Code = "~3"},
                    ValidDescription = "New Valid Action"
                };
            }

            [Fact]
            public void AddsValidActionForGivenJurisdictions()
            {
                var f = new ValidActionsFixture(Db);
                f.SetupActions();

                var inputModel = PrepareSave();

                f.Validator.CheckValidPropertyCombination(inputModel).Returns((ValidationResult) null);

                var result = f.Subject.Save(inputModel);

                Assert.Equal(result.Result, "success");
                Assert.Equal(7, Db.Set<ValidAction>().Count());
                Assert.Equal(inputModel.ValidDescription, Db.Set<ValidAction>().First(_ => _.CountryId.Contains("CountryId1")).ActionName);
                Assert.Equal(inputModel.ValidDescription, Db.Set<ValidAction>().First(_ => _.CountryId.Contains("CountryId2")).ActionName);
                Assert.Equal(Db.Set<ValidAction>().Max(va => va.DisplaySequence), (short?) 7);
            }

            [Fact]
            public void ReturnsConfirmationValidationResultIfValidActionExistForSome()
            {
                var f = new ValidActionsFixture(Db);
                var data = f.SetupActions();

                var input = new ActionSaveDetails
                {
                    Jurisdictions = new[]
                    {
                        new CountryModel {Code = data.validAction1.CountryId},
                        new CountryModel {Code = Fixture.String(), Value = Fixture.String()}
                    },
                    PropertyType = new PropertyType {Code = data.validAction1.PropertyTypeId},
                    CaseType = new CaseType {Code = data.validAction1.CaseTypeId},
                    Action = new Action {Code = data.validAction1.Action.Code},
                    ValidDescription = Fixture.String("Valid Description")
                };
                f.Validator.CheckValidPropertyCombination(input).Returns((ValidationResult) null);
                f.Validator.DuplicateCombinationValidationResult(null, 0).ReturnsForAnyArgs(new ValidationResult {Result = "confirmation"});

                var result = f.Subject.Save(input);

                Assert.Equal("confirmation", result.Result);
            }

            [Fact]
            public void ReturnsValidationResultIfValidActionAlreadyExist()
            {
                var f = new ValidActionsFixture(Db);
                var data = f.SetupActions();

                var input = new ActionSaveDetails
                {
                    Jurisdictions = new[] {new CountryModel {Code = data.validAction1.CountryId}},
                    PropertyType = new PropertyType {Code = data.validAction1.PropertyTypeId},
                    CaseType = new CaseType {Code = data.validAction1.CaseTypeId},
                    Action = new Action {Code = data.validAction1.Action.Code},
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
                var f = new ValidActionsFixture(Db);
                var data = f.SetupActions();

                var input = new ActionSaveDetails
                {
                    Jurisdictions = new[] {new CountryModel {Code = data.validAction1.CountryId}},
                    PropertyType = new PropertyType {Code = "P"},
                    CaseType = new CaseType {Code = data.validAction1.CaseTypeId},
                    Action = new Action {Code = "~3"},
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
                var f = new ValidActionsFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Save(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("actionSaveDetails", exception.Message);
            }
        }

        public class UpdateMethod : FactBase
        {
            ActionSaveDetails PrepareUpdate(ValidAction validAction)
            {
                return new ActionSaveDetails
                {
                    Jurisdictions = new[]
                    {
                        new CountryModel
                        {
                            Code = validAction.CountryId
                        }
                    },
                    PropertyType = new PropertyType {Code = validAction.PropertyTypeId},
                    CaseType = new CaseType {Code = validAction.CaseTypeId},
                    Action = new Action {Code = validAction.ActionId},
                    ValidDescription = validAction.ActionName + "Updated"
                };
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenSaveModelNotPassed()
            {
                var f = new ValidActionsFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Update(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("actionSaveDetails", exception.Message);
            }

            [Fact]
            public void UpdatedExistingValidAction()
            {
                var f = new ValidActionsFixture(Db);
                f.SetupActions();

                var firstValidAction = Db.Set<ValidAction>().First();

                var countryId = firstValidAction.CountryId;
                var propertyTypeId = firstValidAction.PropertyTypeId;
                var caseTypeId = firstValidAction.CaseTypeId;
                var actionId = firstValidAction.ActionId;

                var modelToUpdate = PrepareUpdate(firstValidAction);

                var result = f.Subject.Update(modelToUpdate);

                Assert.Equal(result.Result, "success");
                Assert.Equal(countryId, ((ValidActionIdentifier) result.UpdatedKeys).CountryId);
                Assert.Equal(propertyTypeId, ((ValidActionIdentifier) result.UpdatedKeys).PropertyTypeId);
                Assert.Equal(caseTypeId, ((ValidActionIdentifier) result.UpdatedKeys).CaseTypeId);
                Assert.Equal(actionId, ((ValidActionIdentifier) result.UpdatedKeys).ActionId);
                Assert.Contains("Updated", Db.Set<ValidAction>()
                                             .First(
                                                    _ =>
                                                        _.CountryId == countryId && _.PropertyTypeId == propertyTypeId && _.CaseTypeId == caseTypeId &&
                                                        _.ActionId == actionId).ActionName);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeletesValidActionForGivenIdentifiers()
            {
                var f = new ValidActionsFixture(Db);
                f.SetupActions();
                var firstValidAction = Db.Set<ValidAction>().First(va => va.CountryId == "GB");
                var secondValidAction = Db.Set<ValidAction>().First(va => va.CountryId == "NZ");

                var identifiers = new[]
                {
                    new ValidActionIdentifier(
                                              firstValidAction.CountryId,
                                              firstValidAction.PropertyTypeId,
                                              firstValidAction.CaseTypeId,
                                              firstValidAction.ActionId),
                    new ValidActionIdentifier(
                                              secondValidAction.CountryId,
                                              secondValidAction.PropertyTypeId,
                                              secondValidAction.CaseTypeId,
                                              secondValidAction.ActionId)
                };

                var result = f.Subject.Delete(identifiers);

                Assert.False(result.HasError);
                Assert.False(result.InUseIds.Any());
                Assert.Equal(3, Db.Set<ValidAction>().Count());
            }

            [Fact]
            public void ReturnsErrorWithListOfIdsIfValidCombinationIsInUse()
            {
                var f = new ValidActionsFixture(Db);
                f.SetupActions();
                var firstValidAction = Db.Set<ValidAction>().First(va => va.CountryId == "GB");

                var @case = new CaseBuilder
                {
                    CountryCode = firstValidAction.CountryId,
                    PropertyType = new PropertyTypeBuilder {Id = firstValidAction.PropertyTypeId}.Build(),
                    CaseType = new CaseTypeBuilder {Id = firstValidAction.CaseTypeId}.Build()
                }.Build().In(Db);
                @case.OpenActions.Add(new OpenActionBuilder(Db) {Case = @case, Action = new ActionBuilder {Id = firstValidAction.ActionId}.Build()}.Build().In(Db));

                var identifiers = new[]
                {
                    new ValidActionIdentifier(
                                              firstValidAction.CountryId,
                                              firstValidAction.PropertyTypeId,
                                              firstValidAction.CaseTypeId,
                                              firstValidAction.ActionId)
                };
                var result = f.Subject.Delete(identifiers);

                Assert.True(result.HasError);
                Assert.True(result.InUseIds.Any());
                Assert.Equal(5, Db.Set<ValidAction>().Count());
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenCollectionOfValidIdentifiersNotPassed()
            {
                var f = new ValidActionsFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Delete(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("deleteRequestModel", exception.Message);
            }
        }
    }
}