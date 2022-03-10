using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.ExternalApplications.Security.Authentication.ApiKey
{
    public class ApiKeyValidator : IApiKeyValidator
    {
        readonly IRepository _repository;
        readonly Func<DateTime> _systemClock;

        public ApiKeyValidator(IRepository repository, Func<DateTime> systemClock)
        {
            _repository = repository;
            _systemClock = systemClock;
        }

        public async Task<bool> ValidateApiToken(string apiKey, string applicationName, bool isOneTimeToken)
        {
            return isOneTimeToken
                ? await ProcessOneTimeToken(apiKey, applicationName)
                : await ValidateLongTermExternalApiToken(apiKey, applicationName);
        }

        async Task<bool> ValidateLongTermExternalApiToken(string apiKey, string applicationName)
        {
            var today = _systemClock().Date;

            return await _repository.Set<ExternalApplicationToken>()
                                    .AnyAsync(extapptoken => extapptoken.ExternalApplication.Name.Equals(applicationName)
                                                             && extapptoken.Token == apiKey
                                                             && extapptoken.IsActive
                                                             && (!extapptoken.ExpiryDate.HasValue || extapptoken.ExpiryDate.Value >= today));
        }

        async Task<bool> ProcessOneTimeToken(string apiKey, string applicationName)
        {
            if (!Guid.TryParse(apiKey, out var apiKeyGuid))
            {
                return false;
            }

            var now = _systemClock().ToUniversalTime();

            return await (from otk in _repository.Set<OneTimeToken>()
                          where otk.ExternalApplicationName == applicationName && otk.Token == apiKeyGuid && otk.ExpiryDate >= now
                          select otk).AnyAsync();
        }
    }
}