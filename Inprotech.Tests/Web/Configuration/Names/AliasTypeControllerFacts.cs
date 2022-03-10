using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.Names;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Names
{
    public class AliasTypeControllerFacts : FactBase
    {
        public class AliasTypeControllerFixture : IFixture<AliasTypeController>
        {
            readonly InMemoryDbContext _db;

            public AliasTypeControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                Subject = new AliasTypeController(db, Substitute.For<IPreferredCultureResolver>());
            }

            public AliasTypeController Subject { get; }

            public List<NameAliasType> PrepareData()
            {
                var nameAliasType1 = new NameAliasType {Id = 1, Code = "AA", Description = "CPA Accounts Alias", IsUnique = true}.In(_db);
                var nameAliasType2 = new NameAliasType {Id = 2, Code = "_C", Description = "Accounts No 3", IsUnique = false}.In(_db);
                var nameAliasType3 = new NameAliasType {Id = 3, Code = "IU", Description = "Intranet User Enquiry", IsUnique = true}.In(_db);
                var nameAliasTypeslist = new List<NameAliasType> {nameAliasType1, nameAliasType2, nameAliasType3};
                return nameAliasTypeslist;
            }

            public NameAliasTypeModel GetNameAliasTypeModel()
            {
                return new NameAliasTypeModel
                {
                    Code = "AA",
                    Description = "New Name Alias Type",
                    IsUnique = true
                };
            }
        }

        public class SearchMethod : FactBase
        {
            [Fact]
            public void ShouldReturnListOfMatchingNameAliasTypesWhenSearchOptionIsProvided()
            {
                var f = new AliasTypeControllerFixture(Db);
                var nameAliasTypes = f.PrepareData();
                var searchOptions = new SearchOptions
                {
                    Text = "AA"
                };

                var e = (IEnumerable<object>) f.Subject.Search(searchOptions);
                dynamic nameAliastype = e.SingleOrDefault();
                Assert.NotNull(e);
                Assert.NotNull(nameAliastype);
                Assert.Equal(nameAliastype.Code, nameAliasTypes[0].Code);
                Assert.Equal(nameAliastype.Description, nameAliasTypes[0].Description);
                Assert.Equal(nameAliastype.Id, nameAliasTypes[0].Id);
            }

            [Fact]
            public void ShouldReturnListOfNameAliasTypessWhenSearchOptionIsNotProvided()
            {
                var f = new AliasTypeControllerFixture(Db);
                var nameAliastypes = f.PrepareData();

                var e = (IEnumerable<object>) f.Subject.Search(null);
                Assert.NotNull(e);
                Assert.Equal(e.Count(), nameAliastypes.Count);
            }
        }

        public class GetNameAliasTypeMethod : FactBase
        {
            [Fact]
            public void ShouldReturnNameAliasTypeDetails()
            {
                var f = new AliasTypeControllerFixture(Db);
                var nameAliastypes = f.PrepareData();

                var r = f.Subject.GetNameAliasType(nameAliastypes[0].Id);
                Assert.Equal(nameAliastypes[0].Code, r.Code);
                Assert.Equal(nameAliastypes[0].Description, r.Description);
            }

            [Fact]
            public void ShouldThrowErrorIfNameAliasTypeNotFound()
            {
                var f = new AliasTypeControllerFixture(Db);
                var e = Record.Exception(() => f.Subject.GetNameAliasType(-200));
                Assert.IsType<HttpResponseException>(e);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void ShouldCreateNewNameAliasTypeWithGivenDetails()
            {
                var f = new AliasTypeControllerFixture(Db);
                var saveDetails = f.GetNameAliasTypeModel();
                saveDetails.Id = 1;
                var result = f.Subject.Save(saveDetails);

                var nameAliasType =
                    Db.Set<NameAliasType>().FirstOrDefault(nt => nt.Id == saveDetails.Id);

                Assert.NotNull(nameAliasType);
                Assert.Equal(saveDetails.Code, nameAliasType.Code);
                Assert.Equal(saveDetails.Description, nameAliasType.Description);
                Assert.Equal("success", result.Result);
                Assert.Equal(nameAliasType.Code, result.UpdatedId);
            }

            [Fact]
            public void ShouldReturnErrorResultWhenNameAliasTypeCodeAlreadyExist()
            {
                var f = new AliasTypeControllerFixture(Db);

                var saveDetails = f.GetNameAliasTypeModel();
                f.PrepareData();

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(1, result.Errors.Length);
                Assert.Equal("field.errors.notunique", result.Errors[0].Message);
                Assert.Equal("type", result.Errors[0].Field);
            }

            [Fact]
            public void ShouldReturnErrorResultWhenNameAliasTypeCodeIsGreaterThanTwo()
            {
                var f = new AliasTypeControllerFixture(Db);

                var saveDetails = f.GetNameAliasTypeModel();
                saveDetails.Code = "0011";

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(1, result.Errors.Length);
                Assert.Equal("The value must not be greater than 2 characters.", result.Errors[0].Message);
                Assert.Equal("code", result.Errors[0].Field);
            }

            [Fact]
            public void ShouldReturnErrorResultWhenNameAliasTypeDescriptionAlreadyExist()
            {
                var f = new AliasTypeControllerFixture(Db);

                var saveDetails = f.GetNameAliasTypeModel();
                f.PrepareData();
                saveDetails.Description = "Accounts No 3";
                saveDetails.Code = "@@";

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(1, result.Errors.Length);
                Assert.Equal("field.errors.notunique", result.Errors[0].Message);
                Assert.Equal("description", result.Errors[0].Field);
            }

            [Fact]
            public void ShouldReturnErrorResultWhenNameAliasTypeDescriptionIsGreaterThanThirty()
            {
                var f = new AliasTypeControllerFixture(Db);

                var saveDetails = f.GetNameAliasTypeModel();
                saveDetails.Description = "123456789012345678901234567890123456789012345678901";

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(1, result.Errors.Length);
                Assert.Equal("The value must not be greater than 30 characters.", result.Errors[0].Message);
                Assert.Equal("description", result.Errors[0].Field);
            }

            [Fact]
            public void ShouldThrowErrorIfNameAliasTypeDetailsNotFound()
            {
                var f = new AliasTypeControllerFixture(Db);

                var e = Record.Exception(() => f.Subject.Save(null));
                Assert.IsType<ArgumentNullException>(e);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void ShouldThrowErrorIfNameAliasTypeDetailsNull()
            {
                var f = new AliasTypeControllerFixture(Db);
                var e = Record.Exception(() => f.Subject.Update(Fixture.Integer(), null));
                Assert.IsType<ArgumentNullException>(e);
            }

            [Fact]
            public void ShouldThrowErrorIfNameAliasTypeToBeEditedNotFound()
            {
                var f = new AliasTypeControllerFixture(Db);
                var saveDetails = f.GetNameAliasTypeModel();
                var e = Record.Exception(() => f.Subject.Update(Fixture.Integer(), saveDetails));
                Assert.IsType<HttpResponseException>(e);
            }

            [Fact]
            public void ShoulReturnSuccessWhenSaved()
            {
                var f = new AliasTypeControllerFixture(Db);

                f.PrepareData();

                var saveDetails = f.GetNameAliasTypeModel();
                saveDetails.Id = 1;
                saveDetails.IsUnique = false;

                var result = f.Subject.Update(saveDetails.Id, saveDetails);
                var nameAliasType =
                    Db.Set<NameAliasType>()
                      .First(nt => nt.Id == saveDetails.Id);

                Assert.Equal("success", result.Result);
                Assert.Equal(nameAliasType.Code, result.UpdatedId);
                Assert.Equal(saveDetails.Description, nameAliasType.Description);
                Assert.Equal(saveDetails.IsUnique, nameAliasType.IsUnique);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void ShouldDeleteSuccessfully()
            {
                var f = new AliasTypeControllerFixture(Db);
                var model = f.PrepareData();

                var deleteIds = new List<int> {model[0].Id};

                var deleteRequestModel = new DeleteRequestModel {Ids = deleteIds};
                var r = f.Subject.Delete(deleteRequestModel);

                Assert.False(r.HasError);
                Assert.Empty(r.InUseIds);
                Assert.Equal(2, Db.Set<NameAliasType>().Count());
            }

            [Fact]
            public void ShouldThrowErrorIfInvalidAliasTypeIdIsProvided()
            {
                var f = new AliasTypeControllerFixture(Db);
                var ids = new List<int> {Fixture.Integer()};
                var deleteRequestModel = new DeleteRequestModel {Ids = ids};
                var e = Record.Exception(() => f.Subject.Delete(deleteRequestModel));
                Assert.IsType<HttpResponseException>(e);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) e).Response.StatusCode);
            }
        }
    }
}