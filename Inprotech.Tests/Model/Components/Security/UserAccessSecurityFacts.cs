using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Security
{
    public class UserAccessSecurityFacts : FactBase
    {
        [Theory]
        [InlineData(AccessPermissionLevel.Select)]
        [InlineData(AccessPermissionLevel.Delete)]
        [InlineData(AccessPermissionLevel.Insert)]
        [InlineData(AccessPermissionLevel.Update)]
        [InlineData(AccessPermissionLevel.FullAccess)]
        public void ReturnsCurrentUserRowAccessDetailsForPermissionLevel(AccessPermissionLevel accessLevel)
        {
            var f = new UserAccessSecurityFixture(Db);
            const string accessType = "C";

            var user = new User("user", false)
            {
                RowAccessPermissions =
                    new[]
                    {
                        new RowAccess
                        {
                            Details = new[]
                            {
                                new RowAccessDetail {AccessType = accessType, AccessLevel = (short) accessLevel}
                            }
                        }
                    }
            }.In(Db);

            f.SecurityContext.User.Returns(user);

            var results = f.Subject.CurrentUserRowAccessDetails(accessType, (short) accessLevel);

            Assert.Single(results);
        }

        [Theory]
        [InlineData(AccessPermissionLevel.Select, 4)]
        [InlineData(AccessPermissionLevel.Insert, 2)]
        [InlineData(AccessPermissionLevel.Update, 2)]
        [InlineData(AccessPermissionLevel.Delete, 0)]
        [InlineData(AccessPermissionLevel.FullAccess, 0)]
        public void DoesNotReturnRowAccessDetailsForHigherAccessLevel(AccessPermissionLevel accessLevel, int expectedResults)
        {
            var f = new UserAccessSecurityFixture(Db);
            const string accessType = "C";

            var user = new User("user", false)
            {
                RowAccessPermissions =
                    new[]
                    {
                        new RowAccess
                        {
                            Details = new[]
                            {
                                new RowAccessDetail {AccessType = accessType, AccessLevel = (short) AccessPermissionLevel.Select},
                                new RowAccessDetail {AccessType = accessType, AccessLevel = (short) AccessPermissionLevel.Select + (short) AccessPermissionLevel.Insert},
                                new RowAccessDetail {AccessType = accessType, AccessLevel = (short) AccessPermissionLevel.Select + (short) AccessPermissionLevel.Update},
                                new RowAccessDetail {AccessType = accessType, AccessLevel = (short) AccessPermissionLevel.Select + (short) AccessPermissionLevel.Update + (short) AccessPermissionLevel.Insert}
                            }
                        }
                    }
            }.In(Db);

            f.SecurityContext.User.Returns(user);

            var results = f.Subject.CurrentUserRowAccessDetails(accessType, (short) accessLevel);

            Assert.Equal(expectedResults, results.Count());
        }

        [Fact]
        public void HasNoRowAccessSecurityForAccessType()
        {
            var f = new UserAccessSecurityFixture(Db);
            var user = new User("user", false)
            {
                RowAccessPermissions =
                    new[] {new RowAccess {Details = new[] {new RowAccessDetail {AccessType = "C"}}}}
            }.In(Db);

            f.SecurityContext.User.Returns(user);

            var result = f.Subject.HasRowAccessSecurity("N");

            Assert.False(result);
        }

        [Fact]
        public void HasNoRowAccessSecurityForExternalUser()
        {
            var f = new UserAccessSecurityFixture(Db);
            var user = new User("user", true)
            {
                RowAccessPermissions =
                    new[] {new RowAccess {Details = new[] {new RowAccessDetail {AccessType = "C"}}}}
            }.In(Db);

            f.SecurityContext.User.Returns(user);

            var result = f.Subject.HasRowAccessSecurity("C");

            Assert.False(result);
        }

        [Fact]
        public void HasRowAccessSecurityForAccessType()
        {
            var f = new UserAccessSecurityFixture(Db);
            var user = new User("user", false)
            {
                RowAccessPermissions =
                    new[] {new RowAccess {Details = new[] {new RowAccessDetail {AccessType = "C"}}}}
            }.In(Db);

            f.SecurityContext.User.Returns(user);

            var result = f.Subject.HasRowAccessSecurity("C");

            Assert.True(result);
        }
    }

    public class UserAccessSecurityFixture : IFixture<UserAccessSecurity>
    {
        public UserAccessSecurityFixture(InMemoryDbContext db)
        {
            SecurityContext = Substitute.For<ISecurityContext>();
            Subject = new UserAccessSecurity(db, SecurityContext);
        }

        public ISecurityContext SecurityContext { get; set; }
        public UserAccessSecurity Subject { get; }
    }
}