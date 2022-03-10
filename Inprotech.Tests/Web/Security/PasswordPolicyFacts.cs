using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Security;
using NSubstitute;
using System.Collections.Generic;
using Xunit;

namespace Inprotech.Tests.Web.Security
{
    public class PasswordPolicyFacts : FactBase
    {
        public class PasswordPolicyFixture : IFixture<PasswordPolicy>
        {
           
            public readonly IStaticTranslator _staticTranslator;
            public readonly IPreferredCultureResolver _preferredCultureResolver;
            public readonly ISiteControlReader _siteControl;
            public readonly ILogger<PasswordPolicy> _logger;
            public readonly IPasswordVerifier _passwordVerifier;
            public PasswordPolicy Subject { get; }
       
            public PasswordPolicyFixture(InMemoryDbContext db)
            {
                _staticTranslator = Substitute.For<IStaticTranslator>();
                _preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                _logger = Substitute.For<ILogger<PasswordPolicy>>();
                _logger.Warning(Arg.Any<string>());
                _siteControl = Substitute.For<ISiteControlReader>();
                _passwordVerifier = Substitute.For<IPasswordVerifier>();
                _preferredCultureResolver.ResolveAll().Returns(new List<string>() { "US" });
                
                _staticTranslator.Translate(Arg.Any<string>(), Arg.Any<string[]>()).Returns(Fixture.String());

                Subject = new PasswordPolicy(_siteControl, _staticTranslator, _preferredCultureResolver, _logger, _passwordVerifier);
            }
        }

        [Fact]
        public void ShouldReturnSuccessWhenSiteControlIsOff()
        {
            var fixture = new PasswordPolicyFixture(Db);
            fixture._siteControl.Read<bool>(SiteControls.EnforcePasswordPolicy).Returns(false);
            var result = fixture.Subject.EnsureValid("12345", null);

            Assert.Equal(PasswordManagementStatus.Success, result.Status);
        }

        [Fact]
        public void ShouldReturnFailedWhenSiteControlIsOnAndWeekPasswordIsProvided()
        {
            var fixture = new PasswordPolicyFixture(Db);
            fixture._siteControl.Read<bool>(SiteControls.EnforcePasswordPolicy).Returns(true);
            var user = CreateUser("bob", "dabadee", true);
            var result = fixture.Subject.EnsureValid("12345", user);

            Assert.Equal(PasswordManagementStatus.PasswordPolicyValidationFailed, result.Status);
            fixture._logger.Received(1).Warning(Arg.Is("Password Policy Validation Failed: password regex failed"), Arg.Any<object>());
        }

        [Fact]
        public void ShouldReturnSuccessWhenSiteControlIsOnAndStrongPasswordIsProvided()
        {
            var fixture = new PasswordPolicyFixture(Db);
            fixture._siteControl.Read<bool>(SiteControls.EnforcePasswordPolicy).Returns(true);
            fixture._siteControl.Read<int?>(SiteControls.PasswordUsedHistory).Returns(5);
            var user = CreateUser("bob", "dabadee", true);
            var result = fixture.Subject.EnsureValid("Test@12345", user);

            Assert.Equal(PasswordManagementStatus.Success, result.Status);
        }

        [Fact]
        public void ShouldReturnFailedWhenSiteControlIsOnAndUserNameSameAsPassword()
        {
            var fixture = new PasswordPolicyFixture(Db);
            fixture._siteControl.Read<bool>(SiteControls.EnforcePasswordPolicy).Returns(true);
            var user = CreateUser("bob", "dabadee", true);
            var result = fixture.Subject.EnsureValid("bob", user);

            Assert.Equal(PasswordManagementStatus.PasswordPolicyValidationFailed, result.Status);
            fixture._logger.Received(1).Warning(Arg.Is("Password Policy Validation Failed: Username should not be same as password"), Arg.Any<object>());
        }

        [Fact]
        public void ShouldReturnFailedWhenSiteControlIsOnAndPasswordContainUserName()
        {
            var fixture = new PasswordPolicyFixture(Db);
            fixture._siteControl.Read<bool>(SiteControls.EnforcePasswordPolicy).Returns(true);
            var user = CreateUser("bob", "dabadee", true);
            var result = fixture.Subject.EnsureValid("bob@2345", user);

            Assert.Equal(PasswordManagementStatus.PasswordPolicyValidationFailed, result.Status);
            fixture._logger.Received(1).Warning(Arg.Is("Password Policy Validation Failed: Username should not be same as password"), Arg.Any<object>());
        }

        [Fact]
        public void ShouldReturnFailedWhenPasswordAlreadyUsed()
        {
            var fixture = new PasswordPolicyFixture(Db);
            fixture._passwordVerifier.HasPasswordReused(Arg.Any<string>(), Arg.Any<string>()).Returns(true);
            fixture._siteControl.Read<bool>(SiteControls.EnforcePasswordPolicy).Returns(true);
            var user = CreateUser("bob", "dabadee", true);
            var result = fixture.Subject.EnsureValid("Internal@123", user);

            Assert.Equal(PasswordManagementStatus.PasswordPolicyValidationFailed, result.Status);
            fixture._logger.Received(1).Warning(Arg.Is("Password Policy Validation Failed: password already used"), Arg.Any<object>());
        }
    }
}
