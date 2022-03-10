using System;
using System.Collections.Concurrent;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Integration.DmsIntegration.Component.iManage
{
    public interface ICredentialsResolver
    {
        Task<DmsCredential> Resolve(IManageSettings.SiteDatabaseSettings settings);
    }

    public class CredentialsResolver : ICredentialsResolver
    {
        readonly ISecurityContext _currentUserContext;
        readonly ILogger<CredentialsResolver> _log;
        readonly IPersistedCredentialsResolver _persistedCredentialsResolver;

        // intentionally non-static
        readonly ConcurrentDictionary<int, DmsCredential> _cache = new ConcurrentDictionary<int, DmsCredential>();

        public CredentialsResolver(ILogger<CredentialsResolver> log,
                                   ISecurityContext currentUserContext,
                                   IPersistedCredentialsResolver persistedCredentialsResolver)
        {
            _log = log;
            _currentUserContext = currentUserContext;
            _persistedCredentialsResolver = persistedCredentialsResolver;
        }

        public async Task<DmsCredential> Resolve(IManageSettings.SiteDatabaseSettings settings)
        {
            if (_cache.TryGetValue(settings.GetHashCode(), out DmsCredential dmsCredential))
                return dmsCredential;

            if (settings.IsInprotechUsernameWithImpersonationEnabled)
            {
                dmsCredential = new DmsCredential
                {
                    UserName = _currentUserContext.User.UserName
                };

                _cache.TryAdd(settings.GetHashCode(), dmsCredential);

                return dmsCredential;
            }

            if (settings.IsOAuth2Enabled)
            {
                dmsCredential = new DmsCredential
                {
                    UserName = _currentUserContext.User.UserName,
                    Password = string.Empty
                };

                _cache.TryAdd(settings.GetHashCode(), dmsCredential);

                return dmsCredential;
            }

            dmsCredential = await _persistedCredentialsResolver.Resolve() ?? new DmsCredential();

            LogPotentialConfigurationIssues(settings, dmsCredential);

            _cache.TryAdd(settings.GetHashCode(), dmsCredential);

            return dmsCredential;
        }

        void LogPotentialConfigurationIssues(IManageSettings.SiteDatabaseSettings settings, DmsCredential dmsCredential)
        {
            var issues = string.Join(Environment.NewLine, new[]
            {
                ValidateUsernameRequired(settings, dmsCredential),
                ValidatePasswordRequired(settings, dmsCredential)
            }.Where(x => !string.IsNullOrWhiteSpace(x)));

            if (!string.IsNullOrWhiteSpace(issues))
            {
                _log.Warning("Credentials resolved for DMS Connectivity returned some potential issues." +
                             Environment.NewLine + issues);
            }
        }

        string ValidateUsernameRequired(IManageSettings.SiteDatabaseSettings settings, DmsCredential dmsCredential)
        {
            var requiresWorkSiteLoginId = settings.IsUsernamePasswordRequired ||
                                          settings.IsUsernameWithImpersonationEnabled;

            if (string.IsNullOrWhiteSpace(dmsCredential.UserName) && requiresWorkSiteLoginId)
            {
                return
                    "* No Username found. This may indicate 'Login ID' is not configured. This can be found in the 'iManage Integration' group of user preferences.";
            }

            return null;
        }

        string ValidatePasswordRequired(IManageSettings.SiteDatabaseSettings settings, DmsCredential dmsCredential)
        {
            var requiresPassword = settings.IsUsernamePasswordRequired;

            if (string.IsNullOrWhiteSpace(dmsCredential.Password) && requiresPassword)
            {
                return
                    "* No password found. This may indicate 'Password' is not configured. This can be found in the 'iManage Integration' group of user preferences.";
            }

            return null;
        }
    }
}
