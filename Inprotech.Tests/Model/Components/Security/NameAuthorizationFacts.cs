using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Security
{
    public class NameAuthorizationFacts
    {
        public class ExternalUserScenario : FactBase
        {
            INameAuthorization CreateSubject()
            {
                var user = new User(Fixture.String(), true);
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(user);

                return new NameAuthorization(Db, securityContext);
            }

            [Fact]
            public async Task ShouldIndicateNameExistsButUnauthorised()
            {
                var name = new NameBuilder(Db).Build().In(Db);

                var r = await CreateSubject().Authorize(name.Id, AccessPermissionLevel.Select);

                Assert.True(r.Exists);
                Assert.True(r.IsUnauthorized);
                Assert.Equal(ErrorTypeCode.NameNotRelatedToExternalUser.ToString(), r.ReasonCode);
            }

            [Fact]
            public async Task ShouldIndicateNameIsAuthorised()
            {
                var name = new NameBuilder(Db).Build().In(Db);
                new FilteredUserViewName().In(Db).WithKnownId(x => x.NameNo, name.Id);

                var r = await CreateSubject().Authorize(name.Id, AccessPermissionLevel.Select);

                Assert.True(r.Exists);
                Assert.False(r.IsUnauthorized);
            }

            [Fact]
            public async Task ShouldIndicateNameNotExists()
            {
                var r = await CreateSubject().Authorize(Fixture.Integer(), AccessPermissionLevel.Select);

                Assert.False(r.Exists);
            }
        }

        public class InternalUserViewOrRowLevelSecurityScenario : FactBase
        {
            public InternalUserViewOrRowLevelSecurityScenario()
            {
                _thisUser = new User(Fixture.String(), false).In(Db);
            }

            readonly User _thisUser;

            INameAuthorization CreateSubject()
            {
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(_thisUser);

                return new NameAuthorization(Db, securityContext);
            }

            [Theory]
            [InlineData(AccessPermissionLevel.Delete)]
            [InlineData(AccessPermissionLevel.Update)]
            [InlineData(AccessPermissionLevel.Insert)]
            public async Task ShouldIndicateNameNotPermittedIfNameNotAccessibleDueToRowLevelSecurity(AccessPermissionLevel requiredLevel)
            {
                var name = new NameBuilder(Db).Build().In(Db);
                new FilteredEthicalWallName().In(Db).WithKnownId(x => x.NameNo, name.Id);
                /* this user only has upto select access for the name */
                new FilteredRowSecurityName {SecurityFlag = AccessPermissionLevel.Select}.In(Db).WithKnownId(x => x.NameNo, name.Id);

                var subject = CreateSubject();

                var rowAccess = new RowAccess("full-access", Fixture.String()).In(Db);
                rowAccess.Details.Add(new RowAccessDetail("full-access") {AccessType = "N"}.In(Db));

                _thisUser.RowAccessPermissions.Add(rowAccess);

                var r = await subject.Authorize(name.Id, requiredLevel);

                Assert.True(r.Exists);
                Assert.True(r.IsUnauthorized);
                Assert.Equal(ErrorTypeCode.NoRowaccessForName.ToString(), r.ReasonCode);
            }

            [Fact]
            public async Task ShouldIndicateNameNotExists()
            {
                var r = await CreateSubject().Authorize(Fixture.Integer(), AccessPermissionLevel.Select);

                Assert.False(r.Exists);
            }

            [Fact]
            public async Task ShouldIndicateNameNotPermittedDueToEthicalWall()
            {
                var name = new NameBuilder(Db).Build().In(Db);

                var r = await CreateSubject().Authorize(name.Id, AccessPermissionLevel.Select);

                Assert.True(r.Exists);
                Assert.True(r.IsUnauthorized);
                Assert.Equal(ErrorTypeCode.EthicalWallForName.ToString(), r.ReasonCode);
            }

            [Fact]
            public async Task ShouldIndicateNameNotPermittedDueToNoRowLevelSecuritySetupForTheUser()
            {
                var name = new NameBuilder(Db).Build().In(Db);
                new FilteredEthicalWallName().In(Db).WithKnownId(x => x.NameNo, name.Id);

                var subject = CreateSubject();

                _thisUser.RowAccessPermissions.Clear();

                var otherUser = new User("other", false).In(Db);
                var rowAccess = new RowAccess("full-access", Fixture.String()).In(Db);
                rowAccess.Details.Add(new RowAccessDetail("full-access") {AccessType = "N"}.In(Db));
                otherUser.RowAccessPermissions.Add(rowAccess);

                var r = await subject.Authorize(name.Id, AccessPermissionLevel.Select);

                Assert.True(r.Exists);
                Assert.True(r.IsUnauthorized);
                Assert.Equal(ErrorTypeCode.NoRowaccessForName.ToString(), r.ReasonCode);
            }
        }

        public class InternalUserMultipleNamesScenario : FactBase
        {
            public InternalUserMultipleNamesScenario()
            {
                _thisUser = new User(Fixture.String(), false).In(Db);

                var rowAccess = new RowAccess("full-access", Fixture.String()).In(Db);
                rowAccess.Details.Add(new RowAccessDetail("full-access") {AccessType = "N"}.In(Db));

                _thisUser.RowAccessPermissions.Add(rowAccess);

                _securityContext.User.Returns(_thisUser);
            }

            readonly User _thisUser;
            readonly ISecurityContext _securityContext = Substitute.For<ISecurityContext>();

            [Fact]
            public async Task ShouldReturnOnlyUpdatableNames()
            {
                var subject = new NameAuthorization(Db, _securityContext);

                var name1FullAccess = new NameBuilder(Db).Build().In(Db);
                new FilteredEthicalWallName().In(Db).WithKnownId(x => x.NameNo, name1FullAccess.Id);
                new FilteredRowSecurityName {SecurityFlag = AccessPermissionLevel.FullAccess}.In(Db).WithKnownId(x => x.NameNo, name1FullAccess.Id);

                var name2NoEthicalWallAccess = new NameBuilder(Db).Build().In(Db);

                var name3NoRowAccess = new NameBuilder(Db).Build().In(Db);
                new FilteredEthicalWallName().In(Db).WithKnownId(x => x.NameNo, name3NoRowAccess.Id);

                var nameIds = new[] {name1FullAccess.Id, name2NoEthicalWallAccess.Id, name3NoRowAccess.Id};

                var updatability = (await subject.UpdatableNames(nameIds)).ToArray();

                Assert.Single(updatability);
                Assert.Contains(name1FullAccess.Id, updatability);
            }

            [Fact]
            public async Task ShouldReturnOnlyUpdatableNames2()
            {
                var subject = new NameAuthorization(Db, _securityContext);

                InprotechKaizen.Model.Names.Name CreateAccessibleName()
                {
                    var name = new NameBuilder(Db).Build().In(Db);
                    new FilteredEthicalWallName().In(Db).WithKnownId(x => x.NameNo, name.Id);
                    new FilteredRowSecurityName {SecurityFlag = AccessPermissionLevel.FullAccess}.In(Db).WithKnownId(x => x.NameNo, name.Id);

                    return name;
                }

                var n1 = CreateAccessibleName();
                var n2 = CreateAccessibleName();
                var n3 = CreateAccessibleName();

                var updatability = (await subject.UpdatableNames(n1.Id, n2.Id, n3.Id)).ToArray();

                Assert.Equal(3, updatability.Length);
            }

            [Fact]
            public async Task ShouldReturnOnlyViewableName1()
            {
                var subject = new NameAuthorization(Db, _securityContext);

                var name1FullAccess = new NameBuilder(Db).Build().In(Db);
                new FilteredEthicalWallName().In(Db).WithKnownId(x => x.NameNo, name1FullAccess.Id);
                new FilteredRowSecurityName {SecurityFlag = AccessPermissionLevel.FullAccess}.In(Db).WithKnownId(x => x.NameNo, name1FullAccess.Id);

                var name2NoEthicalWallAccess = new NameBuilder(Db).Build().In(Db);

                var name3NoRowAccess = new NameBuilder(Db).Build().In(Db);
                new FilteredEthicalWallName().In(Db).WithKnownId(x => x.NameNo, name3NoRowAccess.Id);

                var nameIds = new[] {name1FullAccess.Id, name2NoEthicalWallAccess.Id, name3NoRowAccess.Id};

                var viewability = (await subject.AccessibleNames(nameIds)).ToArray();

                Assert.Single(viewability);
                Assert.Contains(name1FullAccess.Id, viewability);
            }

            [Fact]
            public async Task ShouldReturnOnlyViewableNames2()
            {
                var subject = new NameAuthorization(Db, _securityContext);

                InprotechKaizen.Model.Names.Name CreateAccessibleName()
                {
                    var name = new NameBuilder(Db).Build().In(Db);
                    new FilteredEthicalWallName().In(Db).WithKnownId(x => x.NameNo, name.Id);
                    new FilteredRowSecurityName {SecurityFlag = AccessPermissionLevel.FullAccess}.In(Db).WithKnownId(x => x.NameNo, name.Id);

                    return name;
                }

                var n1 = CreateAccessibleName();
                var n2 = CreateAccessibleName();
                var n3 = CreateAccessibleName();

                var viewability = (await subject.AccessibleNames(n1.Id, n2.Id, n3.Id)).ToArray();

                Assert.Equal(3, viewability.Length);
            }
        }
    }
}