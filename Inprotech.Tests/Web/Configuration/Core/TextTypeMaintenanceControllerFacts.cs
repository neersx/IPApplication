using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class TextTypeMaintenanceControllerFacts : FactBase
    {
        public static TextTypeModel GetTextTypeSaveDetails()
        {
            return new TextTypeModel
            {
                Id = "T",
                Description = "New Text Type",
                UsedByName = true,
                UsedByIndividual = true
            };
        }

        public class TextTypeMaintenanceControllerFixture : IFixture<TextTypeMaintenanceController>
        {
            public TextTypeMaintenanceControllerFixture(InMemoryDbContext db)
            {
                DbContext = db;
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                Subject = new TextTypeMaintenanceController(DbContext, PreferredCultureResolver);
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }

            public InMemoryDbContext DbContext { get; }
            public TextTypeMaintenanceController Subject { get; }
        }

        public class SearchMethod : FactBase
        {
            public List<TextType> PrepareData()
            {
                var texttype1 = new TextTypeBuilder {Id = "_B", Description = "Billing", UsedByFlag = 2}.Build().In(Db);
                var texttype2 = new TextTypeBuilder {Id = "A", Description = "Abstract", UsedByFlag = 0}.Build().In(Db);

                var texttype3 = new TextTypeBuilder {Id = "C", Description = "Int'l Patent Classification", UsedByFlag = 3}.Build().In(Db);
                var texttypelist = new List<TextType> {texttype1, texttype2, texttype3};

                return texttypelist;
            }

            [Fact]
            public void ShouldReturnListOfMatchingTextTypesWhenSearchOptionIsProvided()
            {
                var texttypes = PrepareData();
                var searchOptions = new SearchOptions
                {
                    Text = "Billing"
                };
                var f = new TextTypeMaintenanceControllerFixture(Db);

                var e = (IEnumerable<object>) f.Subject.Search(searchOptions);
                dynamic texttype = e.SingleOrDefault();
                Assert.NotNull(e);
                Assert.NotNull(texttype);
                Assert.Equal(texttype.Description, texttypes[0].TextDescription);
                Assert.Equal(texttype.Id, texttypes[0].Id);
            }

            [Fact]
            public void ShouldReturnListOfTextTypessWhenSearchOptionIsNotProvided()
            {
                var texttypes = PrepareData();
                var f = new TextTypeMaintenanceControllerFixture(Db);

                var e = (IEnumerable<object>) f.Subject.Search(null);
                Assert.NotNull(e);
                Assert.Equal(e.Count(), texttypes.Count);
            }
        }

        public class GetTextTypeMethod : FactBase
        {
            [Fact]
            public void ShouldReturnTextTypeDetails()
            {
                var f = new TextTypeMaintenanceControllerFixture(Db);

                var textType = new TextTypeBuilder().Build().In(Db);

                var r = f.Subject.GetTextType(textType.Id);
                Assert.Equal(textType.Id, r.Id);
                Assert.Equal(textType.TextDescription, r.Description);
            }

            [Fact]
            public void ShouldThrowErrorIfTextTypeNotFound()
            {
                var f = new TextTypeMaintenanceControllerFixture(Db);

                var e = Record.Exception(() => f.Subject.GetTextType("A"));
                Assert.IsType<HttpResponseException>(e);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void ShouldCreateNewTextTypeWithGivenDetails()
            {
                var f = new TextTypeMaintenanceControllerFixture(Db);
                var saveDetails = GetTextTypeSaveDetails();
                var result = f.Subject.Save(saveDetails);

                var textType =
                    Db.Set<TextType>().FirstOrDefault(nt => nt.Id == saveDetails.Id);

                Assert.NotNull(textType);
                Assert.Equal(saveDetails.Description, textType.TextDescription);
                Assert.Equal(saveDetails.Id, textType.Id);
                Assert.Equal(saveDetails.UsedByCase, textType.UsedByCase);
                Assert.Equal(saveDetails.UsedByEmployee, textType.UsedByEmployee);
                Assert.Equal(saveDetails.UsedByIndividual, textType.UsedByIndividual);
                Assert.Equal(saveDetails.UsedByOrganisation, textType.UsedByOrganisation);
                Assert.Equal("success", result.Result);
                Assert.Equal(textType.Id, result.UpdatedId);
            }

            [Fact]
            public void ShouldReturnErrorResultWhenTextTypeCodeAlreadyExist()
            {
                var f = new TextTypeMaintenanceControllerFixture(Db);

                var saveDetails = GetTextTypeSaveDetails();
                new TextTypeBuilder {Id = saveDetails.Id}.Build().In(Db);

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(1, result.Errors.Length);
                Assert.Equal("field.errors.notunique", result.Errors[0].Message);
                Assert.Equal("textTypeCode", result.Errors[0].Field);
            }

            [Fact]
            public void ShouldReturnErrorResultWhenTextTypeCodeIsGreaterThanOne()
            {
                var f = new TextTypeMaintenanceControllerFixture(Db);

                var saveDetails = GetTextTypeSaveDetails();
                saveDetails.Id = "011";

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(1, result.Errors.Length);
                Assert.Equal("The value must not be greater than 2 characters.", result.Errors[0].Message);
                Assert.Equal("id", result.Errors[0].Field);
            }

            [Fact]
            public void ShouldReturnErrorResultWhenTextTypeDescriptionIsGreaterThanThirty()
            {
                var f = new TextTypeMaintenanceControllerFixture(Db);

                var saveDetails = GetTextTypeSaveDetails();
                saveDetails.Description = "123456789012345678901234567890123456789012345678901";

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(1, result.Errors.Length);
                Assert.Equal("The value must not be greater than 50 characters.", result.Errors[0].Message);
                Assert.Equal("description", result.Errors[0].Field);
            }

            [Fact]
            public void ShouldThrowErrorIfTextTypeDetailsNotFound()
            {
                var f = new TextTypeMaintenanceControllerFixture(Db);

                var e = Record.Exception(() => f.Subject.Save(null));
                Assert.IsType<ArgumentNullException>(e);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void ShouldThrowErrorIfTextTypeDetailsNull()
            {
                var f = new TextTypeMaintenanceControllerFixture(Db);

                var e = Record.Exception(() => f.Subject.Update(Fixture.String(), null));
                Assert.IsType<ArgumentNullException>(e);
            }

            [Fact]
            public void ShouldThrowErrorIfTextTypeToBeEditedNotFound()
            {
                var f = new TextTypeMaintenanceControllerFixture(Db);
                var saveDetails = GetTextTypeSaveDetails();
                var e = Record.Exception(() => f.Subject.Update(Fixture.String(), saveDetails));
                Assert.IsType<HttpResponseException>(e);
            }

            [Fact]
            public void ShoulReturnSuccessWhenSaved()
            {
                var f = new TextTypeMaintenanceControllerFixture(Db);

                var saveDetails = GetTextTypeSaveDetails();
                new TextTypeBuilder {Description = "Text Type Code", Id = saveDetails.Id, UsedByFlag = 2}.Build().In(Db);

                var result = f.Subject.Update(saveDetails.Id, saveDetails);
                var textType =
                    Db.Set<TextType>()
                      .First(nt => nt.Id == saveDetails.Id);

                Assert.Equal("success", result.Result);
                Assert.Equal(textType.Id, result.UpdatedId);
                Assert.Equal(saveDetails.Description, textType.TextDescription);
                Assert.Equal(saveDetails.UsedByCase, textType.UsedByCase);
                Assert.Equal(saveDetails.UsedByName, textType.UsedByEmployee || textType.UsedByIndividual || textType.UsedByOrganisation);
                Assert.Equal(saveDetails.UsedByEmployee, textType.UsedByEmployee);
                Assert.Equal(saveDetails.UsedByIndividual, textType.UsedByIndividual);
                Assert.Equal(saveDetails.UsedByOrganisation, textType.UsedByOrganisation);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void ShouldDeleteSuccessfully()
            {
                var model = new TextTypeBuilder {Id = "B", Description = "Billing", UsedByFlag = 2}.Build().In(Db);

                var deleteIds = new List<string> {model.Id};

                var deleteRequestModel = new TextTypeDeleteRequestModel {Ids = deleteIds};
                var f = new TextTypeMaintenanceControllerFixture(Db);
                var r = f.Subject.Delete(deleteRequestModel);

                Assert.False(r.HasError);
                Assert.Empty(r.InUseIds);
                Assert.False(Db.Set<TextType>().Any());
            }

            [Fact]
            public void ShouldThrowErrorIfInvalidTextTypeIdIsProvided()
            {
                var f = new TextTypeMaintenanceControllerFixture(Db);
                var ids = new List<string> {Fixture.String()};
                var deleteRequestModel = new TextTypeDeleteRequestModel {Ids = ids};
                var e = Record.Exception(() => f.Subject.Delete(deleteRequestModel));
                Assert.IsType<HttpResponseException>(e);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) e).Response.StatusCode);
            }
        }

        public class ChangeTextTypeMethod : FactBase
        {
            [Fact]
            public void ShouldReturnErrorResultWhenNewTextTypeCodeAlreadyExist()
            {
                var f = new TextTypeMaintenanceControllerFixture(Db);

                var textType = new TextTypeBuilder {Id = "C"}.Build().In(Db);

                var result = f.Subject.UpdateTextTypeCode(textType.Id, new ChangeTextTypeCodeDetails {Id = textType.Id, NewTextTypeCode = "C"});
                Assert.Equal(1, result.Errors.Length);
                Assert.Equal("field.errors.notunique", result.Errors[0].Message);
                Assert.Equal("textTypeCode", result.Errors[0].Field);
            }

            [Fact]
            public void ShouldReturnErrorResultWhenNewTextTypeCodeLengthIsGreaterThanTwo()
            {
                var f = new TextTypeMaintenanceControllerFixture(Db);

                var textType = new TextTypeBuilder {Id = "C"}.Build().In(Db);

                var result = f.Subject.UpdateTextTypeCode(textType.Id, new ChangeTextTypeCodeDetails {Id = textType.Id, NewTextTypeCode = "011"});
                Assert.Equal(1, result.Errors.Length);
                Assert.Equal("The value must not be greater than 2 characters.", result.Errors[0].Message);
                Assert.Equal("newTextTypeCode", result.Errors[0].Field);
            }

            [Fact]
            public void ShouldThrowErrorIfTextTypeDetailsNotFound()
            {
                var f = new TextTypeMaintenanceControllerFixture(Db);

                var e = Record.Exception(() => f.Subject.Save(null));
                Assert.IsType<ArgumentNullException>(e);
            }
        }
    }
}