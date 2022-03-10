using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Web.Security;
using Inprotech.Web.Security.TwoFactorAuth;
using InprotechKaizen.Model.Security;
using NSubstitute;
using System;
using System.Threading.Tasks;
using Xunit;

namespace Inprotech.Tests.Web.Security
{
    public class PasswordVerifierFacts : FactBase
    {
        readonly ISiteControlReader _siteControl;
        readonly PasswordVerifier _subject;
        readonly IUserValidation _validation;

        public PasswordVerifierFacts()
        {
            var configuredAccess = Substitute.For<IConfiguredAccess>();
            configuredAccess.For(Arg.Any<User>()).Returns(true);
            var twoFactorAuthVerify = Substitute.For<ITwoFactorAuthVerify>();
            _validation = new UserValidation(Db,
                                             configuredAccess,
                                             Substitute.For<ISiteControlReader>(),
                                             Substitute.For<IBus>(),
                                             () => DateTime.Now, twoFactorAuthVerify);
            var now = Substitute.For<Func<DateTime>>();
            _siteControl = Substitute.For<ISiteControlReader>();
            _subject = new PasswordVerifier(_siteControl, now, Db);
            now().Returns(DateTime.Now);
        }

        [Fact]
        public void ShouldReturnTrueWhenPasswordAlreadyUsed()
        {
            _siteControl.Read<bool>(SiteControls.EnforcePasswordPolicy).Returns(true);
            _siteControl.Read<int?>(SiteControls.PasswordUsedHistory).Returns(5);
            var user = CreateUser("bob", "internal", true);
            user.PasswordHistory = @"7599e58dfa334fbda5e0d0689a4fbbc1 fd728c24721a8db9cb47d69722b197fc00d1a18472fa7503efcdac952a999274
        a2cc8919bb4c45dca8a595bf22af8454 14fadd3a04ced26232f7d418ac1b6e7899ffdcac94d3c8bc2001940a0b23c3c3";
            var result = _subject.HasPasswordReused("Internal@123", user.PasswordHistory);
            Assert.True(result);
        }

        [Fact]
        public void ShouldReturnFalseWhenPasswordUsedHistoryNotSet()
        {
            _siteControl.Read<bool>(SiteControls.EnforcePasswordPolicy).Returns(true);
            _siteControl.Read<int?>(SiteControls.PasswordUsedHistory).Returns(0);
            var user = CreateUser("bob", "internal", true);
            Assert.False(_subject.HasPasswordReused(Fixture.String(), user.PasswordHistory));

            _siteControl.Read<bool>(SiteControls.EnforcePasswordPolicy).Returns(false);
            Assert.False(_subject.HasPasswordReused(Fixture.String(), user.PasswordHistory));
        }

        [Fact]
        public async Task ShaPasswordShouldOverrideMd5()
        {
            var user = CreateUser("bob", "internalMd5", true);
            
            var validation = await _validation.Validate(user, "internalMd5");
            Assert.True(validation.Accepted);

            user = UpdateUserPasswordManually(user, "internalSha", false);

            validation = await _validation.Validate(user, "internalMd5");
            Assert.False(validation.Accepted);

            validation = await _validation.Validate(user, "internalSha");
            Assert.True(validation.Accepted);
        }

        [Fact]
        public async Task CorrectPasswordWorks()
        {
            var user = CreateUser("bob", "internal", true);
            _siteControl.Read<bool>(SiteControls.EnforcePasswordPolicy).Returns(true);
            _siteControl.Read<int?>(SiteControls.PasswordUsedHistory).Returns(5);
            _subject.UpdateUserPassword("goodPassword", user);
            Assert.True(user.PasswordHistory.Contains(user.PasswordSalt));
            Assert.NotNull(user.PasswordUpdatedDate);
            var validation = await _validation.Validate(user, "goodPassword");
            Assert.True(validation.Accepted);
        }

        [Fact]
        public async Task DoNotUpdatePasswordHistoryWhenPasswordUsedHistoryNotSet()
        {
            var user = CreateUser("bob", "internal", true);
            _siteControl.Read<bool>(SiteControls.EnforcePasswordPolicy).Returns(true);
            _siteControl.Read<int?>(SiteControls.PasswordUsedHistory).Returns(0);
            _subject.UpdateUserPassword("goodPassword", user);
            Assert.Null(user.PasswordHistory);
            var validation = await _validation.Validate(user, "goodPassword");
            Assert.True(validation.Accepted);
        }

        [Fact]
        public void DoNotUpdatePasswordHistoryWhenEnforcePasswordHistoryIsFalse()
        {
            var user = CreateUser("bob", "internal", true);
            _siteControl.Read<bool>(SiteControls.EnforcePasswordPolicy).Returns(false);
            _siteControl.Read<int?>(SiteControls.PasswordUsedHistory).Returns(5);
            _subject.UpdateUserPassword("goodPassword", user);
            Assert.Null(user.PasswordHistory);
        }
    }
}
