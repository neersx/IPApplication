using System;
using System.Threading.Tasks;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Security;
using Inprotech.Web.Security.TwoFactorAuth;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Security
{
    public class UserValidationFacts : FactBase
    {
        public class UserValidationFixture : IFixture<UserValidation>
        {
            public UserValidationFixture(InMemoryDbContext db)
            {
                Bus = Substitute.For<IBus>();
                SiteControls = Substitute.For<ISiteControlReader>();
                ConfiguredAccess = Substitute.For<IConfiguredAccess>();
                Now = Substitute.For<Func<DateTime>>();
                Subject = new UserValidation(db, ConfiguredAccess, SiteControls, Bus, Now, TwoFactorAuthVerify);
                Now().Returns(Fixture.Today());
            }

            public IBus Bus { get; set; }
            public Func<DateTime> Now { get; set; }

            public ISiteControlReader SiteControls { get; set; }

            public IConfiguredAccess ConfiguredAccess { get; set; }

            public ITwoFactorAuthVerify TwoFactorAuthVerify { get; set; }

            public UserValidation Subject { get; }

            public UserValidationFixture WithMaxLoginsAllowed(int numberOfRetriesAllowed)
            {
                SiteControls.Read<int>(Inprotech.Infrastructure.SiteControls.MaxInvalidLogins).Returns(numberOfRetriesAllowed);
                return this;
            }

            public UserValidationFixture WithUserIdentifiedAsValid()
            {
                ConfiguredAccess.For(Arg.Any<User>()).Returns(true);
                return this;
            }
        }

        public class ValidatePassword : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task DoesNotIncrementInvalidLoginCounts(bool passwordMd5)
            {
                var fixture = new UserValidationFixture(Db)
                              .WithMaxLoginsAllowed(0)
                              .WithUserIdentifiedAsValid();

                var subject = fixture.Subject;

                var password = Fixture.String();

                var bob = CreateUser("bob", password, passwordMd5);

                bob.InvalidLogins = 0;

                var r = await subject.Validate(bob, Fixture.String());

                Assert.False(r.Accepted);
                Assert.Equal("unauthorised-credentials", r.FailReasonCode);

                Assert.Equal(0, bob.InvalidLogins);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task IncrementInvalidLoginCounts(bool passwordMd5)
            {
                var fixture = new UserValidationFixture(Db)
                              .WithMaxLoginsAllowed(3)
                              .WithUserIdentifiedAsValid();

                var subject = fixture.Subject;

                var password = Fixture.String();

                var bob = CreateUser("bob", password, passwordMd5);

                bob.InvalidLogins = 0;

                var r = await subject.Validate(bob, Fixture.String());

                Assert.False(r.Accepted);
                Assert.Equal("unauthorised-credentials", r.FailReasonCode);

                Assert.Equal(1, bob.InvalidLogins);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task LocksTheAccount(bool passwordMd5)
            {
                var fixture = new UserValidationFixture(Db)
                              .WithMaxLoginsAllowed(1)
                              .WithUserIdentifiedAsValid();

                var subject = fixture.Subject;

                var password = Fixture.String();

                var bob = CreateUser("bob", password, passwordMd5);

                bob.InvalidLogins = 0;
                bob.IsLocked = false;

                var r = await subject.Validate(bob, Fixture.String());

                Assert.False(r.Accepted);
                Assert.Equal("unauthorised-accounts-just-locked", r.FailReasonCode);
                Assert.Equal(1, bob.InvalidLogins);
                Assert.True(bob.IsLocked);

                fixture.Bus.Received(1).PublishAsync(Arg.Any<UserAccountLockedMessage>()).IgnoreAwaitForNSubstituteAssertion();
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task PreventEntryWhenAccountIsLocked(bool passwordMd5)
            {
                var fixture = new UserValidationFixture(Db);

                var subject = fixture.Subject;

                var password = Fixture.String();

                var bob = CreateUser("bob", password, passwordMd5);

                bob.IsLocked = true;

                var r = await subject.Validate(bob, password);

                Assert.False(r.Accepted);
                Assert.Equal("unauthorised-accounts-locked", r.FailReasonCode);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ResetInvalidLoginAttemptsOnPasswordMatches(bool passwordMd5)
            {
                var fixture = new UserValidationFixture(Db)
                              .WithMaxLoginsAllowed(3)
                              .WithUserIdentifiedAsValid();

                var subject = fixture.Subject;

                var password = Fixture.String();

                var bob = CreateUser("bob", password, passwordMd5);

                bob.InvalidLogins = 5;

                var r = await subject.Validate(bob, password);

                Assert.True(r.Accepted);
                Assert.Equal(0, bob.InvalidLogins);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ReturnAuthorisedIfPasswordMatches(bool passwordMd5)
            {
                var fixture = new UserValidationFixture(Db)
                              .WithMaxLoginsAllowed(3)
                              .WithUserIdentifiedAsValid();

                var subject = fixture.Subject;

                var password = Fixture.String();

                var bob = CreateUser("bob", password, passwordMd5);

                var r = await subject.Validate(bob, password);

                Assert.True(r.Accepted);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ReturnUnauthorisedIfPasswordNotMatches(bool passwordMd5)
            {
                var fixture = new UserValidationFixture(Db)
                              .WithMaxLoginsAllowed(3)
                              .WithUserIdentifiedAsValid();

                var subject = fixture.Subject;

                var password = Fixture.String();

                var bob = CreateUser("bob", password, passwordMd5);

                var r = await subject.Validate(bob, Fixture.String());

                Assert.False(r.Accepted);
                Assert.Equal("unauthorised-credentials", r.FailReasonCode);
            }

            [Theory]
            [InlineData(11, true)]
            [InlineData(4, false)]

            public void CheckPasswordExpired(int days, bool hasExpired)
            {
                var fixture = new UserValidationFixture(Db)
                              .WithMaxLoginsAllowed(3)
                              .WithUserIdentifiedAsValid();
                fixture.SiteControls.Read<bool>(SiteControls.EnforcePasswordPolicy).Returns(true);
                fixture.SiteControls.Read<int?>(SiteControls.PasswordExpiryDuration).Returns(5);

                var subject = fixture.Subject;

                var password = Fixture.String();

                var bob = CreateUser("bob", password, true);
                bob.PasswordUpdatedDate = Fixture.Today().Subtract(TimeSpan.FromDays(days));

                var r = subject.IsPasswordExpired(bob);
                Assert.Equal(r, hasExpired);
            }
        }
    }
}