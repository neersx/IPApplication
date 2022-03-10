using System;
using System.Collections.Concurrent;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Compatibility;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Web.Security
{
    internal class TokenExtender : ITokenExtender
    {
        const int ExtensionToleranceMinutesDefault = 3;
        static readonly ConcurrentDictionary<long, object> ExtensionsInProgress = new ConcurrentDictionary<long, object>();
        readonly IAuthSettings _authSettings;
        readonly ITokenRefresh _tokenRefresh;
        readonly IInprotechVersionChecker _inprotechVersionChecker;
        readonly Func<DateTime> _now;
        readonly IUserIdentityAccessManager _userIdentityAccessManager;

        public TokenExtender(IAuthSettings authSettings, IUserIdentityAccessManager userIdentityAccessManager, ITokenRefresh tokenRefresh, IInprotechVersionChecker inprotechVersionChecker, Func<DateTime> now)
        {
            _authSettings = authSettings;
            _userIdentityAccessManager = userIdentityAccessManager;
            _tokenRefresh = tokenRefresh;
            _inprotechVersionChecker = inprotechVersionChecker;
            _now = now;
        }

        async Task<(bool shouldExtend, bool tokenValid)> TrySsoSessionExtension(AuthCookieData cookieData)
        {
            if (!new[] { AuthenticationModeKeys.Sso, AuthenticationModeKeys.Adfs }.Contains(cookieData.AuthMode))
                return (false, false);

            var (data, lastExtension) = await _userIdentityAccessManager.GetSigninData(cookieData.LogId, cookieData.UserId, cookieData.AuthMode);

            if (string.IsNullOrEmpty(data?.RefreshToken))
                return (false, false);

            if (lastExtension != null && lastExtension > _now().AddMinutes(-ExtensionToleranceMinutesDefault))
                return (ShouldRefreshEveryTime, true);

            var ssoProviderResponse = _tokenRefresh.Refresh(data.AccessToken, data.RefreshToken, cookieData.AuthMode);

            data.AccessToken = ssoProviderResponse.AccessToken;
            data.RefreshToken = ssoProviderResponse.RefreshToken;

            await _userIdentityAccessManager.ExtendProviderSession(cookieData.LogId, cookieData.UserId, cookieData.AuthMode, data);
            return (true, true);
        }

        public async Task<(bool shouldExtend, bool tokenValid)> ShouldExtend(AuthCookieData cookieData)
        {
            if (cookieData == null && !_inprotechVersionChecker.CheckMinimumVersion(12, 1))
                return (false, true);

            if (cookieData == null
                || !new[] { AuthenticationModeKeys.Sso, AuthenticationModeKeys.Adfs, AuthenticationModeKeys.Windows, AuthenticationModeKeys.Forms }.Contains(cookieData.AuthMode)
                || !_authSettings.AuthenticationModeEnabled(cookieData.AuthMode))
                return (false, false);

            if (!ExtensionsInProgress.TryAdd(cookieData.LogId, null))
                return (false, true);

            try
            {
                if (new[] { AuthenticationModeKeys.Windows, AuthenticationModeKeys.Forms }.Contains(cookieData.AuthMode))
                {
                    var needsExtension = await TryExtendProviderSession(cookieData);
                    return (needsExtension, true);
                }
                return await TrySsoSessionExtension(cookieData);
            }
            catch
            {
                return (false, false);
            }
            finally
            {
                ExtensionsInProgress.TryRemove(cookieData.LogId, out object _);
            }
        }

        async Task<bool> TryExtendProviderSession(AuthCookieData cookieData)
        {
            return await _userIdentityAccessManager.TryExtendProviderSession(cookieData.LogId, cookieData.UserId, cookieData.AuthMode, null, ExtensionToleranceMinutes);
        }

        int ExtensionToleranceMinutes => ExtensionToleranceMinutesDefault <= _authSettings.SessionTimeout / 3 ? ExtensionToleranceMinutesDefault : 0;

        bool ShouldRefreshEveryTime => ExtensionToleranceMinutes != ExtensionToleranceMinutesDefault;
    }
}