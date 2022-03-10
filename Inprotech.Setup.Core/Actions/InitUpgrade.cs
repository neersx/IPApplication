using System;
using System.Collections.Generic;
using System.IO;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core.Utilities;

namespace Inprotech.Setup.Core.Actions
{
    class InitUpgrade : ISetupAction
    {
        readonly Func<string, ISetupSettingsManager> _settingsManagerFunc;
        readonly IWebAppInfoManager _webAppInfoManager;
        readonly IValidator _validator;
        readonly Func<string, IIisAppInfoManager> _iisAppInfoManager;
        readonly IFileSystem _fileSystem;
        readonly ICryptoService _cryptoService;

        public InitUpgrade(Func<string, ISetupSettingsManager> settingsManagerFunc, IWebAppInfoManager webAppInfoManager, IValidator validator, Func<string, IIisAppInfoManager> iisAppInfoManager, IFileSystem fileSystem, ICryptoService cryptoService)
        {
            _settingsManagerFunc = settingsManagerFunc;
            _webAppInfoManager = webAppInfoManager;
            _validator = validator;
            _iisAppInfoManager = iisAppInfoManager;
            _fileSystem = fileSystem;
            _cryptoService = cryptoService;
        }

        public string Description => "Preparing";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            var ctx = (SetupContext)context;
            var settingsManager = _settingsManagerFunc(ctx.PrivateKey);
            var instancePath = ctx.InstancePath;

            _validator.ValidateSettingsFileExists(instancePath);
            _validator.ValidateInstanceComplete(instancePath, settingsManager);
            _validator.ValidateCanUpgrade(instancePath);
            
            var settings = settingsManager.Read(instancePath);

            var iisAppInfo = _iisAppInfoManager(settings.IisAppInfoProfiles).Find(settings.IisSite, settings.IisPath);

            ctx.PairedIisApp = iisAppInfo;

            if (ctx.NewRootPath != null)
            {
                var newInstancePath = Path.Combine(ctx.NewRootPath, Helpers.GetInstanceName(instancePath));

                if (Helpers.ArePathsEqual(newInstancePath, instancePath)) // if the new root path is same as current one, just ignore it.
                {
                    ctx.NewRootPath = null;
                    ctx.NewInstancePath = null;
                    settings.NewInstancePath = null;
                }
                else
                {
                    if (_fileSystem.DirectoryExists(newInstancePath)) // use new instance folder if target already exists
                        newInstancePath = _webAppInfoManager.GetNewInstancePath(ctx.NewRootPath, settings.IisPath);

                    _validator.ValidateSafePathForNewInstance(newInstancePath);

                    ctx.NewInstancePath = newInstancePath;
                    settings.NewInstancePath = newInstancePath;
                }
            }
            else
            {
                settings.NewInstancePath = null;
            }

            if (ctx.StorageLocation != null)
                settings.StorageLocation = ctx.StorageLocation;

            if (ctx.DatabaseUsername != null)
                settings.DatabaseUsername = ctx.DatabaseUsername;

            if (ctx.DatabasePassword != null)
                settings.DatabasePassword = ctx.DatabasePassword;

            settings.AuthenticationMode = ctx.AuthenticationMode;
            settings.Authentication2FAMode = ctx.Authentication2FAMode;

            settings.IpPlatformSettings = ctx.IpPlatformSettings;

            settings.IntegrationServerPort = ctx.IntegrationServerPort;
            settings.RemoteIntegrationServerUrl = ctx.RemoteIntegrationServerUrl;
            settings.RemoteStorageServiceUrl = ctx.RemoteStorageServiceUrl;

            settings.CookieConsentSettings = ctx.CookieConsentSettings;

            settings.AdfsSettings = ctx.AdfsSettings.Copy();
            _cryptoService.Encrypt(ctx.PrivateKey, settings.AdfsSettings);

            if (ctx.AuthenticationMode == null)
                ctx.AuthenticationMode = ctx.PairedIisApp.GetAuthenticationMode();

            settings.RunMode = SetupRunMode.Upgrade;
            settings.Status = SetupStatus.Begin;

            settingsManager.Write(instancePath, settings);
        }
    }
}