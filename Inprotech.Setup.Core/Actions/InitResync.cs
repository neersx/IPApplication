using System;
using System.Collections.Generic;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Core.Actions
{
    class InitResync : ISetupAction
    {
        readonly Func<string, ISetupSettingsManager> _settingsManagerFunc;
        readonly IValidator _validator;
        readonly Func<string, IIisAppInfoManager> _iisAppInfoManager;

        public InitResync(Func<string, ISetupSettingsManager> settingsManagerFunc, IValidator validator, Func<string, IIisAppInfoManager> iisAppInfoManager)
        {
            _settingsManagerFunc = settingsManagerFunc;
            _validator = validator;
            _iisAppInfoManager = iisAppInfoManager;
        }

        public string Description => "Preparing";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            var ctx = (SetupContext)context;
            var settingsManager = _settingsManagerFunc(ctx.PrivateKey);

            var instancePath = ctx.InstancePath;

            _validator.ValidateCommandLineInstallationFeatureIfRequired(instancePath);
            _validator.ValidateInstanceComplete(instancePath, settingsManager);
            _validator.ValidateSettingsFileExists(instancePath);

            var settings = settingsManager.Read(instancePath);
            settings.RunMode = SetupRunMode.Resync;
            settings.Status = SetupStatus.Begin;

            var iisAppInfo = _iisAppInfoManager(settings.IisAppInfoProfiles).Find(settings.IisSite, settings.IisPath);
            _validator.ValidateMustUpgrade(instancePath, iisAppInfo);

            ctx.Version = settings.Version;
            ctx.PairedIisApp = iisAppInfo;
            ctx.StorageLocation = settings.StorageLocation;
            ctx.IntegrationServerPort = settings.IntegrationServerPort;
            ctx.RemoteIntegrationServerUrl = settings.RemoteIntegrationServerUrl;
            ctx.RemoteStorageServiceUrl = settings.RemoteStorageServiceUrl;

            if (ctx.DatabaseUsername != null)
                settings.DatabaseUsername = ctx.DatabaseUsername;
            if (ctx.DatabasePassword != null)
                settings.DatabasePassword = ctx.DatabasePassword;

            ctx.AuthenticationMode = !string.IsNullOrEmpty(settings.AuthenticationMode) ? settings.AuthenticationMode : iisAppInfo.GetAuthenticationMode();
            ctx.Authentication2FAMode = settings.Authentication2FAMode;
            
            ctx.CookiePath = iisAppInfo.WebConfig.CookiePath;
            ctx.CookieDomain = iisAppInfo.WebConfig.CookieDomain;
            ctx.CookieName = iisAppInfo.WebConfig.CookieName;

            settingsManager.Write(instancePath, settings);
        }
    }
}