using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Security;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using Newtonsoft.Json;

namespace Inprotech.Infrastructure.Security
{
    public interface IAuthSettings
    {
        int SessionTimeout { get; }
        string SessionCookieName { get; }
        string SessionCookiePath { get; }
        string SessionCookieDomain { get; }
        bool FormsEnabled { get; }
        bool WindowsEnabled { get; }
        bool SsoEnabled { get; }
        bool AdfsEnabled { get; }
        bool Internal2FaEnabled { get; }
        bool External2FaEnabled { get; }
        string SignInUrl { get; }
        string ParentPath { get; }
        bool TwoFactorAuthenticationEnabled(bool isUserExternal);
        bool AuthenticationModeEnabled(string authMode);
        CookieConsentFlags CookieConsentSettings { get; }
    }

    public static class AuthSettingsResolver
    {
        const int DefaultSessionTimeout = 30;

        public static void Resolve(AuthSettings authSettings, Func<string, IGroupedConfig> groupedConfig, IConfigurationSettings appConfigurationSettings)
        {
            var keys = new[]
            {
                KnownAppSettingsKeys.AuthenticationMode,
                KnownAppSettingsKeys.Authentication2FAMode,
                KnownAppSettingsKeys.SessionCookieName,
                KnownAppSettingsKeys.SessionCookiePath,
                KnownAppSettingsKeys.SessionCookieDomain,
                KnownAppSettingsKeys.ParentPath,
                KnownAppSettingsKeys.SignInUrl,
                "SessionTimeout"
            };

            var settings = groupedConfig("InprotechServer.AppSettings").GetValues(keys);
            foreach (var key in keys)
            {
                if (!settings.ContainsKey(key))
                {
                    settings[key] = appConfigurationSettings[key];
                }
            }

            var authModes = new ConfiguredAuthMode(settings[KnownAppSettingsKeys.AuthenticationMode]);

            var twoFactorAuthModes = new ConfiguredTwoFactorAuthMode(settings[KnownAppSettingsKeys.Authentication2FAMode]);

            var sessionTimeout = !int.TryParse(settings["SessionTimeout"], out var timeout)
                ? DefaultSessionTimeout
                : timeout;

            var signInUrl = settings[KnownAppSettingsKeys.ParentPath] + "/" + settings[KnownAppSettingsKeys.SignInUrl];

            var cookieConsentFlags = Resolve(groupedConfig);

            authSettings.FormsEnabled = authModes.FormsEnabled;
            authSettings.WindowsEnabled = authModes.WindowsEnabled;
            authSettings.SsoEnabled = authModes.SsoEnabled;
            authSettings.AdfsEnabled = authModes.AdfsEnabled;
            authSettings.Internal2FaEnabled = twoFactorAuthModes.InternalEnabled;
            authSettings.External2FaEnabled = twoFactorAuthModes.ExternalEnabled;
            authSettings.SessionTimeout = sessionTimeout;
            authSettings.SessionCookieName = settings[KnownAppSettingsKeys.SessionCookieName];
            authSettings.SessionCookiePath = settings[KnownAppSettingsKeys.SessionCookiePath].NullIfEmptyOrWhitespace();
            authSettings.SessionCookieDomain = settings[KnownAppSettingsKeys.SessionCookieDomain].NullIfEmptyOrWhitespace();
            authSettings.SignInUrl = signInUrl;
            authSettings.ParentPath = settings[KnownAppSettingsKeys.ParentPath];
            authSettings.CookieConsentSettings = cookieConsentFlags;
        }

        static CookieConsentFlags Resolve(Func<string, IGroupedConfig> groupedConfig)
        {
            Dictionary<string, string> cookieConsentSettings;

            var setupSettings = groupedConfig(KnownSetupSettingKeys.ConfigGroup)[KnownSetupSettingKeys.ConfigKey];

            var settings = new JsonSerializerSettings {Error = (se, ev) => ev.ErrorContext.Handled = true};

            if (string.IsNullOrEmpty(setupSettings) || (cookieConsentSettings = JsonConvert.DeserializeObject<Dictionary<string, string>>(setupSettings, settings)) == null)
            {
                return new CookieConsentFlags();
            }

            bool HasValue(string key)
            {
                return cookieConsentSettings.ContainsKey(key) && !string.IsNullOrEmpty(cookieConsentSettings[key]?.Trim());
            }

            var isConfigured = HasValue(KnownSetupSettingKeys.CookieConsentBannerHook);
            return new CookieConsentFlags
            {
                IsConfigured = isConfigured,
                IsResetConfigured = isConfigured && HasValue(KnownSetupSettingKeys.CookieResetConsentHook),
                IsVerificationConfigured = isConfigured && (HasValue(KnownSetupSettingKeys.CookieConsentVerificationHook) || HasValue(KnownSetupSettingKeys.PreferenceConsentVerificationHook))
            };
        }
    }

