using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Security
{
    public class UserIdentityAccessManagerFacts : FactBase
    {
        const int DefaultExtensionToleranceMinutes = 3;

        public class UserIdentityAccessManagerFixture : IFixture<IUserIdentityAccessManager>
        {
            readonly ICryptoService _cryptoService;
            public IDbContext DbContext { get; }

            public UserIdentityAccessManagerFixture(InMemoryDbContext dbContext)
            {
                _cryptoService = Substitute.For<ICryptoService>();
                Bus = Substitute.For<IBus>();

                DbContext = dbContext;
                Subject = new UserIdentityAccessManager(DbContext, _cryptoService, Fixture.Today, Bus);
            }
            public IBus Bus { get; set; }

            public IUserIdentityAccessManager Subject { get; }

            public UserIdentityAccessManagerFixture WithEncryptRefreshToken(string refreshToken)
            {
                _cryptoService.Encrypt(Arg.Any<string>()).Returns(refreshToken);
                return this;
            }

            public UserIdentityAccessManagerFixture WithDecryptRefreshToken(string refreshToken)
            {
                _cryptoService.Decrypt(Arg.Any<string>()).Returns(refreshToken);
                return this;
            }
        }

        [Fact]
        public void AddsUserIdentityLog()
        {
            var identityId = Fixture.Integer();
            var refreshToken = "Refresh";
            var fixture = new UserIdentityAccessManagerFixture(Db).WithEncryptRefreshToken(refreshToken);

            fixture.Subject.StartSession(identityId, AuthenticationModeKeys.Sso, new UserIdentityAccessData {RefreshToken = refreshToken}, "testApplication", "167.78.89.89");

            var log = fixture.DbContext.Set<UserIdentityAccessLog>().Single();
            Assert.Equal(identityId, log.IdentityId);
            Assert.Equal(Fixture.Today(), log.LoginTime);
            Assert.Equal("testApplication", log.Application);
            Assert.Equal("167.78.89.89", log.Source);
            fixture.Bus.Received(1).Publish(Arg.Is<UserSessionStartedMessage>(_ => _.IdentityId == identityId));
        }

        [Fact]
        public void ApplicationIsOptionalWhenStartingSession()
        {
            var fixture = new UserIdentityAccessManagerFixture(Db);
            fixture.Subject.StartSession(1, AuthenticationModeKeys.Sso, null, null, null); // null passed as Application

            var log = fixture.DbContext.Set<UserIdentityAccessLog>().Single();
            Assert.Equal(1, log.IdentityId);
            Assert.Null(log.Application);
        }

        [Fact]
        public async Task DoesNotExtendProviderSessionIfWithinTolerance()
        {
            var identityId = Fixture.Integer();
            var refreshToken = "Refresh";
            var fixture = new UserIdentityAccessManagerFixture(Db).WithEncryptRefreshToken(refreshToken);

            fixture.Subject.StartSession(identityId, AuthenticationModeKeys.Sso, new UserIdentityAccessData {RefreshToken = refreshToken}, "testApplication", null);

            refreshToken = "NewRefresh";
            fixture.WithEncryptRefreshToken(refreshToken);
            
            await fixture.Subject.ExtendProviderSession(0, identityId, AuthenticationModeKeys.Sso, new UserIdentityAccessData {RefreshToken = refreshToken});

            refreshToken = "xyz";
            await fixture.Subject.TryExtendProviderSession(0, identityId, AuthenticationModeKeys.Sso, new UserIdentityAccessData {RefreshToken = refreshToken}, DefaultExtensionToleranceMinutes);

            var log = fixture.DbContext.Set<UserIdentityAccessLog>().Single();
            Assert.Equal(identityId, log.IdentityId);
            Assert.NotEqual(refreshToken, log.Data);
            Assert.Equal(1, log.TotalExtensions);
        }

        [Fact]
        public async Task EndsSession()
        {
            var fixture = new UserIdentityAccessManagerFixture(Db);
            var userId = Fixture.Integer();
            var log1 = new UserIdentityAccessLog(userId, AuthenticationModeKeys.Sso, null, Fixture.Today()).In(Db);
            await fixture.Subject.EndSession(log1.LogId);
            var log = fixture.DbContext.Set<UserIdentityAccessLog>().Single();
            Assert.NotNull(log.LogoutTime);
            Assert.Equal(Fixture.Today(), log.LogoutTime);
            fixture.Bus.Received(1).Publish(Arg.Is<UserSessionInvalidatedMessage>(_ => _.IdentityId == userId));
        }

        [Fact]
        public async Task ExtendProviderSession()
        {
            var identityId = Fixture.Integer();
            var refreshToken = "Refresh";
            var fixture = new UserIdentityAccessManagerFixture(Db).WithEncryptRefreshToken(refreshToken);

            fixture.Subject.StartSession(identityId, AuthenticationModeKeys.Sso, new UserIdentityAccessData {RefreshToken = refreshToken}, "testApplication", null);

            refreshToken = "NewRefresh";
            fixture.WithEncryptRefreshToken(refreshToken);
            
            await fixture.Subject.ExtendProviderSession(0, identityId, AuthenticationModeKeys.Sso, new UserIdentityAccessData {RefreshToken = refreshToken});

            var log = fixture.DbContext.Set<UserIdentityAccessLog>().Single();
            Assert.Equal(identityId, log.IdentityId);
            Assert.Equal(AuthenticationModeKeys.Sso, log.Provider);
            Assert.Equal(refreshToken, log.Data);
            Assert.Equal(Fixture.Today(), log.LastExtension);
        }

        [Fact]
        public async Task ExtendProviderSessionIfOlderThanTolerance()
        {
            var dbLog = new UserIdentityAccessLog(1, AuthenticationModeKeys.Sso, "abc", Fixture.PastDate())
            {
                TotalExtensions = 1,
                LastExtension = Fixture.PastDate()
            }.In(Db);

            var refreshToken = "xyz";
            var fixture = new UserIdentityAccessManagerFixture(Db).WithEncryptRefreshToken(refreshToken);
            await fixture.Subject.TryExtendProviderSession(dbLog.LogId, 1, AuthenticationModeKeys.Sso, new UserIdentityAccessData {RefreshToken = refreshToken}, DefaultExtensionToleranceMinutes);

            var log = fixture.DbContext.Set<UserIdentityAccessLog>().Single();
            Assert.Equal(1, log.IdentityId);
            Assert.Equal(refreshToken, log.Data);
            Assert.Equal(2, log.TotalExtensions);
            Assert.Equal(Fixture.Today(), log.LastExtension);
        }

        [Fact]
        public async Task ExtendProviderThowsIfSessionNotFound()
        {
            var identityId = Fixture.Integer();

            var refreshToken = "NewRefresh";
            var fixture = new UserIdentityAccessManagerFixture(Db).WithEncryptRefreshToken(refreshToken);
            await Assert.ThrowsAsync<InvalidOperationException>(async () => await fixture.Subject.ExtendProviderSession(1, 1, AuthenticationModeKeys.Sso, new UserIdentityAccessData {RefreshToken = refreshToken}));

            refreshToken = "Refresh";
            fixture.WithEncryptRefreshToken(refreshToken);

            fixture.Subject.StartSession(identityId, AuthenticationModeKeys.Sso, new UserIdentityAccessData {RefreshToken = refreshToken}, "testApplication", null);
            
            var log = fixture.DbContext.Set<UserIdentityAccessLog>().Single();
            await Assert.ThrowsAsync<Exception>(async () => await fixture.Subject.ExtendProviderSession(log.LogId, log.IdentityId, AuthenticationModeKeys.Forms, new UserIdentityAccessData {RefreshToken = refreshToken}));
        }

        [Fact]
        public async Task GetSigninData()
        {
            var userId = Fixture.Integer();
            var data = new UserIdentityAccessData {RefreshToken = "data"};
            var log1 = new UserIdentityAccessLog(userId, AuthenticationModeKeys.Sso, null, Fixture.Today()) {Data = data.ToString()}.In(Db);

            var fixture = new UserIdentityAccessManagerFixture(Db).WithDecryptRefreshToken(log1.Data);
            var log = await fixture.Subject.GetSigninData(log1.LogId, userId, AuthenticationModeKeys.Sso);
            Assert.Equal("data", log.data.RefreshToken);
            Assert.Null(log.lastExtension);
        }

        [Fact]
        public async Task ThrowsIfLogDetailsDontMatch()
        {
            var fixture = new UserIdentityAccessManagerFixture(Db);
            var userId = Fixture.Integer();
            var log1 = new UserIdentityAccessLog(userId, AuthenticationModeKeys.Sso, null, Fixture.Today()).In(Db);
            await Assert.ThrowsAsync<Exception>(async () => await fixture.Subject.GetSigninData(log1.LogId, userId, AuthenticationModeKeys.Forms));
        }
    }
}