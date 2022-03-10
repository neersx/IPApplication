using System;
using System.Collections.Generic;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core.Utilities;

namespace Inprotech.Setup.Core.Actions
{
    class InitUpdate : ISetupAction
    {
        readonly Func<string, ISetupSettingsManager> _settingsManagerFunc;
        readonly IValidator _validator;
        readonly Func<string, IIisAppInfoManager> _iisAppInfoManager;
        readonly ICryptoService _cryptoService;

        public InitUpdate(Func<string, ISetupSettingsManager> settingsManagerFunc, IValidator validator, Func<string, IIisAppInfoManager> iisAppInfoManager, ICryptoService cryptoService)
        {
            _settingsManagerFunc = settingsManagerFunc;
            _validator = validator;
            _iisAppInfoManager = iisAppInfoManager;
            _cryptoService = cryptoService;
        }

        public string Description => "Preparing";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            var ctx = (SetupContext)context;
            var settingsManager = _settingsManagerFunc(ctx.PrivateKey);
            var instancePath = ctx.InstancePath;

            _validator.ValidateCommandLineInstallationFeatureIfRequired(instancePath);
            _validator.RequireUpdateFeature(instancePath);
            _validator.ValidateSettingsFileExists(instancePath);
            _validator.ValidateInstanceComplete(instancePath, settingsManager);
            
            var settings = settingsManager.Read(instancePath);

            var iisAppInfo = _iisAppInfoManager(ctx.IisAppInfoProfiles).Find(settings.IisSite, settings.IisPath);
            ctx.PairedIisApp = iisAppInfo;

            _validator.ValidateMustUpgrade(instancePath, iisAppInfo);

            if (ctx.StorageLocation != null)
                settings.StorageLocation = ctx.StorageLocation;
            if (ctx.DatabaseUsername != null)
                settings.DatabaseUsername = ctx.DatabaseUsername;
            if (ctx.DatabasePassword != null)
                settings.DatabasePassword = ctx.DatabasePassword;

            settings.AuthenticationMode = ctx.AuthenticationMode;
            settings.Authentication2FAMode = ctx.Authentication2FAMode;

            settings.IpPlatformSettings = ctx.IpPlatformSettings;

            settings.AdfsSettings = ctx.AdfsSettings.Copy();
            _cryptoService.Encrypt(ctx.PrivateKey, settings.AdfsSettings);

            if (ctx.AuthenticationMode == null)
                ctx.AuthenticationMode = iisAppInfo.GetAuthenticationMode();

            settings.IntegrationServerPort = ctx.IntegrationServerPort;
            settings.RemoteIntegrationServerUrl = ctx.RemoteIntegrationServerUrl;
            settings.RemoteStorageServiceUrl = ctx.RemoteStorageServiceUrl;
            settings.CookieConsentSettings = ctx.CookieConsentSettings;
            settings.UsageStatisticsSettings = ctx.UsageStatisticsSettings;

            settings.RunMode = SetupRunMode.Update;
            settings.Status = SetupStatus.Begin;

            settingsManager.Write(instancePath, settings);
        }
    }
}