    public class QaAuthSettings
    {
        readonly Func<string, IGroupedConfig> _groupedConfig;
        readonly IConfigurationSettings _appConfigurationSettings;
        readonly ILogger<QaAuthSettings> _logger;
        readonly AuthSettings _authSettings;

        public QaAuthSettings(Func<string, IGroupedConfig> groupedConfig, 
                              IConfigurationSettings appConfigurationSettings, 
                              ILogger<QaAuthSettings> logger,
                              AuthSettings authSettings)
        {
            _groupedConfig = groupedConfig;
            _appConfigurationSettings = appConfigurationSettings;
            _logger = logger;
            _authSettings = authSettings;
        }

        public void Reload()
        {
            _logger.Warning("authSettings being refreshed");

            AuthSettingsResolver.Resolve(_authSettings, _groupedConfig, _appConfigurationSettings);

            _logger.Debug(JsonConvert.SerializeObject(_authSettings));
        }
    }

    public class AuthSettings : IAuthSettings
    {
        public bool FormsEnabled { get; set; }

        public bool WindowsEnabled { get; set; }

        public bool SsoEnabled { get; set; }

        public bool AdfsEnabled { get; set; }

        public bool Internal2FaEnabled { get; set; }

        public bool External2FaEnabled { get; set; }

        public int SessionTimeout { get; set; }

        public string SessionCookieName { get; set; }

        public string SessionCookiePath { get; set; }

        public string SessionCookieDomain { get; set; }

        public string SignInUrl { get; set; }

        public string ParentPath { get; set; }

        public CookieConsentFlags CookieConsentSettings { get; set; }

        public bool TwoFactorAuthenticationEnabled(bool isUserExternal)
        {
            return isUserExternal ? External2FaEnabled : Internal2FaEnabled;
        }

        public bool AuthenticationModeEnabled(string authMode)
        {
            switch (authMode)
            {
                case AuthenticationModeKeys.Forms:
                    return FormsEnabled;
                case AuthenticationModeKeys.Windows:
                    return WindowsEnabled;
                case AuthenticationModeKeys.Sso:
                    return SsoEnabled;
                case AuthenticationModeKeys.Adfs:
                    return AdfsEnabled;
            }

            return false;
        }
    }

    public static class AuthSettingsExt
    {
        static bool PreventManualLogout(this IAuthSettings settings)
        {
            return settings.WindowsEnabled && !settings.FormsEnabled && !settings.SsoEnabled;
        }

        public static FormsAuthenticationTicket CreateAuthTicket(this IAuthSettings settings, AuthUser user)
        {
            return new FormsAuthenticationTicket(1, user.Username,
                                                 DateTime.Now,
                                                 DateTime.Now.AddMinutes(settings.SessionTimeout),
                                                 false, new AuthCookieData(user, settings.PreventManualLogout()).ToJson(),
                                                 settings.SessionCookiePath);
        }
    }

    public class ConfiguredAuthMode
    {
        public ConfiguredAuthMode(string authModes)
        {
            var enabled = (authModes ?? string.Empty).Split(',').Select(x => x.Trim()).ToArray();

            FormsEnabled = enabled.Contains(AuthenticationModeKeys.Forms, StringComparer.InvariantCultureIgnoreCase);

            WindowsEnabled = enabled.Contains(AuthenticationModeKeys.Windows, StringComparer.InvariantCultureIgnoreCase);

            SsoEnabled = enabled.Contains(AuthenticationModeKeys.Sso, StringComparer.InvariantCultureIgnoreCase);

            AdfsEnabled = enabled.Contains(AuthenticationModeKeys.Adfs, StringComparer.InvariantCultureIgnoreCase);
        }

        public bool FormsEnabled { get; }

        public bool WindowsEnabled { get; }

        public bool SsoEnabled { get; }

        public bool AdfsEnabled { get; }
    }

    public static class AuthenticationModeKeys
    {
        public const string Forms = "Forms";
        public const string Windows = "Windows";
        public const string Sso = "Sso";
        public const string Adfs = "Adfs";
    }

    public class ConfiguredTwoFactorAuthMode
    {
        public ConfiguredTwoFactorAuthMode(string authModes)
        {
            var enabled = (authModes ?? string.Empty).Split(',').Select(x => x.Trim()).ToArray();

            InternalEnabled = enabled.Contains(TwoFactorAuthenticationModeKeys.Internal, StringComparer.InvariantCultureIgnoreCase);
            ExternalEnabled = enabled.Contains(TwoFactorAuthenticationModeKeys.External, StringComparer.InvariantCultureIgnoreCase);
        }

        public bool InternalEnabled { get; }

        public bool ExternalEnabled { get; }
    }

    public class CookieConsentFlags
    {
        public bool IsConfigured { get; set; }
        public bool IsResetConfigured { get; set; }
        public bool IsVerificationConfigured { get; set; }
    }

    public static class TwoFactorAuthenticationModeKeys
    {
        public const string Internal = "Internal";
        public const string External = "External";
    }
}