using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.Compatibility;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Documents;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class NumberTypeMaintenanceControllerFacts : FactBase
    {
        public class NumberTypeMaintenanceControllerFixture : IFixture<NumberTypeMaintenanceController>
        {
            readonly InMemoryDbContext _db;

            public NumberTypeMaintenanceControllerFixture(InMemoryDbContext db)
            {
                _db = db;

                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                InprotechVersionChecker = Substitute.For<IInprotechVersionChecker>();

                Subject = new NumberTypeMaintenanceController(db, PreferredCultureResolver, InprotechVersionChecker);
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }

            public IInprotechVersionChecker InprotechVersionChecker { get; set; }

            public NumberTypeMaintenanceController Subject { get; }

            public NumberTypeSaveDetails GetNumberTypeSaveDetails()
            {
                var relatedEvent = new EventBuilder().Build().In(_db);
                var dataItem = new DocItem {Id = Fixture.Integer(), Name = Fixture.String(), Description = Fixture.String()}.In(_db);

                return new NumberTypeSaveDetails
                {
                    Id = 1,
                    NumberTypeCode = "T",
                    NumberTypeDescription = "New Number Type",
                    RelatedEvent = new Event {Key = relatedEvent.Id, Code = relatedEvent.Code},
                    DataItem = new DataItem {Key = dataItem.Id, Value = dataItem.Description, Code = dataItem.Name},
                    DisplayPriority = 0
                };
            }
        }

        public class SearchMethod : FactBase
        {
            public List<NumberType> PrepareData()
            {
                var numberType1 = new NumberTypeBuilder {Code = KnownNumberTypes.Application, Name = "Application No.", IssuedByIpOffice = true, RelatedEventNo = -7, DisplayPriority = 0}.Build().In(Db);
                var numberType2 = new NumberTypeBuilder {Code = KnownNumberTypes.Publication, Name = "Publication No.", IssuedByIpOffice = false, RelatedEventNo = -36, DisplayPriority = 1}.Build().In(Db);
                var numberType3 = new NumberTypeBuilder {Code = KnownNumberTypes.Registration, Name = "Registration No.", IssuedByIpOffice = true, RelatedEventNo = -8, DisplayPriority = 2}.Build().In(Db);
                var numbertypelist = new List<NumberType> {numberType1, numberType2, numberType3};

                return numbertypelist;
            }

            [Fact]
            public void ShouldReturnListOfMatchingNumnerTypesWhenSearchOptionIsProvided()
            {
                var numberTypeList = PrepareData();
                var searchOptions = new SearchOptions
                {
                    Text = KnownNumberTypes.Registration
                };
                var f = new NumberTypeMaintenanceControllerFixture(Db);

                var e = (IEnumerable<object>) f.Subject.Search(searchOptions);
                dynamic numbertype = e.SingleOrDefault();
                Assert.NotNull(e);
                Assert.NotNull(numbertype);
                Assert.Equal(numbertype.Description, numberTypeList[2].Name);
            }

            [Fact]
            public void ShouldReturnListOfNumberTypesWhenSearchOptionIsNotProvided()
            {
                var numberTypeList = PrepareData();
                var f = new NumberTypeMaintenanceControllerFixture(Db);

                var e = (IEnumerable<object>) f.Subject.Search(null);
                Assert.NotNull(e);
                Assert.Equal(e.Count(), numberTypeList.Count);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void ShouldDeleteSuccessfully()
            {
                var model = new NumberTypeBuilder().Build().In(Db);

                var deleteIds = new List<int> {model.Id};

                var deleteRequestModel = new DeleteRequestModel {Ids = deleteIds};
                var f = new NumberTypeMaintenanceControllerFixture(Db);
                var r = f.Subject.Delete(deleteRequestModel);

                Assert.False(r.HasError);
                Assert.Empty(r.InUseIds);
                Assert.False(Db.Set<NumberType>().Any());
            }
        }

        public class GetNameTypeMethod : FactBase
        {
            [Fact]
            public void ShouldReturnNumberTypeDetails()
            {
                var f = new NumberTypeMaintenanceControllerFixture(Db);

                var numberType = new NumberTypeBuilder().Build().In(Db);

                var r = f.Subject.GetNumberType(numberType.Id);
                Assert.Equal(numberType.Id, r.Id);
                Assert.Equal(numberType.NumberTypeCode, r.NumberTypeCode);
                Assert.Equal(numberType.Name, r.NumberTypeDescription);
            }

            [Fact]
            public void ShouldThrowErrorIfNumberTypeNotFound()
            {
                var f = new NumberTypeMaintenanceControllerFixture(Db);

                var e = Record.Exception(() => f.Subject.GetNumberType(1));
                Assert.IsType<HttpResponseException>(e);
            }
        }

        public class ChangeNumberTypeMethod : FactBase
        {
            [Fact]
            public void ShouldReturnErrorResultWhenNumberTypeCodeAlreadyExist()
            {
                var f = new NumberTypeMaintenanceControllerFixture(Db);

                var numberType = new NumberTypeBuilder {Code = "C"}.Build().In(Db);

                var result = f.Subject.UpdateNumberTypeCode(numberType.Id, new ChangeNumberTypeCodeDetails {Id = numberType.Id, NewNumberTypeCode = "C", NumberTypeCode = numberType.NumberTypeCode});
                Assert.Equal(result.Errors.Length, 1);
                Assert.Equal(result.Errors[0].Message, "field.errors.notunique");
                Assert.Equal(result.Errors[0].Field, "numberTypeCode");
            }

            [Fact]
            public void ShouldReturnErrorResultWhenNumberTypeCodeIsGreaterThanOne()
            {
                var f = new NumberTypeMaintenanceControllerFixture(Db);

                var numberType = new NumberTypeBuilder {Code = "C"}.Build().In(Db);

                var result = f.Subject.UpdateNumberTypeCode(numberType.Id, new ChangeNumberTypeCodeDetails {Id = numberType.Id, NewNumberTypeCode = "01", NumberTypeCode = numberType.NumberTypeCode});
                Assert.Equal(result.Errors.Length, 1);
                Assert.Equal(result.Errors[0].Message, "The value must not be greater than 1 characters.");
                Assert.Equal(result.Errors[0].Field, "newNumberTypeCode");
            }

            [Fact]
            public void ShouldThrowErrorIfNumberTypeDetailsNotFound()
            {
                var f = new NumberTypeMaintenanceControllerFixture(Db);

                var e = Record.Exception(() => f.Subject.Save(null));
                Assert.IsType<ArgumentNullException>(e);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void ShouldCreateNewNumberTypeWithGivenDetails()
            {
                var f = new NumberTypeMaintenanceControllerFixture(Db);
                f.InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).Returns(false);
                var saveDetails = f.GetNumberTypeSaveDetails();
                var result = f.Subject.Save(saveDetails);

                var numberType =
                    Db.Set<NumberType>().FirstOrDefault(nt => nt.Id == saveDetails.Id);

                Assert.NotNull(numberType);
                Assert.Equal(saveDetails.NumberTypeDescription, numberType.Name);
                Assert.Equal(saveDetails.NumberTypeCode, numberType.NumberTypeCode);
                Assert.Equal(saveDetails.IssuedByIpOffice, numberType.IssuedByIpOffice);
                Assert.Equal(saveDetails.RelatedEvent.Key, numberType.RelatedEventId);
                Assert.Equal(saveDetails.DataItem.Key, numberType.DocItemId);
                Assert.Equal("success", result.Result);
                Assert.Equal(numberType.Id, result.UpdatedId);
            }

            [Fact]
            public void ShouldReturnErrorResultWhenNumberTypeCodeAlreadyExist()
            {
                var f = new NumberTypeMaintenanceControllerFixture(Db);
                f.InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).Returns(false);
                var saveDetails = f.GetNumberTypeSaveDetails();
                new NumberTypeBuilder {Code = saveDetails.NumberTypeCode}.Build().In(Db);

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(result.Errors.Length, 1);
                Assert.Equal(result.Errors[0].Message, "field.errors.notunique");
                Assert.Equal(result.Errors[0].Field, "numberTypeCode");
            }

            [Fact]
            public void ShouldReturnErrorResultWhenNumberTypeCodeIsGreaterThanOne()
            {
                var f = new NumberTypeMaintenanceControllerFixture(Db);
                f.InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).Returns(false);
                var saveDetails = f.GetNumberTypeSaveDetails();
                saveDetails.NumberTypeCode = "01";

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(result.Errors.Length, 1);
                Assert.Equal(result.Errors[0].Message, "The value must not be greater than 1 characters.");
                Assert.Equal(result.Errors[0].Field, "numberTypeCode");
            }

            [Fact]
            public void ShouldReturnErrorResultWhenNumberTypeDescriptionIsGreaterThanThirty()
            {
                var f = new NumberTypeMaintenanceControllerFixture(Db);
                f.InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).Returns(false);
                var saveDetails = f.GetNumberTypeSaveDetails();
                saveDetails.NumberTypeDescription = "1234567890123456789012345678901";

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(result.Errors.Length, 1);
                Assert.Equal(result.Errors[0].Message, "The value must not be greater than 30 characters.");
                Assert.Equal(result.Errors[0].Field, "numberTypeDescription");
            }

            [Fact]
            public void ShouldThrowErrorIfNumberTypeDetailsNotFound()
            {
                var f = new NumberTypeMaintenanceControllerFixture(Db);
                f.InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).Returns(false);
                var e = Record.Exception(() => f.Subject.Save(null));
                Assert.IsType<ArgumentNullException>(e);
            }

            [Fact]
            public void ShouldBeAbleToSaveMoreThan1CharacterNumberTypeWhenInprotechVersionIs16()
            {
                var f = new NumberTypeMaintenanceControllerFixture(Db);
                f.InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).Returns(true);
                var saveDetails = f.GetNumberTypeSaveDetails();
                saveDetails.NumberTypeCode = "01";
                var result = f.Subject.Save(saveDetails);
                Assert.Equal("success", result.Result);
            }

            [Fact]
            public void ShouldNotBeAbleToSaveMoreThan3CharacterNumberTypeWhenInprotechVersionIs16()
            {
                var f = new NumberTypeMaintenanceControllerFixture(Db);
                f.InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).Returns(true);
                var saveDetails = f.GetNumberTypeSaveDetails();
                saveDetails.NumberTypeCode = "0123";
                var result = f.Subject.Save(saveDetails);
                Assert.Equal(result.Errors.Length, 1);
                Assert.Equal(result.Errors[0].Message, "The value must not be greater than 3 characters.");
                Assert.Equal(result.Errors[0].Field, "numberTypeCode");
            }
        }

        public class UpdateActionSequenceMethod : FactBase
        {
            public dynamic PrepareData()
            {
                var numberType1 = new NumberTypeBuilder {Code = KnownNumberTypes.Application, Name = "Application No.", IssuedByIpOffice = true, RelatedEventNo = -7, DisplayPriority = 0}.Build().In(Db);
                var numberType2 = new NumberTypeBuilder {Code = KnownNumberTypes.Publication, Name = "Publication No.", IssuedByIpOffice = false, RelatedEventNo = -36, DisplayPriority = 1}.Build().In(Db);
                var numberType3 = new NumberTypeBuilder {Code = KnownNumberTypes.Registration, Name = "Registration No.", IssuedByIpOffice = true, RelatedEventNo = -8, DisplayPriority = 2}.Build().In(Db);

                return new
                {
                    numberType1,
                    numberType2,
                    numberType3
                };
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenSaveDetailsIsPassedAsNull()
            {
                var f = new NumberTypeMaintenanceControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.UpdateNumberTypesSequence(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("saveDetails", exception.Message);
            }

            [Fact]
            public void UpdateNumberTypeSequence()
            {
                var numberTypes = PrepareData();

                var f = new NumberTypeMaintenanceControllerFixture(Db);
                var result = f.Subject.UpdateNumberTypesSequence(new[]
                {
                    new DisplayOrderSaveDetails {Id = numberTypes.numberType1.Id, DisplayPriority = 2},
                    new DisplayOrderSaveDetails {Id = numberTypes.numberType2.Id, DisplayPriority = 1},
                    new DisplayOrderSaveDetails {Id = numberTypes.numberType3.Id, DisplayPriority = 0}
                });

                Assert.Equal("success", result.Result);

                var id = (short) numberTypes.numberType1.Id;
                var displaySequence = Db.Set<NumberType>()
                                        .First(_ => _.Id == id).DisplayPriority;
                Assert.Equal(2, displaySequence);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void ShouldReturnErrorResultWhenChangedNumberTypeCodeAlreadyExist()
            {
                var f = new NumberTypeMaintenanceControllerFixture(Db);
                f.InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).Returns(false);
                var saveDetails = f.GetNumberTypeSaveDetails();

                new NumberType(saveDetails.Id, saveDetails.NumberTypeCode, "TQ", null).In(Db);
                new NumberType(Fixture.Short(), "N", "NT", null).In(Db);
                saveDetails.NumberTypeCode = "N";

                var result = f.Subject.Update((short) saveDetails.Id, saveDetails);
                Assert.Equal(result.Errors.Length, 1);
                Assert.Equal(result.Errors[0].Message, "field.errors.notunique");
                Assert.Equal(result.Errors[0].Field, "numberTypeCode");
            }

            [Fact]
            public void ShouldThrowErrorIfNumberTypeDetailsNull()
            {
                var f = new NumberTypeMaintenanceControllerFixture(Db);
                f.InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).Returns(false);
                var e = Record.Exception(() => f.Subject.Update(Fixture.Short(), null));
                Assert.IsType<ArgumentNullException>(e);
            }

            [Fact]
            public void ShouldThrowErrorIfNumberTypeToBeEditedNotFound()
            {
                var f = new NumberTypeMaintenanceControllerFixture(Db);
                f.InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).Returns(false);
                var saveDetails = f.GetNumberTypeSaveDetails();
                var e = Record.Exception(() => f.Subject.Update(Fixture.Short(), saveDetails));
                Assert.IsType<HttpResponseException>(e);
            }

            [Fact]
            public void ShoulReturnSuccessWhenSaved()
            {
                var f = new NumberTypeMaintenanceControllerFixture(Db);
                f.InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).Returns(false);
                var saveDetails = f.GetNumberTypeSaveDetails();
                new NumberType(saveDetails.Id, saveDetails.NumberTypeCode, "Number Type Code", null).In(Db);

                var result = f.Subject.Update((short) saveDetails.Id, saveDetails);
                var numberType =
                    Db.Set<NumberType>()
                      .First(nt => nt.NumberTypeCode == saveDetails.NumberTypeCode);

                Assert.Equal("success", result.Result);
                Assert.Equal(numberType.Id, result.UpdatedId);
                Assert.Equal(saveDetails.NumberTypeDescription, numberType.Name);
                Assert.Equal(saveDetails.NumberTypeCode, numberType.NumberTypeCode);
                Assert.Equal(saveDetails.IssuedByIpOffice, numberType.IssuedByIpOffice);
                Assert.Equal(saveDetails.RelatedEvent.Key, numberType.RelatedEventId);
                Assert.Equal(saveDetails.DataItem.Key, numberType.DocItemId);
            }

            [Fact]
            public void ShouldBeAbleToUpdateToMoreThan1CharacterNumberTypeWhenInprotechVersionIs16()
            {
                var f = new NumberTypeMaintenanceControllerFixture(Db);
                f.InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).Returns(true);
                var saveDetails = f.GetNumberTypeSaveDetails().In(Db);
                new NumberType(saveDetails.Id, saveDetails.NumberTypeCode, "Number Type Code", null).In(Db);
                saveDetails.NumberTypeCode = "ABC";
                var result = f.Subject.Update((short)saveDetails.Id, saveDetails);
                Assert.Equal("success", result.Result);
            }

            [Fact]
            public void ShouldNotBeAbleToUpdateToMoreThan3CharacterNumberTypeWhenInprotechVersionIs16()
            {
                var f = new NumberTypeMaintenanceControllerFixture(Db);
                f.InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).Returns(true);
                var saveDetails = f.GetNumberTypeSaveDetails();
                new NumberType(saveDetails.Id, saveDetails.NumberTypeCode, "Number Type Code", null).In(Db);
                saveDetails.NumberTypeCode = "0123";
                var result = f.Subject.Update((short)saveDetails.Id, saveDetails);
                Assert.Equal(result.Errors.Length, 1);
                Assert.Equal(result.Errors[0].Message, "The value must not be greater than 3 characters.");
                Assert.Equal(result.Errors[0].Field, "numberTypeCode");
            }
        }
    }
}