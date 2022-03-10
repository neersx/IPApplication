using System;
using System.Collections.Generic;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core.Utilities;

namespace Inprotech.Setup.Core.Actions
{
    class InitInstall : ISetupAction
    {
        readonly IFileSystem _fileSystem;
        readonly IWebAppInfoManager _webAppInfoManager;
        readonly Func<string, IIisAppInfoManager> _iisAppInfoManagerFunc;
        readonly IValidator _validator;
        readonly ICryptoService _cryptoService;
        readonly Func<string, ISetupSettingsManager> _setupSettingsManager;
        readonly IVersionManager _versionManager;

        public InitInstall(
            IVersionManager versionManager,
            Func<string, ISetupSettingsManager> settingsManager,
            IFileSystem fileSystem,
            IWebAppInfoManager webAppInfoManager,
            Func<string, IIisAppInfoManager> iisAppInfoManager,
            IValidator validator,
            ICryptoService cryptoService)
        {
            _versionManager = versionManager;
            _setupSettingsManager = settingsManager;
            _fileSystem = fileSystem;
            _webAppInfoManager = webAppInfoManager;
            _iisAppInfoManagerFunc = iisAppInfoManager;
            _validator = validator;
            _cryptoService = cryptoService;
        }

        public string Description => "Preparing";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            var ctx = (SetupContext)context;
            var settingManager = _setupSettingsManager(ctx.PrivateKey);
            _validator.ValidateIisAppIsNotPaired(ctx.RootPath, ctx.IisSite, ctx.IisPath);

            var iisAppInfo = _iisAppInfoManagerFunc(ctx.IisAppInfoProfiles).Find(ctx.IisSite, ctx.IisPath);
            ctx.PairedIisApp = iisAppInfo;

            var instancePath = ctx.InstancePath = _webAppInfoManager.GetNewInstancePath(ctx.RootPath, ctx.IisPath);

            _validator.ValidateSafePathForNewInstance(instancePath);

            _fileSystem.EnsureDirectory(instancePath);
            _fileSystem.EnsureDirectory(ctx.StorageLocation);

            var settings = new SetupSettings
            {
                IisSite = ctx.IisSite,
                IisPath = ctx.IisPath,
                Status = SetupStatus.Begin,
                Version = _versionManager.GetCurrentWebAppVersion(),
                StorageLocation = ctx.StorageLocation,
                RunMode = SetupRunMode.New,
                DatabaseUsername = ctx.DatabaseUsername,
                DatabasePassword = ctx.DatabasePassword,
                AuthenticationMode = ctx.AuthenticationMode,
                Authentication2FAMode = ctx.Authentication2FAMode,
                IpPlatformSettings = ctx.IpPlatformSettings,
                AdfsSettings = ctx.AdfsSettings.Copy(),
                IntegrationServerPort = ctx.IntegrationServerPort,
                RemoteIntegrationServerUrl = ctx.RemoteIntegrationServerUrl,
                RemoteStorageServiceUrl = ctx.RemoteStorageServiceUrl,
                CookieConsentSettings = ctx.CookieConsentSettings,
                UsageStatisticsSettings = ctx.UsageStatisticsSettings,
                IisAppInfoProfiles = ctx.IisAppInfoProfiles
            };

            _cryptoService.Encrypt(ctx.PrivateKey, settings.AdfsSettings);
            ctx.Version = settings.Version;
            settingManager.Write(instancePath, settings);
            if (ctx.AuthenticationMode == null)
                ctx.AuthenticationMode = ctx.PairedIisApp.GetAuthenticationMode();
        }
    }
}