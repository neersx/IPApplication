using System;
using System.Collections.Generic;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core.Utilities;

namespace Inprotech.Setup.Core.Actions
{
    class InitResume : ISetupAction
    {
        readonly Func<string, ISetupSettingsManager> _setupSettingsManagerFunc;
        readonly Func<string, IIisAppInfoManager> _iisAppInfoManager;
        readonly IValidator _validator;
        readonly ICryptoService _cryptoService;

        public InitResume(Func<string, ISetupSettingsManager> setupSettingsManagerFunc, Func<string, IIisAppInfoManager> iisAppInfoManager, IValidator validator, ICryptoService cryptoService)
        {
            _setupSettingsManagerFunc = setupSettingsManagerFunc;
            _iisAppInfoManager = iisAppInfoManager;
            _validator = validator;
            _cryptoService = cryptoService;
        }

        public string Description => "Preparing";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            var ctx = (SetupContext)context;

            _validator.ValidateSettingsFileExists(ctx.InstancePath);

            var settingsManager = _setupSettingsManagerFunc(ctx.PrivateKey);
            var settings = settingsManager.Read(ctx.InstancePath);
            var iisAppInfo = _iisAppInfoManager(ctx.IisAppInfoProfiles).Find(settings.IisSite, settings.IisPath);

            if (settings.Status == SetupStatus.Complete)
                throw new Exception("Setup is already complete.");

            if (ctx.DatabaseUsername != null)
                settings.DatabaseUsername = ctx.DatabaseUsername;
            if (ctx.DatabasePassword != null)
                settings.DatabasePassword = ctx.DatabasePassword;

            settingsManager.Write(ctx.InstancePath, settings);

            ctx.SetupSettings = settings;
            ctx.PairedIisApp = iisAppInfo;

            ctx.AuthenticationMode = !string.IsNullOrEmpty(settings.AuthenticationMode) ? settings.AuthenticationMode : iisAppInfo.GetAuthenticationMode();
            ctx.Authentication2FAMode = settings.Authentication2FAMode;

            ctx.AdfsSettings = settings.AdfsSettings.Copy();
            _cryptoService.Decrypt(ctx.PrivateKey, ctx.AdfsSettings);

            ctx.IpPlatformSettings = settings.IpPlatformSettings;

            ctx.IntegrationServerPort = settings.IntegrationServerPort;
            ctx.RemoteIntegrationServerUrl = settings.RemoteIntegrationServerUrl;
            ctx.RemoteStorageServiceUrl = settings.RemoteStorageServiceUrl;

            ctx.CookieConsentSettings = settings.CookieConsentSettings;
            ctx.UsageStatisticsSettings = settings.UsageStatisticsSettings;

            switch (settings.RunMode)
            {
                case SetupRunMode.New:
                    ctx.Workflow.BuildResumeNewWorkflow();
                    break;
                case SetupRunMode.Remove:
                    ctx.Workflow.BuildRemoveWorkflow();
                    break;
                case SetupRunMode.Resync:
                    _validator.ValidateCommandLineInstallationFeatureIfRequired(ctx.InstancePath);
                    ctx.Workflow.BuildResyncWorkflow();
                    break;
                case SetupRunMode.Update:
                    _validator.ValidateCommandLineInstallationFeatureIfRequired(ctx.InstancePath);
                    ctx.Workflow.BuildUpdateWorkflow();
                    break;
                case SetupRunMode.Upgrade:
                    ctx.Workflow.BuildUpgradeWorkflow();
                    break;
            }
        }
    }
}