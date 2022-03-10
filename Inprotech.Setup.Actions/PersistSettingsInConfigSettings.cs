using System;
using System.Collections.Generic;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Actions
{
    public class PersistSettingsInConfigSettings : ISetupAction
    {
        readonly IInprotechServerPersistingConfigManager _inprotechServerPersistingConfigManager;
        IAdfsConfigPersistence _adfsConfigPersistence;
        string _connectionString;
        IDictionary<string, object> _context;
        IEventStream _eventStream;

        public PersistSettingsInConfigSettings()
        {
            _inprotechServerPersistingConfigManager = new InprotechServerPersistingConfigManager();
        }

        /// <summary>
        ///     For Testing only.
        /// </summary>
        /// <param name="ipPlatformConfigPersistance"></param>
        /// <param name="adfsConfigPersistence"></param>
        public PersistSettingsInConfigSettings(IInprotechServerPersistingConfigManager ipPlatformConfigPersistance, IAdfsConfigPersistence adfsConfigPersistence)
        {
            _inprotechServerPersistingConfigManager = ipPlatformConfigPersistance;
            _adfsConfigPersistence = adfsConfigPersistence;
        }

        string PrivateKey => _context.ContainsKey(Constants.AppSettings.InprotechServerSettings.PrivateKey)
            ? (string)_context[Constants.AppSettings.InprotechServerSettings.PrivateKey]
            : null;

        public bool ContinueOnException => false;

        public string Description => "Persist Configuration Settings";

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            _context = context ?? throw new ArgumentNullException(nameof(context));
            _eventStream = eventStream ?? throw new ArgumentNullException(nameof(eventStream));

            _connectionString = (string)context["InprotechConnectionString"];
            _adfsConfigPersistence = _adfsConfigPersistence ?? new AdfsConfigPersistence(_connectionString);

            PersistIpPlatformSettings();
            PersistAuthenticationMode();
            PersistAuthentication2FAMode();
            RemovePrivateKeyFromDb();
            PersistAdfsSettings();
            PersistSetupSettings();
        }

        void PersistSetupSettings()
        {
            CookieConsentSettings cookieConsentSetting;
            if (!_context.TryGetValue("CookieConsentSettings", out var ctxCookie) || (cookieConsentSetting = ctxCookie as CookieConsentSettings) == null)
            {
                return;
            }

            _inprotechServerPersistingConfigManager.SetSetupValues(_connectionString, new Dictionary<string, string>
            {
                {Constants.InprotechServer.SetupConfiguration.CookieConsentBannerHook, cookieConsentSetting.CookieConsentBannerHook?.Trim()},
                {Constants.InprotechServer.SetupConfiguration.CookieDeclarationHook, cookieConsentSetting.CookieDeclarationHook?.Trim()},
                {Constants.InprotechServer.SetupConfiguration.CookieResetConsentHook, cookieConsentSetting.CookieResetConsentHook?.Trim()},
                {Constants.InprotechServer.SetupConfiguration.CookieConsentVerificationHook, cookieConsentSetting.CookieConsentVerificationHook?.Trim()},
                {Constants.InprotechServer.SetupConfiguration.PreferenceConsentVerificationHook, cookieConsentSetting.PreferenceConsentVerificationHook?.Trim()},
                {Constants.InprotechServer.SetupConfiguration.StatisticsConsentVerificationHook, cookieConsentSetting.StatisticsConsentVerificationHook?.Trim()}
            });
        }

        void PersistIpPlatformSettings()
        {
            IpPlatformSettings ipPlatformSettings;
            if (!AuthModeUtility.IsAuthModeEnabled(_context, Constants.AuthenticationModeKeys.Sso) || !_context.ContainsKey("IpPlatformSettings") || (ipPlatformSettings = _context["IpPlatformSettings"] as IpPlatformSettings) == null)
            {
                return;
            }

            _inprotechServerPersistingConfigManager.SetIpPlatformSettings(_connectionString, PrivateKey, ipPlatformSettings);
            _eventStream.PublishInformation("Persisting The IP Platform settings");
        }

        void RemovePrivateKeyFromDb()
        {
            _inprotechServerPersistingConfigManager.RemovePrivateKey(_connectionString);
            _eventStream.PublishInformation("Removing PrivateKey settings");
        }

        void PersistAdfsSettings()
        {
            AdfsSettings adfsSettings;
            if (!AuthModeUtility.IsAuthModeEnabled(_context, Constants.AuthenticationModeKeys.Adfs) || !_context.ContainsKey("AdfsSettings") || (adfsSettings = _context["AdfsSettings"] as AdfsSettings) == null)
            {
                return;
            }

            _adfsConfigPersistence.SetAdfsSettings(PrivateKey, adfsSettings);
            _eventStream.PublishInformation("Persisting ADFS settings");
        }

        void PersistAuthenticationMode()
        {
            if (!_context.ContainsKey("AuthenticationMode"))
            {
                return;
            }

            _inprotechServerPersistingConfigManager.SaveAuthMode(_connectionString, (string)_context["AuthenticationMode"]);
            _eventStream.PublishInformation("Persisting Authentication Mode settings");
        }

        void PersistAuthentication2FAMode()
        {
            if (!_context.ContainsKey("Authentication2FAMode"))
            {
                return;
            }

            _inprotechServerPersistingConfigManager.Save2FAAuthMode(_connectionString, (string)_context["Authentication2FAMode"]);
            _eventStream.PublishInformation("Persisting Authentication Two Factor Mode settings");
        }
    }
}