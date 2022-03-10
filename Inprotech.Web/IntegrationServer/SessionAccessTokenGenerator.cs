using System;
using System.Collections.Concurrent;
using System.Threading.Tasks;
using System.Transactions;
using Inprotech.Infrastructure.DependencyInjection;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.ExternalApplications;
using Inprotech.Integration.Persistence;

namespace Inprotech.Web.IntegrationServer
{
    public class SessionAccessTokenGenerator : ISessionAccessTokenGenerator
    {
        readonly ILifetimeScope _lifetimeScope;
        readonly Func<DateTime> _now;
        readonly ISessionAccessTokenInputResolver _sessionAccessTokenInputResolver;
        readonly ConcurrentDictionary<long, Token> _storedTokens = new ConcurrentDictionary<long, Token>();
        readonly Func<Guid> _tokenGenerator;

        public SessionAccessTokenGenerator(ISessionAccessTokenInputResolver sessionAccessTokenInputResolver, Func<Guid> tokenGenerator, Func<DateTime> now, ILifetimeScope lifetimeScope)
        {
            _sessionAccessTokenInputResolver = sessionAccessTokenInputResolver;
            _lifetimeScope = lifetimeScope;
            _tokenGenerator = tokenGenerator;
            _now = now;
        }

        public async Task<Guid> GetOrCreateAccessToken(string applicationName = nameof(ExternalApplicationName.InprotechServer))
        {
            if (string.IsNullOrWhiteSpace(applicationName)) throw new ArgumentNullException(nameof(applicationName));

            var token = _tokenGenerator();
            var createdBy = int.MinValue;
            var now = _now().ToUniversalTime();
            var expiry = now.AddMinutes(5);

            if (_sessionAccessTokenInputResolver.TryResolve(out var userId, out var sessionId))
            {
                if (_storedTokens.TryGetValue(sessionId, out var stored) && stored.Expiry > now)
                {
                    return stored.ApiKey;
                }

                createdBy = userId;

                var newToken = new Token
                {
                    ApiKey = token,
                    Expiry = expiry
                };

                _storedTokens.AddOrUpdate(sessionId,
                                          newToken,
                                          (k, v) =>
                                          {
                                              v.ApiKey = token;
                                              v.Expiry = expiry;

                                              return v;
                                          });
            }

            using (var scope = _lifetimeScope.BeginLifetimeScope())
            {
                var repository = scope.Resolve<IRepository>();

                using (var transactionScope = repository.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled, scopeOption: TransactionScopeOption.RequiresNew))
                {
                    repository.Set<OneTimeToken>()
                              .Add(new OneTimeToken
                              {
                                  ExternalApplicationName = applicationName,
                                  CreatedOn = now,
                                  CreatedBy = createdBy,
                                  ExpiryDate = expiry,
                                  Token = token
                              });

                    await repository.SaveChangesAsync();

                    transactionScope.Complete();
                }
            }

            return token;
        }

        class Token
        {
            public Guid ApiKey { get; set; }
            public DateTime Expiry { get; set; }
        }
    }
}