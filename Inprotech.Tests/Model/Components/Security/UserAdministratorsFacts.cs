using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using Xunit;

namespace Inprotech.Tests.Model.Components.Security
{
    public class UserAdministratorsFacts : FactBase
    {
        [Theory]
        [InlineData(true, false, false, false, false, 1, "Should return as canInsert=true")]
        [InlineData(false, true, false, false, false, 1, "Should return as canUpdate=true")]
        [InlineData(false, false, true, false, false, 1, "Should return as canDelete=true")]
        [InlineData(false, false, false, true, false, 0, "Should not return as on canExecute=true")]
        [InlineData(false, false, false, false, true, 0, "Should not return as on isMandatory=true")]
#pragma warning disable xUnit1026 // <Rule name>
        public void ReturnsForUsersWithMaintainUserPermissions(bool canInsert, bool canUpdate, bool canDelete, bool canExecute, bool isMandatory, int expectedNumberOfRowsReturned, string message)
#pragma warning restore xUnit1026
        {
            var n = new NameBuilder(Db)
                    {
                        Email = new TelecommunicationBuilder
                            {
                                TelecomNumber = "someone@cpaglobal.com"
                            }.Build()
                             .In(Db)
                    }
                    .Build()
                    .In(Db);

            var user = new UserBuilder(Db)
                       {
                           Name = n
                       }
                       .Build()
                       .In(Db);

            new PermissionsGrantedAllItem
            {
                IdentityKey = user.Id,
                CanInsert = canInsert,
                CanUpdate = canUpdate,
                CanDelete = canDelete,
                CanExecute = canExecute,
                IsMandatory = isMandatory
            }.In(Db);

            var subject = new UserAdministrators(Db, Fixture.Today);
            var r = subject.Resolve();

            Assert.Equal(expectedNumberOfRowsReturned, r.Count());
        }

        [Fact]
        public void ReturnExternalAdministratorForTheExternalUser()
        {
            var n1 = new NameBuilder(Db)
                {
                    Email = new TelecommunicationBuilder
                        {
                            TelecomNumber = "administrator@customer-domain.com"
                        }.Build()
                         .In(Db)
                }.Build()
                 .In(Db);

            var n2 = new NameBuilder(Db)
                {
                    Email = new TelecommunicationBuilder
                        {
                            TelecomNumber = "user@customer-domain.com"
                        }.Build()
                         .In(Db)
                }.Build()
                 .In(Db);

            var externalAccessAccount = new AccessAccountBuilder().Build().In(Db);

            var externalUserAdmin = new UserBuilder(Db)
                {
                    Name = n1,
                    AccessAccount = externalAccessAccount,
                    IsExternalUser = true
                }.Build()
                 .In(Db);

            var externalUser = new UserBuilder(Db)
                {
                    Name = n2,
                    AccessAccount = externalAccessAccount,
                    IsExternalUser = true
                }.Build()
                 .In(Db);

            new PermissionsGrantedAllItem
            {
                IdentityKey = externalUserAdmin.Id,
                CanInsert = true
            }.In(Db);

            var subject = new UserAdministrators(Db, Fixture.Today);
            var r = subject.Resolve(externalUser.Id).Single();

            Assert.Equal("administrator@customer-domain.com", r.Email);
            Assert.Equal(externalUserAdmin.Id, r.Id);
        }

        [Fact]
        public void ReturnsThoseWithEmailsOnly()
        {
            var user = new UserBuilder(Db)
                       {
                           Name = new NameBuilder(Db).Build().In(Db)
                       }
                       .Build()
                       .In(Db);

            new PermissionsGrantedAllItem
            {
                IdentityKey = user.Id,
                CanInsert = true,
                CanUpdate = true,
                CanDelete = true
            }.In(Db);

            var subject = new UserAdministrators(Db, Fixture.Today);

            Assert.Empty(subject.Resolve());
        }

        [Fact]
        public void ShouldNotReturnExternalAdministratorNotRelatedToTheExternalUser()
        {
            var n1 = new NameBuilder(Db)
                {
                    Email = new TelecommunicationBuilder
                        {
                            TelecomNumber = "administrator@customer-domain.com"
                        }.Build()
                         .In(Db)
                }.Build()
                 .In(Db);

            var n2 = new NameBuilder(Db)
                {
                    Email = new TelecommunicationBuilder
                        {
                            TelecomNumber = "user@customer-domain.com"
                        }.Build()
                         .In(Db)
                }.Build()
                 .In(Db);

            var externalAccessAccount = new AccessAccountBuilder().Build().In(Db);
            var otherExternalAccessAccount = new AccessAccountBuilder().Build().In(Db);

            var externalUserAdmin = new UserBuilder(Db)
                {
                    Name = n1,
                    AccessAccount = externalAccessAccount,
                    IsExternalUser = true
                }.Build()
                 .In(Db);

            var externalUser = new UserBuilder(Db)
                {
                    Name = n2,
                    AccessAccount = otherExternalAccessAccount,
                    IsExternalUser = true
                }.Build()
                 .In(Db);

            new PermissionsGrantedAllItem
            {
                IdentityKey = externalUserAdmin.Id,
                CanInsert = true
            }.In(Db);

            var subject = new UserAdministrators(Db, Fixture.Today);
            Assert.Empty(subject.Resolve(externalUser.Id));
        }
    }
}