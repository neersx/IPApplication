using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using Xunit;

namespace Inprotech.Tests.Model.Components.Security
{
    public class FunctionSecurityProviderFacts
    {
        public class FunctionSecurityFor : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ReturnsForMatchingFunctionOnly(bool expected)
            {
                var user = new UserBuilder(Db).Build();
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = expected ? (short)1 : (short)0, AccessStaffId = user.NameId }.In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.Billing, AccessPrivileges = expected ? (short)0 : (short)1, AccessStaffId = user.NameId }.In(Db);
                var f = new FunctionSecurityProviderFixture(Db);
                var result = await f.Subject.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanRead, user);
                Assert.Equal(expected, result);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ReturnsForNameFamily(bool expected)
            {
                var staff = new NameBuilder(Db).WithFamily().Build().In(Db);
                var user = new UserBuilder(Db) { Name = staff }.Build();
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = expected ? (short)1 : (short)0, AccessGroup = staff.NameFamily.Id }.In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = expected ? (short)0 : (short)1, AccessGroup = Fixture.Short() }.In(Db);
                var f = new FunctionSecurityProviderFixture(Db);
                var result = await f.Subject.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanRead, user);
                Assert.Equal(expected, result);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task PrefersStaffNameOverNameFamily(bool expected)
            {
                var staff = new NameBuilder(Db).WithFamily().Build().In(Db);
                var user = new UserBuilder(Db) { Name = staff }.Build();
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = expected ? (short)1 : (short)0, AccessStaffId = user.NameId, AccessGroup = staff.NameFamily.Id }.In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = expected ? (short)0 : (short)1, AccessStaffId = user.NameId + 1, AccessGroup = staff.NameFamily.Id }.In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = expected ? (short)0 : (short)1, AccessGroup = staff.NameFamily.Id }.In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = expected ? (short)0 : (short)1, AccessGroup = Fixture.Short() }.In(Db);
                var f = new FunctionSecurityProviderFixture(Db);
                var result = await f.Subject.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanRead, user);
                Assert.Equal(expected, result);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task PrefersOwnerNameOverStaffName(bool expected)
            {
                var newNameId = Fixture.Integer();
                new NameBuilder(Db).Build().WithKnownId(newNameId).In(Db);
                var staff = new NameBuilder(Db).WithFamily().Build().In(Db);
                var user = new UserBuilder(Db) { Name = staff }.Build();
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = expected ? (short)1 : (short)0, OwnerId = newNameId, AccessStaffId = user.NameId, AccessGroup = staff.NameFamily.Id }.In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = expected ? (short)0 : (short)1, OwnerId = newNameId + 1, AccessStaffId = user.NameId, AccessGroup = staff.NameFamily.Id }.In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = expected ? (short)0 : (short)1, AccessStaffId = user.NameId, AccessGroup = staff.NameFamily.Id }.In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = expected ? (short)0 : (short)1, AccessStaffId = user.NameId + 1, AccessGroup = staff.NameFamily.Id }.In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = expected ? (short)0 : (short)1, AccessGroup = staff.NameFamily.Id }.In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = expected ? (short)0 : (short)1, AccessGroup = Fixture.Short() }.In(Db);
                var f = new FunctionSecurityProviderFixture(Db);
                var result = await f.Subject.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanRead, user, newNameId);
                Assert.Equal(expected, result);
            }

            [Theory]
            [InlineData(FunctionSecurityPrivilege.CanRead)]
            [InlineData(FunctionSecurityPrivilege.CanInsert)]
            [InlineData(FunctionSecurityPrivilege.CanUpdate)]
            [InlineData(FunctionSecurityPrivilege.CanDelete)]
            [InlineData(FunctionSecurityPrivilege.CanPost)]
            [InlineData(FunctionSecurityPrivilege.CanFinalise)]
            [InlineData(FunctionSecurityPrivilege.CanReverse)]
            [InlineData(FunctionSecurityPrivilege.CanCredit)]
            [InlineData(FunctionSecurityPrivilege.CanAdjustValue)]
            [InlineData(FunctionSecurityPrivilege.CanConvert)]
            public async Task ReturnsRequiredPrivilege(FunctionSecurityPrivilege required)
            {
                var otherPrivilege = required - 1;
                var newNameId = Fixture.Integer();
                new NameBuilder(Db).Build().WithKnownId(newNameId).In(Db);
                var staff = new NameBuilder(Db).WithFamily().Build().In(Db);
                var user = new UserBuilder(Db) { Name = staff }.Build();
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = (short)required, OwnerId = newNameId, AccessStaffId = user.NameId, AccessGroup = staff.NameFamily.Id }.In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = (short)otherPrivilege, OwnerId = newNameId, AccessStaffId = user.NameId, AccessGroup = staff.NameFamily.Id }.In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = (short)otherPrivilege, OwnerId = newNameId + 1, AccessStaffId = user.NameId, AccessGroup = staff.NameFamily.Id }.In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = (short)otherPrivilege, AccessStaffId = user.NameId, AccessGroup = staff.NameFamily.Id }.In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = (short)otherPrivilege, AccessStaffId = user.NameId + 1, AccessGroup = staff.NameFamily.Id }.In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = (short)otherPrivilege, AccessGroup = staff.NameFamily.Id }.In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.TimeRecording, AccessPrivileges = (short)otherPrivilege, AccessGroup = Fixture.Short() }.In(Db);
                var f = new FunctionSecurityProviderFixture(Db);
                var result = await f.Subject.FunctionSecurityFor(BusinessFunction.TimeRecording, required, user, newNameId);
                Assert.Equal(true, result);
            }
            
            [Theory]
            [InlineData(FunctionSecurityPrivilege.CanDelete, 11)]
            [InlineData(FunctionSecurityPrivilege.CanUpdate, 22)]
            public async Task VerifyFunctionSecurityForReminder(FunctionSecurityPrivilege given, int expectedNameId)
            {
                var f = new FunctionSecurityProviderFixture(Db);
                var staff = new NameBuilder(Db).WithFamily().Build().In(Db);
                var user = new UserBuilder(Db) { Name = staff }.Build();
                var newNameId = Fixture.Integer();
                new NameBuilder(Db).Build().WithKnownId(expectedNameId).In(Db);
                new NameBuilder(Db).Build().WithKnownId(newNameId).In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.Reminder, AccessPrivileges = (short)FunctionSecurityPrivilege.CanUpdate, OwnerId = expectedNameId, AccessStaffId = user.NameId, AccessGroup = staff.NameFamily.Id }.In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.Reminder, AccessPrivileges = (short)FunctionSecurityPrivilege.CanDelete, OwnerId = expectedNameId, AccessStaffId = user.NameId, AccessGroup = staff.NameFamily.Id }.In(Db);
                var result = await f.Subject.FunctionSecurityFor(BusinessFunction.Reminder, given, user, new[] { expectedNameId, newNameId });
                Assert.Equal(new[] { expectedNameId, user.NameId }, result);
            }

            [Theory]
            [InlineData(FunctionSecurityPrivilege.CanDelete)]
            [InlineData(FunctionSecurityPrivilege.CanUpdate)]
            public async Task VerifyFunctionSecurityForReminderWithNoValidOwners(FunctionSecurityPrivilege given)
            {
                var f = new FunctionSecurityProviderFixture(Db);
                var staff = new NameBuilder(Db).WithFamily().Build().In(Db);
                var user = new UserBuilder(Db) { Name = staff }.Build();
                var newNameId = Fixture.Integer();
                var newNameIdTwo = Fixture.Integer();
                new NameBuilder(Db).Build().WithKnownId(newNameId).In(Db);
                new NameBuilder(Db).Build().WithKnownId(newNameIdTwo).In(Db);
                var result = await f.Subject.FunctionSecurityFor(BusinessFunction.Reminder, given, user, new[] { newNameId, newNameIdTwo });
                Assert.Equal(new[] { user.NameId }, result);
            }

            [Theory]
            [InlineData(FunctionSecurityPrivilege.CanDelete)]
            [InlineData(FunctionSecurityPrivilege.CanUpdate)]
            public async Task VerifyForReminderHavingFunctionSecurityWithoutOwnerId(FunctionSecurityPrivilege given)
            {
                var f = new FunctionSecurityProviderFixture(Db);
                var staff = new NameBuilder(Db).WithFamily().Build().In(Db);
                var user = new UserBuilder(Db) { Name = staff }.Build();
                var newNameId = Fixture.Integer();
                var newNameIdTwo = Fixture.Integer();
                new NameBuilder(Db).Build().WithKnownId(newNameId).In(Db);
                new NameBuilder(Db).Build().WithKnownId(newNameIdTwo).In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.Reminder, AccessPrivileges = (short)FunctionSecurityPrivilege.CanUpdate, AccessStaffId = user.NameId, AccessGroup = staff.NameFamily.Id }.In(Db);
                new FunctionSecurity { FunctionTypeId = (short)BusinessFunction.Reminder, AccessPrivileges = (short)FunctionSecurityPrivilege.CanDelete, AccessStaffId = user.NameId, AccessGroup = staff.NameFamily.Id }.In(Db);
                var result = await f.Subject.FunctionSecurityFor(BusinessFunction.Reminder, given, user, new[] { newNameId, newNameIdTwo });
                Assert.Equal(new[] { newNameId, newNameIdTwo }, result);
            }
        }

        public class ForOthers : FactBase
        {
            [Fact]
            public async Task ReturnsForMatchingFunctionOnly()
            {
                var user = new UserBuilder(Db).Build();
                new FunctionSecurity
                {
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = (short) FunctionSecurityPrivilege.CanRead,
                    AccessStaffId = user.NameId, 
                    OwnerId = Fixture.Integer()
                }.In(Db);
                
                new FunctionSecurity
                {
                    FunctionTypeId = (short)BusinessFunction.Billing, 
                    AccessPrivileges = (short) FunctionSecurityPrivilege.CanCredit,
                    AccessStaffId = user.NameId, 
                    OwnerId = Fixture.Integer()
                }.In(Db);

                var f = new FunctionSecurityProviderFixture(Db);
                var result = (await f.Subject.ForOthers(BusinessFunction.TimeRecording, user)).ToArray();

                Assert.Single(result);
                Assert.True(result[0].CanRead);
            }

            [Fact]
            public async Task ReturnsFunctionSecurityIfGivenToAllStaff()
            {
                var staff2 = Fixture.Integer();
                var user = new UserBuilder(Db).Build();
                new FunctionSecurity
                {
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = 1, 
                    OwnerId = null
                }.In(Db);

                new FunctionSecurity
                {
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = 1, 
                    OwnerId = staff2
                }.In(Db);

                var f = new FunctionSecurityProviderFixture(Db);
                var result = (await f.Subject.ForOthers(BusinessFunction.TimeRecording, user)).ToArray();

                Assert.Equal(2, result.Length);
                Assert.Equal(staff2, result[0].OwnerId);
                Assert.Null(result[1].OwnerId);
            }
            
            [Fact]
            public async Task ReturnsFunctionSecurityAvailableForStaff()
            {
                var user = new UserBuilder(Db).Build();
                var othersTimeGrantedToMe = new FunctionSecurity
                {
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = 1, 
                    OwnerId = Fixture.Integer(), 
                    AccessStaffId = user.NameId
                }.In(Db);

                new FunctionSecurity
                {
                    //othersTimeNotGrantedToMe
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = 1, 
                    OwnerId = Fixture.Integer(), 
                    AccessStaffId = Fixture.Short()
                }.In(Db);

                new FunctionSecurity
                {
                    //myTimeGrantedToMyOwn
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = 1, 
                    OwnerId = user.NameId, 
                    AccessStaffId = user.NameId
                }.In(Db);

                new FunctionSecurity
                {
                    //myTimeGrantedToOther
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = 1, 
                    OwnerId = user.NameId, 
                    AccessStaffId = Fixture.Short()
                }.In(Db);

                var f = new FunctionSecurityProviderFixture(Db);
                var result = (await f.Subject.ForOthers(BusinessFunction.TimeRecording, user)).ToArray();

                Assert.Single(result);
                Assert.Equal(othersTimeGrantedToMe.OwnerId, result.Single().OwnerId);
            }

            [Fact]
            public async Task ReturnsFunctionSecurityAvailableForStaffGroup()
            {
                var staff = new NameBuilder(Db).WithFamily().Build().In(Db);
                var user = new UserBuilder(Db) { Name = staff }.Build();

                new FunctionSecurity
                {
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = 1, 
                    AccessGroup = user.Name.NameFamily.Id, 
                    OwnerId = Fixture.Integer()
                }.In(Db);

                new FunctionSecurity
                {
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = 1, 
                    AccessGroup = user.Name.NameFamily.Id, 
                    OwnerId = null
                }.In(Db);

                var f = new FunctionSecurityProviderFixture(Db);
                var result = (await f.Subject.ForOthers(BusinessFunction.TimeRecording, user)).ToArray();

                Assert.Equal(2, result.Length);
            }
        }

        public class For : FactBase
        {
            [Fact]
            public async Task ReturnsForMatchingFunctionOnly()
            {
                var user = new UserBuilder(Db).Build();
                new FunctionSecurity
                {
                    FunctionTypeId = (short) BusinessFunction.TimeRecording,
                    AccessPrivileges = (short) FunctionSecurityPrivilege.CanRead,
                    AccessStaffId = user.NameId
                }.In(Db);

                new FunctionSecurity
                {
                    FunctionTypeId = (short) BusinessFunction.Billing,
                    AccessPrivileges = (short) FunctionSecurityPrivilege.CanCredit,
                    AccessStaffId = user.NameId
                }.In(Db);

                var f = new FunctionSecurityProviderFixture(Db);
                var result = (await f.Subject.For(BusinessFunction.Billing, user)).ToArray();

                Assert.Single(result);
                Assert.True(result.Single().CanCredit);
            }

            [Fact]
            public async Task ReturnsForNameFamily()
            {
                var staff = new NameBuilder(Db).WithFamily().Build().In(Db);
                var user = new UserBuilder(Db) {Name = staff}.Build();

                new FunctionSecurity
                {
                    FunctionTypeId = (short) BusinessFunction.TimeRecording,
                    AccessPrivileges = (short) FunctionSecurityPrivilege.CanRead,
                    AccessGroup = staff.NameFamily.Id
                }.In(Db);

                new FunctionSecurity
                {
                    FunctionTypeId = (short) BusinessFunction.TimeRecording,
                    AccessPrivileges = (short) FunctionSecurityPrivilege.CanRead,
                    AccessGroup = Fixture.Short()
                }.In(Db);

                var f = new FunctionSecurityProviderFixture(Db);
                var result = (await f.Subject.For(BusinessFunction.TimeRecording, user)).ToArray();

                Assert.Single(result);
                Assert.Equal(staff.NameFamily.Id, result[0].AccessGroup);
            }
        }

        public class BestFit : FactBase
        {
            [Fact]
            public async Task PrefersStaffNameOverNameFamily()
            {
                var staff = new NameBuilder(Db).WithFamily().Build().In(Db);
                var user = new UserBuilder(Db) { Name = staff }.Build();
                
                new FunctionSecurity
                {
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = (short) FunctionSecurityPrivilege.CanRead,
                    AccessStaffId = user.NameId, 
                    AccessGroup = staff.NameFamily.Id
                }.In(Db);

                new FunctionSecurity
                {
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = (short) FunctionSecurityPrivilege.CanUpdate,
                    AccessStaffId = user.NameId + 1, 
                    AccessGroup = staff.NameFamily.Id
                }.In(Db);

                new FunctionSecurity
                {
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = (short) FunctionSecurityPrivilege.CanInsert,
                    AccessGroup = staff.NameFamily.Id
                }.In(Db);

                new FunctionSecurity
                {
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = (short) FunctionSecurityPrivilege.CanDelete,
                    AccessGroup = Fixture.Short()
                }.In(Db);

                var f = new FunctionSecurityProviderFixture(Db);
                var result = await f.Subject.BestFit(BusinessFunction.TimeRecording, user);

                // Using Access Privilege to identify the FunctionSecurity row 
                Assert.True(result.CanRead);
                Assert.False(result.CanInsert);
                Assert.False(result.CanUpdate);
                Assert.False(result.CanDelete);
            }

            [Fact]
            public async Task PrefersOwnerNameOverStaffName()
            {
                var newNameId = Fixture.Integer();
                new NameBuilder(Db).Build().WithKnownId(newNameId).In(Db);
                var staff = new NameBuilder(Db).WithFamily().Build().In(Db);
                var user = new UserBuilder(Db) { Name = staff }.Build();
                
                new FunctionSecurity
                {
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = (short) FunctionSecurityPrivilege.CanRead,
                    OwnerId = newNameId, 
                    AccessStaffId = user.NameId, 
                    AccessGroup = staff.NameFamily.Id
                }.In(Db);

                new FunctionSecurity
                {
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = (short) FunctionSecurityPrivilege.CanInsert,
                    OwnerId = newNameId + 1, 
                    AccessStaffId = user.NameId, 
                    AccessGroup = staff.NameFamily.Id
                }.In(Db);

                new FunctionSecurity
                {
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = (short) FunctionSecurityPrivilege.CanUpdate,
                    AccessStaffId = user.NameId, 
                    AccessGroup = staff.NameFamily.Id
                }.In(Db);

                new FunctionSecurity
                {
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = (short) FunctionSecurityPrivilege.CanDelete,
                    AccessStaffId = user.NameId + 1, 
                    AccessGroup = staff.NameFamily.Id
                }.In(Db);

                new FunctionSecurity
                {
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = (short) FunctionSecurityPrivilege.CanPost,
                    AccessGroup = staff.NameFamily.Id
                }.In(Db);

                new FunctionSecurity
                {
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = (short) FunctionSecurityPrivilege.CanAdjustValue,
                    AccessGroup = Fixture.Short()
                }.In(Db);

                var f = new FunctionSecurityProviderFixture(Db);
                var result = await f.Subject.BestFit(BusinessFunction.TimeRecording, user, newNameId);

                // Using Access Privilege to identify the FunctionSecurity row 
                Assert.True(result.CanRead);
                Assert.False(result.CanInsert);
                Assert.False(result.CanUpdate);
                Assert.False(result.CanDelete);
                Assert.False(result.CanPost);
                Assert.False(result.CanAdjustValue);
            }

            [Theory]
            [InlineData(FunctionSecurityPrivilege.CanRead, true, false, false, false, false, false, false, false, false, false)]
            [InlineData(FunctionSecurityPrivilege.CanInsert, false, true, false, false, false, false, false, false, false, false)]
            [InlineData(FunctionSecurityPrivilege.CanUpdate, false, false, true, false, false, false, false, false, false, false)]
            [InlineData(FunctionSecurityPrivilege.CanDelete, false, false, false, true, false, false, false, false, false, false)]
            [InlineData(FunctionSecurityPrivilege.CanPost, false, false, false, false, true, false, false, false, false, false)]
            [InlineData(FunctionSecurityPrivilege.CanFinalise, false, false, false, false, false, true, false, false, false, false)]
            [InlineData(FunctionSecurityPrivilege.CanReverse, false, false, false, false, false, false, true, false, false, false)]
            [InlineData(FunctionSecurityPrivilege.CanCredit, false, false, false, false, false, false, false, true, false, false)]
            [InlineData(FunctionSecurityPrivilege.CanAdjustValue, false, false, false, false, false, false, false, false, true, false)]
            [InlineData(FunctionSecurityPrivilege.CanConvert, false, false, false, false, false, false, false, false, false, true)]
            public async Task ReturnsRequiredPrivilege(FunctionSecurityPrivilege required, 
                                                       bool canRead, bool canInsert, bool canUpdate, bool canDelete, bool canPost, 
                                                       bool canFinalise, bool canReverse, bool canCredit, 
                                                       bool canAdjustValue, 
                                                       bool canConvert)
            {
                var newNameId = Fixture.Integer();
                new NameBuilder(Db).Build().WithKnownId(newNameId).In(Db);
                var staff = new NameBuilder(Db).WithFamily().Build().In(Db);
                var user = new UserBuilder(Db) { Name = staff }.Build();
                new FunctionSecurity
                {
                    FunctionTypeId = (short)BusinessFunction.TimeRecording, 
                    AccessPrivileges = (short)required, 
                    OwnerId = newNameId, 
                    AccessStaffId = user.NameId, 
                    AccessGroup = staff.NameFamily.Id
                }.In(Db);
                
                var f = new FunctionSecurityProviderFixture(Db);
                var result = await f.Subject.BestFit(BusinessFunction.TimeRecording, user, newNameId);

                Assert.Equal(canRead, result.CanRead);
                Assert.Equal(canInsert, result.CanInsert);
                Assert.Equal(canUpdate, result.CanUpdate);
                Assert.Equal(canDelete, result.CanDelete);
                Assert.Equal(canPost, result.CanPost);
                Assert.Equal(canAdjustValue, result.CanAdjustValue);
                Assert.Equal(canFinalise, result.CanFinalise);
                Assert.Equal(canReverse, result.CanReverse);
                Assert.Equal(canCredit, result.CanCredit);
                Assert.Equal(canConvert, result.CanConvert);
            }
        }
        
        public class FunctionSecurityProviderFixture : IFixture<FunctionSecurityProvider>
        {
            public FunctionSecurityProviderFixture(InMemoryDbContext db)
            {
                Subject = new FunctionSecurityProvider(db);
            }

            public FunctionSecurityProvider Subject { get; set; }
        }
    }
}
