using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.DmsIntegration.Component.iManage
{
    public class PersistedCredentialsResolverFacts : FactBase
    {
        readonly ISecurityContext _securityContext = Substitute.For<ISecurityContext>();
        readonly ICryptoService _cryptoService = Substitute.For<ICryptoService>();

        PersistedCredentialsResolver CreateSubject(User user)
        {
            _cryptoService.Decrypt(Arg.Any<string>(), true)
                          .Returns(x => x[0]);

            _securityContext.User.Returns(user);

            return new PersistedCredentialsResolver(Db, _cryptoService, _securityContext);
        }

        [Fact]
        public async Task ShouldReturnDecryptedPasswordFromConfiguration()
        {
            var user = new User("john", false).In(Db);
            new SettingValues
            {
                User = user,
                SettingId = KnownSettingIds.WorkSitePassword,
                CharacterValue = "very secure password"
            }.In(Db);

            var subject = CreateSubject(user);
            var r = await subject.Resolve();

            Assert.Equal("very secure password", r.Password);

            _cryptoService.Received(1).Decrypt("very secure password", true);
        }

        [Fact]
        public async Task ShouldReturnLoginIdFromConfiguration()
        {
            var user = new User("john", false).In(Db);
            new SettingValues
            {
                User = user,
                SettingId = KnownSettingIds.WorkSiteLogin,
                CharacterValue = "corp\\john"
            }.In(Db);

            var subject = CreateSubject(user);
            var r = await subject.Resolve();

            Assert.Equal("corp\\john", r.UserName);
        }

        [Fact]
        public async Task ShouldReturnNullValuesIfNoneConfigured()
        {
            var subject = CreateSubject(new User());
            var r = await subject.Resolve();

            Assert.NotNull(r);
            Assert.Null(r.UserName);
            Assert.Null(r.Password);
        }
    }
}