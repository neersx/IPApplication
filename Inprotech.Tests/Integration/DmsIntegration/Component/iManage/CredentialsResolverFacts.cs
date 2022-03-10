using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.DmsIntegration.Component.iManage
{
    public class CredentialsResolverFacts
    {
        readonly ILogger<CredentialsResolver> _logger = Substitute.For<ILogger<CredentialsResolver>>();
        readonly IPersistedCredentialsResolver _persistedResolver = Substitute.For<IPersistedCredentialsResolver>();
        readonly ISecurityContext _securityContext = Substitute.For<ISecurityContext>();

        CredentialsResolver CreateSubject()
        {
            return new CredentialsResolver(_logger, _securityContext, _persistedResolver);
        }

        [Theory]
        [InlineData(IManageSettings.LoginTypes.UsernamePassword)]
        [InlineData(IManageSettings.LoginTypes.UsernameWithImpersonation)]
        public async Task ShouldWarnOfUsernameRequiredValidationsCorrectly(string loginType)
        {
            var subject = CreateSubject();

            await subject.Resolve(new IManageSettings.SiteDatabaseSettings {LoginType = loginType});

            _logger
                .Received(1)
                .Warning(Arg.Is<string>(message => message.Contains("* No Username found. This may indicate 'Login ID' is not configured. This can be found in the 'iManage Integration' group of user preferences.")));
        }

        [Theory]
        [InlineData(IManageSettings.LoginTypes.UsernamePassword)]
        public async Task ShouldWarnOfPasswordRequiredValidationsCorrectly(string loginType)
        {
            var subject = CreateSubject();

            await subject.Resolve(new IManageSettings.SiteDatabaseSettings {LoginType = loginType});

            _logger
                .Received(1)
                .Warning(Arg.Is<string>(message => message.Contains("* No password found. This may indicate 'Password' is not configured. This can be found in the 'iManage Integration' group of user preferences.")));
        }

        [Theory]
        [InlineData(IManageSettings.LoginTypes.UsernamePassword)]
        [InlineData(IManageSettings.LoginTypes.TrustedLogin)]
        [InlineData(IManageSettings.LoginTypes.TrustedLogin2)]
        [InlineData(IManageSettings.LoginTypes.UsernameWithImpersonation)]
        public async Task ShouldGetFromPersistedCredentialsResolver(string loginType)
        {
            var userName = Fixture.String();

            _persistedResolver.Resolve().Returns(new DmsCredential {UserName = userName});

            var subject = CreateSubject();

            var result = await subject.Resolve(new IManageSettings.SiteDatabaseSettings {LoginType = loginType});

            _persistedResolver.Received(1).Resolve()
                              .IgnoreAwaitForNSubstituteAssertion();

            Assert.Equal(userName, result.UserName);
        }

        [Theory]
        [InlineData(IManageSettings.LoginTypes.UsernamePassword)]
        [InlineData(IManageSettings.LoginTypes.TrustedLogin)]
        [InlineData(IManageSettings.LoginTypes.TrustedLogin2)]
        [InlineData(IManageSettings.LoginTypes.UsernameWithImpersonation)]
        public async Task ShouldDefaultCredentialsIfNonePersisted(string loginType)
        {
            var subject = CreateSubject();

            var result = await subject.Resolve(new IManageSettings.SiteDatabaseSettings {LoginType = loginType});

            Assert.Null(result.UserName);
        }

        [Fact]
        public async Task ShouldReturnCurrentUsernameIfIsInprotechUsernameWithImpersonationEnabled()
        {
            var userName = Fixture.String();
            var subject = CreateSubject();

            _securityContext.User.Returns(new User(userName, true));

            var result = await subject.Resolve(new IManageSettings.SiteDatabaseSettings {LoginType = IManageSettings.LoginTypes.InprotechUsernameWithImpersonation});

            Assert.Equal(userName, result.UserName);
            _persistedResolver.DidNotReceive().Resolve().IgnoreAwaitForNSubstituteAssertion();
        }
    }
}