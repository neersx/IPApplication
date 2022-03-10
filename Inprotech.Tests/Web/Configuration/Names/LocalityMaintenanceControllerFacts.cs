using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.Names;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Names
{
    public class LocalityMaintenanceControllerFacts : FactBase
    {
        public class LocalityMaintenanceControllerFixture : IFixture<LocalityMaintenanceController>
        {
            readonly InMemoryDbContext _db;

            public LocalityMaintenanceControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                Subject = new LocalityMaintenanceController(db, Substitute.For<IPreferredCultureResolver>());
            }

            public LocalityMaintenanceController Subject { get; }

            public dynamic PrepareData()
            {
                var au = new Country("AU", "Australia").In(_db);

                var vic = new State {CountryCode = au.Id, Code = "VIC", Name = "Victoria"}.In(_db);
                var nsw = new State {CountryCode = au.Id, Code = "NSW", Name = "New South Wales"}.In(_db);

                var mel = new Locality("MEL", "Melbourne Area", "Melbourne", vic, au).In(_db);
                var syd = new Locality("SYD", "Sydney Area", "Sydney", nsw, au).In(_db);

                return new
                {
                    mel,
                    syd
                };
            }
        }

        public class SearchMethod : FactBase
        {
            [Fact]
            public void ShouldReturnListOfLocalityWhenSearchOptionIsNotProvided()
            {
                var f = new LocalityMaintenanceControllerFixture(Db);
                f.PrepareData();

                var e = (IEnumerable<object>) f.Subject.Search(null);

                Assert.NotNull(e);
                Assert.Equal(2, e.Count());
            }

            [Fact]
            public void ShouldReturnListOfMatchingLocalityWhenSearchOptionIsProvided()
            {
                var f = new LocalityMaintenanceControllerFixture(Db);
                var localities = f.PrepareData();
                var searchOptions = new SearchOptions
                {
                    Text = "Mel"
                };

                var result = (IEnumerable<dynamic>) f.Subject.Search(searchOptions);
                var enumerable = result as dynamic[] ?? result.ToArray();

                Assert.Single(enumerable);
                Assert.Equal(localities.mel.Code, enumerable.Single().Code);
                Assert.Equal(localities.mel.Name, enumerable.Single().Name);
            }
        }

        public class GetLocalityMethod : FactBase
        {
            [Fact]
            public void ShouldReturnLocalityDetails()
            {
                var f = new LocalityMaintenanceControllerFixture(Db);

                var localities = f.PrepareData();

                var r = f.Subject.GetLocality(localities.mel.Id);

                Assert.Equal(localities.mel.Code, r.Code);
                Assert.Equal(localities.mel.Name, r.Name);
            }

            [Fact]
            public void ShouldThrowErrorIfLocalityNotFound()
            {
                var f = new LocalityMaintenanceControllerFixture(Db);
                var e = Record.Exception(() => f.Subject.GetLocality(-200));
                Assert.IsType<HttpResponseException>(e);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void ShouldCreateNewLocalityWithGivenDetails()
            {
                var f = new LocalityMaintenanceControllerFixture(Db);

                var saveDetails = new LocalitySaveDetails
                {
                    Code = "MEL12",
                    Name = "melbourne city"
                };

                var result = f.Subject.Save(saveDetails);

                var locality =
                    Db.Set<Locality>().Single(l => l.Code == saveDetails.Code);

                Assert.NotNull(locality);
                Assert.Equal(saveDetails.Code, locality.Code);
                Assert.Equal(saveDetails.Name, locality.Name);
                Assert.Equal("success", result.Result);
                Assert.Equal(locality.Id, result.UpdatedId);
            }

            [Fact]
            public void ShouldReturnErrorResultWhenLocalityAlreadyExists()
            {
                var f = new LocalityMaintenanceControllerFixture(Db);
                f.PrepareData();

                var saveDetails = new LocalitySaveDetails
                {
                    Code = "MEL"
                };

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(1, result.Errors.Length);
                Assert.Equal("field.errors.notunique", result.Errors[0].Message);
                Assert.Equal("code", result.Errors[0].Field);
            }

            [Fact]
            public void ShouldReturnErrorResultWhenLocalityCodeIsGreaterThanFive()
            {
                var f = new LocalityMaintenanceControllerFixture(Db);

                var saveDetails = new LocalitySaveDetails
                {
                    Code = "MEL112"
                };

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(1, result.Errors.Length);
                Assert.Equal("The value must not be greater than 5 characters.", result.Errors[0].Message);
                Assert.Equal("code", result.Errors[0].Field);
            }

            [Fact]
            public void ShouldReturnErrorResultWhenLocalityNameIsGreaterThanThirty()
            {
                var f = new LocalityMaintenanceControllerFixture(Db);

                var saveDetails = new LocalitySaveDetails
                {
                    Code = "MEL11",
                    Name = "123456789012345678901234567890123456789012345678901"
                };

                var result = f.Subject.Save(saveDetails);

                Assert.Equal(1, result.Errors.Length);
                Assert.Equal("The value must not be greater than 30 characters.", result.Errors[0].Message);
                Assert.Equal("name", result.Errors[0].Field);
            }

            [Fact]
            public void ShouldThrowErrorIfLocalityDetailsNotFound()
            {
                var f = new LocalityMaintenanceControllerFixture(Db);

                var e = Record.Exception(() => f.Subject.Save(null));
                Assert.IsType<ArgumentNullException>(e);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void ShouldThrowErrorIfLocalityDetailsNull()
            {
                var f = new LocalityMaintenanceControllerFixture(Db);
                var e = Record.Exception(() => f.Subject.Update(Fixture.Integer(), null));
                Assert.IsType<ArgumentNullException>(e);
            }

            [Fact]
            public void ShouldThrowErrorIfLocalityToBeEditedNotFound()
            {
                var f = new LocalityMaintenanceControllerFixture(Db);

                var e = Record.Exception(() => f.Subject.Update(Fixture.Integer(), new LocalitySaveDetails {Code = "12", Name = "123456"}));
                Assert.IsType<HttpResponseException>(e);
            }

            [Fact]
            public void ShoulReturnSuccessWhenSaved()
            {
                var f = new LocalityMaintenanceControllerFixture(Db);

                var data = f.PrepareData();

                var saveDetails = new LocalitySaveDetails {Code = "MEL", Name = "Melbourne area modified"};

                var id = (int) data.mel.Id;
                saveDetails.Id = id;
                var result = f.Subject.Update(id, saveDetails);

                var locality =
                    Db.Set<Locality>()
                      .First(nt => nt.Id == id);

                Assert.Equal("success", result.Result);
                Assert.Equal(locality.Id, result.UpdatedId);
                Assert.Equal(saveDetails.Name, locality.Name);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void ShouldDeleteSuccessfully()
            {
                var f = new LocalityMaintenanceControllerFixture(Db);
                var data = f.PrepareData();

                var deleteIds = new List<int> {data.mel.Id};

                var deleteRequestModel = new DeleteRequestModel {Ids = deleteIds};

                var r = f.Subject.Delete(deleteRequestModel);

                Assert.False(r.HasError);
                Assert.Empty(r.InUseIds);
                Assert.Single(Db.Set<Locality>());
            }

            [Fact]
            public void ShouldThrowErrorIfInvalidLocalityIdIsProvided()
            {
                var f = new LocalityMaintenanceControllerFixture(Db);

                var ids = new List<int> {Fixture.Integer()};

                var deleteRequestModel = new DeleteRequestModel {Ids = ids};
                var e = Record.Exception(() => f.Subject.Delete(deleteRequestModel));

                Assert.IsType<HttpResponseException>(e);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) e).Response.StatusCode);
            }
        }
    }
}