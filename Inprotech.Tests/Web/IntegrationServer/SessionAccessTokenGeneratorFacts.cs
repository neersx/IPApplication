using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.DependencyInjection;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.Integration.ExternalApplications;
using Inprotech.Integration.Persistence;
using Inprotech.Tests.Fakes;
using Inprotech.Web.IntegrationServer;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.IntegrationServer
{
    public class SessionAccessTokenGeneratorFacts : FactBase
    {
        readonly ILifetimeScope _lifetimeScope = Substitute.For<ILifetimeScope>();
        readonly ILifetimeScope _childLifetimeScope = Substitute.For<ILifetimeScope>();
        readonly ISessionAccessTokenInputResolver _accessTokenInputResolver = Substitute.For<ISessionAccessTokenInputResolver>();
     
        readonly Guid _defaultApiKey = Guid.NewGuid();

        int _userId;

        SessionAccessTokenGenerator CreateSubject()
        {
            var user = new User().In(Db);
            _userId = user.Id;
            _childLifetimeScope.Resolve<IRepository>().Returns(Db);
            _lifetimeScope.BeginLifetimeScope().Returns(_childLifetimeScope);

            return new SessionAccessTokenGenerator(_accessTokenInputResolver,() => _defaultApiKey, Fixture.Today, _lifetimeScope);
        }

        [Theory]
        [InlineData("KLJAdf")]
        [InlineData("4u5u43lkjfds")]
        public async Task ShouldGenerateSessionAccessTimeAccessTokenForApplication(string applicationName)
        {
            var subject = CreateSubject();

            await subject.GetOrCreateAccessToken(applicationName);

            var generatedToken = Db.Set<OneTimeToken>().Single();

            Assert.Equal(applicationName, generatedToken.ExternalApplicationName);
        }

        [Fact]
        public async Task ShouldGenerateNewSessionAccessToken()
        {
            var subject = CreateSubject();

            _accessTokenInputResolver.TryResolve(out _, out _)
                                     .Returns(x =>
                                     {
                                         x[0] = _userId;
                                         x[1] = Fixture.Long();

                                         return true;
                                     });

            await subject.GetOrCreateAccessToken();

            var generatedToken = Db.Set<OneTimeToken>().Single();

            Assert.Equal(_defaultApiKey, generatedToken.Token);
            Assert.Equal(_userId, generatedToken.CreatedBy);
            Assert.Equal(Fixture.Today().ToUniversalTime(), generatedToken.CreatedOn);
            Assert.Equal(Fixture.Today().ToUniversalTime().AddMinutes(5), generatedToken.ExpiryDate);
            Assert.Equal(ExternalApplicationName.InprotechServer.ToString(), generatedToken.ExternalApplicationName);
        }

        [Fact]
        public async Task ShouldReuseAlreadyGeneratedSessionAccessToken()
        {
            var subject = CreateSubject();

            var sessionId = Fixture.Long();
            _accessTokenInputResolver.TryResolve(out _, out _)
                                     .Returns(x =>
                                     {
                                         x[0] = _userId;
                                         x[1] = sessionId;

                                         return true;
                                     });

            await subject.GetOrCreateAccessToken();

            await subject.GetOrCreateAccessToken();

            await subject.GetOrCreateAccessToken();

            var generatedToken = Db.Set<OneTimeToken>().Single();

            _lifetimeScope.Received(1).BeginLifetimeScope();
            _childLifetimeScope.Received(1).Resolve<IRepository>();

            Assert.Equal(_defaultApiKey, generatedToken.Token);
            Assert.Equal(_userId, generatedToken.CreatedBy);
            Assert.Equal(Fixture.Today().ToUniversalTime(), generatedToken.CreatedOn);
            Assert.Equal(Fixture.Today().ToUniversalTime().AddMinutes(5), generatedToken.ExpiryDate);
            Assert.Equal(ExternalApplicationName.InprotechServer.ToString(), generatedToken.ExternalApplicationName);
        }

        [Fact]
        public async Task ShouldContinueToGenerateOneTimeAccessTokenForUnauthenticatedRequests()
        {
            // use case: password reset
            
            var subject = CreateSubject();

            _accessTokenInputResolver.TryResolve(out _, out _)
                                     .Returns(x =>
                                     {
                                         x[0] = int.MinValue;
                                         x[1] = long.MinValue;

                                         return false;
                                     });
            
            await subject.GetOrCreateAccessToken();

            var generatedToken = Db.Set<OneTimeToken>().Single();

            _lifetimeScope.Received(1).BeginLifetimeScope();
            _childLifetimeScope.Received(1).Resolve<IRepository>();

            Assert.Equal(_defaultApiKey, generatedToken.Token);
            Assert.Equal(int.MinValue, generatedToken.CreatedBy);
            Assert.Equal(Fixture.Today().ToUniversalTime(), generatedToken.CreatedOn);
            Assert.Equal(Fixture.Today().ToUniversalTime().AddMinutes(5), generatedToken.ExpiryDate);
            Assert.Equal(ExternalApplicationName.InprotechServer.ToString(), generatedToken.ExternalApplicationName); 
        }
    }
}