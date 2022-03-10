using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web.Configuration.ValidCombinations;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.ValidCombinations
{
    public class ValidPropertyTypesFacts
    {
        public class ValidPropertyTypesFixture : IFixture<ValidPropertyTypes>
        {
            readonly InMemoryDbContext _db;

            public ValidPropertyTypesFixture(InMemoryDbContext db)
            {
                _db = db;
                Validator = Substitute.For<IValidCombinationValidator>();

                Subject = new ValidPropertyTypes(db, Validator);
            }

            public IValidCombinationValidator Validator { get; set; }

            public ValidPropertyTypes Subject { get; }

            public dynamic SetUpPropertyTypes()
            {
                var validProperty1 =
                    new ValidPropertyBuilder {PropertyTypeId = "T", CountryCode = "NZ", CountryName = "New Zealand"}.Build()
                                                                                                                    .In(_db);
                var validProperty2 =
                    new ValidPropertyBuilder {PropertyTypeId = "P", CountryCode = "GB", CountryName = "United Kingdom"}.Build()
                                                                                                                       .In(_db);
                var validProperty3 =
                    new ValidPropertyBuilder {PropertyTypeId = "D", CountryCode = "EH", CountryName = "West Sahara"}.Build()
                                                                                                                    .In(_db);
                var validProperty4 =
                    new ValidPropertyBuilder {PropertyTypeId = "P", CountryCode = "US", CountryName = "United States Of America"}.Build()
                                                                                                                                 .In(_db);

                var validProperty5 =
                    new ValidPropertyBuilder {PropertyTypeId = "T", CountryCode = "US", CountryName = "United States Of America"}.Build()
                                                                                                                                 .In(_db);

                return new
                {
                    validProperty1,
                    validProperty2,
                    validProperty3,
                    validProperty4,
                    validProperty5
                };
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void ReturnsNullWhenValidPropertyNotFoundForGivenCountryAndPropertyCode()
            {
                var f = new ValidPropertyTypesFixture(Db);

                var result = f.Subject.GetValidPropertyType(new ValidPropertyIdentifier("XXX", "YYY"));

                Assert.Null(result);
            }

            [Fact]
            public void ReturnValidPropertyForGivenCountryAndPropertyCode()
            {
                var f = new ValidPropertyTypesFixture(Db);
                var data = f.SetUpPropertyTypes();
                var result =
                    f.Subject.GetValidPropertyType(new ValidPropertyIdentifier(data.validProperty1.CountryId, data.validProperty1.PropertyTypeId));

                Assert.NotNull(result);
                Assert.Equal(data.validProperty1.CountryId, result.Jurisdictions.First().Code);
                Assert.Equal(data.validProperty1.PropertyTypeId, result.PropertyType.Code);
            }
        }

        public class SaveMethod : FactBase
        {
            PropertyTypeSaveDetails PrepareSave()
            {
                return new PropertyTypeSaveDetails
                {
                    Jurisdictions = new[]
                    {
                        new CountryModel
                        {
                            Code = Fixture.String("CountryId1")
                        },
                        new CountryModel
                        {
                            Code = Fixture.String("CountryId2")
                        }
                    },
                    PropertyType = new PropertyType {Code = Fixture.String("PropertyTypeId")},
                    AnnuityType = 0,
                    CycleOffset = 1,
                    Offset = null,
                    ValidDescription = "New Valid Property"
                };
            }

            [Fact]
            public void AddsValidPropertyForGivenJurisdictions()
            {
                var f = new ValidPropertyTypesFixture(Db);
                f.SetUpPropertyTypes();
                var inputModel = PrepareSave();

                var result =
                    f.Subject.Save(inputModel);

                Assert.Equal(result.Result, "success");
                Assert.Equal(2, ((IEnumerable<ValidPropertyIdentifier>) result.UpdatedKeys).Count());
                Assert.Equal(7, Db.Set<ValidProperty>().Count());
                Assert.Equal(inputModel.ValidDescription, Db.Set<ValidProperty>().First(_ => _.CountryId.Contains("CountryId1")).PropertyName);
                Assert.Equal(inputModel.ValidDescription, Db.Set<ValidProperty>().First(_ => _.CountryId.Contains("CountryId2")).PropertyName);
            }

            [Fact]
            public void ReturnsConfirmationValidationResultIfValidPropertyTypeExistForSome()
            {
                var f = new ValidPropertyTypesFixture(Db);
                var data = f.SetUpPropertyTypes();

                var input = new PropertyTypeSaveDetails
                {
                    Jurisdictions = new[]
                    {
                        new CountryModel {Code = data.validProperty1.CountryId, Value = data.validProperty1.Country.Name},
                        new CountryModel {Code = Fixture.String(), Value = Fixture.String()}
                    },
                    PropertyType = new PropertyType {Code = data.validProperty1.PropertyTypeId},
                    ValidDescription = Fixture.String("Valid Description")
                };

                f.Validator.DuplicateCombinationValidationResult(null, 0).ReturnsForAnyArgs(new ValidationResult {Result = "confirmation"});
                var result = f.Subject.Save(input);

                Assert.Equal("confirmation", result.Result);
            }

            [Fact]
            public void ReturnsValidationResultIfValidPropertyAlreadyExist()
            {
                var f = new ValidPropertyTypesFixture(Db);
                var data = f.SetUpPropertyTypes();

                var input = new PropertyTypeSaveDetails
                {
                    Jurisdictions = new[] {new CountryModel {Code = data.validProperty1.CountryId, Value = data.validProperty1.Country.Name}},
                    PropertyType = new PropertyType {Code = data.validProperty1.PropertyTypeId},
                    ValidDescription = Fixture.String("Valid Description")
                };
                f.Validator.DuplicateCombinationValidationResult(null, 0).ReturnsForAnyArgs(new ValidationResult {Result = "Error"});
                var result = f.Subject.Save(input);

                Assert.Equal("Error", result.Result);
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenSaveModelNotPassed()
            {
                var f = new ValidPropertyTypesFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Save(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("propertyTypeSaveDetails", exception.Message);
            }
        }

        public class UpdateMethod : FactBase
        {
            PropertyTypeSaveDetails PrepareUpdate(ValidProperty validProperty)
            {
                return new PropertyTypeSaveDetails
                {
                    Jurisdictions = new[]
                    {
                        new CountryModel
                        {
                            Code = validProperty.CountryId
                        }
                    },
                    PropertyType = new PropertyType {Code = validProperty.PropertyTypeId},
                    AnnuityType = 0,
                    CycleOffset = 1,
                    Offset = null,
                    ValidDescription = validProperty.PropertyName + "Updated"
                };
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenSaveModelNotPassed()
            {
                var f = new ValidPropertyTypesFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Update(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("propertyTypeSaveDetails", exception.Message);
            }

            [Fact]
            public void UpdatedExistingValidProperty()
            {
                var f = new ValidPropertyTypesFixture(Db);
                var propertyTypes = f.SetUpPropertyTypes();

                string countryId = propertyTypes.validProperty1.CountryId;
                string propertyTypeId = propertyTypes.validProperty1.PropertyTypeId;

                var modelToUpdate = PrepareUpdate(propertyTypes.validProperty1);

                var result = f.Subject.Update(modelToUpdate);

                Assert.Equal(result.Result, "success");
                Assert.Equal(countryId, ((ValidPropertyIdentifier) result.UpdatedKeys).CountryId);
                Assert.Equal(propertyTypeId, ((ValidPropertyIdentifier) result.UpdatedKeys).PropertyTypeId);
                Assert.Contains("Updated", Db.Set<ValidProperty>()
                                             .First(_ => _.CountryId == countryId && _.PropertyTypeId == propertyTypeId).PropertyName);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Theory]
            [InlineData("Case")]
            [InlineData("ValidBasis")]
            [InlineData("ValidAction")]
            [InlineData("ValidCategory")]
            [InlineData("ValidChecklist")]
            [InlineData("ValidRelationship")]
            [InlineData("ValidStatus")]
            [InlineData("ValidSubType")]
            [InlineData("DateOfLaw")]
            public void ReturnsErrorWithListOfIdsIfValidCombinationIsInUse(string entityName)
            {
                var f = new ValidPropertyTypesFixture(Db);
                var propertyTypes = f.SetUpPropertyTypes();

                InitializeDataForInUseTests(entityName, propertyTypes);

                var identifiers = new[]
                {
                    new ValidPropertyIdentifier(propertyTypes.validProperty1.CountryId, propertyTypes.validProperty1.PropertyTypeId)
                };

                var result = f.Subject.Delete(identifiers);

                Assert.True(result.HasError);
                Assert.True(result.InUseIds.Any());
                Assert.Equal(5, Db.Set<ValidProperty>().Count());
            }

            void InitializeDataForInUseTests(string entityName, dynamic propertyTypes)
            {
                var country = new CountryBuilder {Id = propertyTypes.validProperty1.CountryId}.Build();
                var propertyType = new PropertyTypeBuilder {Id = propertyTypes.validProperty1.PropertyTypeId}.Build();
                switch (entityName)
                {
                    case "Case":
                        new CaseBuilder
                        {
                            CountryCode = country.Id,
                            PropertyType = propertyType
                        }.Build().In(Db);
                        break;
                    case "ValidBasis":
                        new ValidBasisBuilder
                        {
                            Country = country,
                            PropertyType = propertyType
                        }.Build().In(Db);
                        break;
                    case "ValidAction":
                        new ValidActionBuilder
                        {
                            Country = country,
                            PropertyType = propertyType
                        }.Build().In(Db);
                        break;
                    case "ValidCategory":
                        new ValidCategoryBuilder
                        {
                            Country = country,
                            PropertyType = propertyType
                        }.Build().In(Db);
                        break;
                    case "ValidChecklist":
                        new ValidChecklistBuilder
                        {
                            Country = country,
                            PropertyType = propertyType
                        }.Build().In(Db);
                        break;
                    case "ValidRelationship":
                        new ValidRelationshipBuilder
                        {
                            Country = country,
                            PropertyType = propertyType
                        }.Build().In(Db);
                        break;
                    case "ValidStatus":
                        new ValidStatusBuilder
                        {
                            Country = country,
                            PropertyType = propertyType
                        }.Build().In(Db);
                        break;
                    case "ValidSubType":
                        new ValidSubTypeBuilder
                        {
                            Country = country,
                            PropertyType = propertyType
                        }.Build().In(Db);
                        break;
                    case "DateOfLaw":
                        new DateOfLawBuilder
                        {
                            CountryCode = country.Id,
                            PropertyTypeId = propertyType.Code
                        }.Build().In(Db);
                        break;
                }
            }

            [Fact]
            public void DeletesValidPropertyForGivenIdentifiers()
            {
                var f = new ValidPropertyTypesFixture(Db);
                var propertyTypes = f.SetUpPropertyTypes();

                var identifiers = new[]
                {
                    new ValidPropertyIdentifier(propertyTypes.validProperty1.CountryId, propertyTypes.validProperty1.PropertyTypeId),
                    new ValidPropertyIdentifier(propertyTypes.validProperty5.CountryId, propertyTypes.validProperty5.PropertyTypeId)
                };

                var result = f.Subject.Delete(identifiers);

                Assert.False(result.HasError);
                Assert.False(result.InUseIds.Any());
                Assert.Equal(3, Db.Set<ValidProperty>().Count());
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenDeleteModelNotPassed()
            {
                var f = new ValidPropertyTypesFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Delete(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("deleteRequestModel", exception.Message);
            }
        }
    }
}