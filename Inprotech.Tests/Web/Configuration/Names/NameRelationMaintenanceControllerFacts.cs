using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.Names;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Names
{
    public class NameRelationMaintenanceControllerFacts : FactBase
    {
        public class NameRelationMaintenanceFixture : IFixture<NameRelationMaintenanceController>
        {
            readonly InMemoryDbContext _db;

            public NameRelationMaintenanceFixture(InMemoryDbContext db)
            {
                _db = db;
                LicenseSecurityProvider = Substitute.For<ILicenseSecurityProvider>();
                Subject = new NameRelationMaintenanceController(_db, Substitute.For<IPreferredCultureResolver>(), LicenseSecurityProvider);
            }

            public ILicenseSecurityProvider LicenseSecurityProvider { get; set; }

            public NameRelationMaintenanceController Subject { get; }

            public dynamic PrepareData()
            {
                var nameRelation2 = new NameRelation("TE2", Fixture.String(), Fixture.String(), (decimal) NameRelationType.Default, true, 0).In(_db);
                var nameRelation1 = new NameRelation("TE1", Fixture.String(), Fixture.String(), (decimal) NameRelationType.Default, true, 1).In(_db);

                var nameRalationModel1 = new NameRelationsModel {RelationshipCode = "TE2", IsCrmOnly = nameRelation2.CrmOnly, RelationshipDescription = nameRelation2.RelationDescription, ReverseDescription = nameRelation2.ReverseDescription, IsEmployee = true, IsIndividual = true, IsOrganisation = true, Id = nameRelation2.Id};
                var nameRalationModel2 = new NameRelationsModel {RelationshipCode = "TE3", IsCrmOnly = false, RelationshipDescription = Fixture.String(), ReverseDescription = Fixture.String(), IsEmployee = true, EthicalWall = "1"};

                return new
                {
                    nameRelation1,
                    nameRelation2,
                    nameRalationModel1,
                    nameRalationModel2
                };
            }
        }

        public class SearchMethod : FactBase
        {
            [Fact]
            public void ShouldReturnListOfMatchingNameRelationshipWhenSearchOptionIsProvided()
            {
                var f = new NameRelationMaintenanceFixture(Db);
                var data = f.PrepareData();
                var searchOptions = new NameRelationSearchOptions
                {
                    Text = data.nameRelation1.RelationshipCode
                };

                var result = (IEnumerable<dynamic>) f.Subject.Search(searchOptions);
                var enumerable = result as dynamic[] ?? result.ToArray();

                Assert.Single(enumerable);
                Assert.Equal(data.nameRelation1.RelationshipCode, enumerable.Single().RelationshipCode);
                Assert.Equal(data.nameRelation1.Id, enumerable.Single().Id);
            }

            [Fact]
            public void ShouldReturnListOfNameRelationshipWhenSearchOptionIsNotProvided()
            {
                var f = new NameRelationMaintenanceFixture(Db);
                f.PrepareData();

                var e = (IEnumerable<object>) f.Subject.Search(null);

                Assert.NotNull(e);
                Assert.Equal(2, e.Count());
            }
        }

        public class GetNameRelationMethod : FactBase
        {
            [Fact]
            public void ShouldReturnNameRelationshipDetails()
            {
                var f = new NameRelationMaintenanceFixture(Db);

                var data = f.PrepareData();

                var r = f.Subject.GetNameRelation(data.nameRelation1.Id);

                Assert.Equal(data.nameRelation1.Id, r.Id);
                Assert.Equal(data.nameRelation1.RelationshipCode, r.RelationshipCode);
            }

            [Fact]
            public void ShouldThrowErrorIfNameRelationshipNotFound()
            {
                var f = new NameRelationMaintenanceFixture(Db);
                var e = Record.Exception(() => f.Subject.GetNameRelation(-200));
                Assert.IsType<HttpResponseException>(e);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void ShouldCreateNewNameRelationshipWithGivenDetails()
            {
                var f = new NameRelationMaintenanceFixture(Db);
                f.LicenseSecurityProvider.IsLicensedForModules(Arg.Any<List<LicensedModule>>()).Returns(true);
                var data = f.PrepareData();

                var model = (NameRelationsModel) data.nameRalationModel2;

                var result = f.Subject.Save(model);

                var namerelation =
                    Db.Set<NameRelation>().Single(_ => _.RelationshipCode == model.RelationshipCode);

                Assert.NotNull(namerelation);
                Assert.Equal(model.RelationshipCode, namerelation.RelationshipCode);
                Assert.Equal("success", result.Result);
                Assert.Equal(namerelation.Id, result.UpdatedId);
            }

            [Fact]
            public void ShouldReturnedErrorWhenRequiredFieldsAreNotProvided()
            {
                var f = new NameRelationMaintenanceFixture(Db);
                var result = f.Subject.Save(new NameRelationsModel());
                Assert.Equal(6, result.Errors.Length);
                Assert.Equal("field.errors.required", result.Errors[0].Message);
                Assert.Equal("relationshipCode", result.Errors[0].Field);
                Assert.Equal("field.errors.required", result.Errors[1].Message);
                Assert.Equal("relationshipDescription", result.Errors[1].Field);
                Assert.Equal("field.errors.required", result.Errors[2].Message);
                Assert.Equal("reverseDescription", result.Errors[2].Field);
                Assert.Equal(ConfigurationResources.NameRelationAtleastOneOptionRequired, result.Errors[3].Message);
                Assert.Equal("isEmployee", result.Errors[3].Field);
                Assert.Equal(ConfigurationResources.NameRelationAtleastOneOptionRequired, result.Errors[4].Message);
                Assert.Equal("isIndividual", result.Errors[4].Field);
                Assert.Equal(ConfigurationResources.NameRelationAtleastOneOptionRequired, result.Errors[5].Message);
                Assert.Equal("isOrganisation", result.Errors[5].Field);
            }

            [Fact]
            public void ShouldReturnErrorResultWhenNameRelationshipCodeIsNotUnique()
            {
                var f = new NameRelationMaintenanceFixture(Db);
                var data = f.PrepareData();
                var result = f.Subject.Save(data.nameRalationModel1);
                Assert.Equal(3, result.Errors.Length);
                Assert.Equal("field.errors.notunique", result.Errors[0].Message);
                Assert.Equal("relationshipCode", result.Errors[0].Field);
                Assert.Equal("field.errors.notunique", result.Errors[1].Message);
                Assert.Equal("relationshipDescription", result.Errors[1].Field);
                Assert.Equal("field.errors.notunique", result.Errors[2].Message);
                Assert.Equal("reverseDescription", result.Errors[2].Field);
            }

            [Fact]
            public void ShouldThrowErrorIfNameRelationshipNotFound()
            {
                var f = new NameRelationMaintenanceFixture(Db);

                var e = Record.Exception(() => f.Subject.Save(null));
                Assert.IsType<ArgumentNullException>(e);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void ShouldThrowErrorIfNameRelationshipDetailsNull()
            {
                var f = new NameRelationMaintenanceFixture(Db);
                var e = Record.Exception(() => f.Subject.Update(Fixture.Integer(), null));
                Assert.IsType<ArgumentNullException>(e);
            }

            [Fact]
            public void ShouldThrowErrorIfNameRelationshipToBeEditedNotFound()
            {
                var f = new NameRelationMaintenanceFixture(Db);
                var data = (NameRelationsModel) f.PrepareData().nameRalationModel2;
                var e = Record.Exception(() => f.Subject.Update(data.Id, data));
                Assert.IsType<HttpResponseException>(e);
            }

            [Fact]
            public void ShoulReturnSuccessWhenSaved()
            {
                var f = new NameRelationMaintenanceFixture(Db);

                var data = f.PrepareData();
                var model = (NameRelationsModel) data.nameRalationModel1;
                model.RelationshipDescription = "updated description";
                model.ReverseDescription = "updated rev desc";
                model.IsCrmOnly = true;
                f.LicenseSecurityProvider.IsLicensedForModules(Arg.Any<List<LicensedModule>>()).Returns(true);
                var result = f.Subject.Update(model.Id, model);

                var nameRelation =
                    Db.Set<NameRelation>()
                      .First(_ => _.Id == model.Id);

                Assert.Equal("success", result.Result);
                Assert.Equal(nameRelation.Id, result.UpdatedId);
                Assert.Equal(model.RelationshipCode, nameRelation.RelationshipCode);
                Assert.Equal(model.RelationshipDescription, nameRelation.RelationDescription);
                Assert.Equal(model.ReverseDescription, nameRelation.ReverseDescription);
                Assert.Equal(model.IsCrmOnly, nameRelation.CrmOnly);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void ShouldDeleteSuccessfully()
            {
                var f = new NameRelationMaintenanceFixture(Db);
                var data = f.PrepareData();

                var deleteIds = new List<int> {data.nameRalationModel1.Id};

                var deleteRequestModel = new DeleteRequestModel {Ids = deleteIds};

                var r = f.Subject.Delete(deleteRequestModel);

                Assert.False(r.HasError);
                Assert.Empty(r.InUseIds);
                Assert.Single(Db.Set<NameRelation>());
            }

            [Fact]
            public void ShouldThrowErrorIfInvalidNameRelationshipIdIsProvided()
            {
                var f = new NameRelationMaintenanceFixture(Db);

                var ids = new List<int> {Fixture.Integer()};

                var deleteRequestModel = new DeleteRequestModel {Ids = ids};
                var e = Record.Exception(() => f.Subject.Delete(deleteRequestModel));

                Assert.IsType<HttpResponseException>(e);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) e).Response.StatusCode);
            }
        }
    }
}