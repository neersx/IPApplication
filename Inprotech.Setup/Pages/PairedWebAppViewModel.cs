using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Windows;
using Caliburn.Micro;
using Inprotech.Setup.Core;
using Inprotech.Setup.UI;

namespace Inprotech.Setup.Pages
{
    public class PairedWebAppViewModel : PropertyChangedBase
    {
        public delegate PairedWebAppViewModel Factory(WebAppInfoWrapper webAppInfo);

        readonly WebAppInfoWrapper _webAppInfo;
        readonly IShell _shell;
        readonly Func<SetupRunnerViewModel> _setupRunnerViewModel;
        readonly IMessageBox _messageBox;
        readonly IVersionManager _versionManager;
        readonly Func<SettingsViewModel> _settingViewModel;
        readonly IAppConfigReader _appConfigReader;

        public PairedWebAppViewModel(
            WebAppInfoWrapper webAppInfo,
            IShell shell,
            Func<SetupRunnerViewModel> setupRunnerViewModel,
            IMessageBox messageBox,
            IVersionManager versionManager,
            Func<SettingsViewModel> settingViewModel,
            IAppConfigReader appConfigReader)
        {
            _shell = shell;
            _setupRunnerViewModel = setupRunnerViewModel;
            _messageBox = messageBox;
            _versionManager = versionManager;
            _settingViewModel = settingViewModel;
            _appConfigReader = appConfigReader;

            _webAppInfo = webAppInfo;

            InstanceConfiguration = new BindableCollection<WebAppConfigurationViewModel>();

            if (_webAppInfo.IsComplete)
            {
                InstanceConfiguration.AddRange(_webAppInfo.ComponentConfigurations.Select(_ => new WebAppConfigurationViewModel(_)));
            }
        }

        public string Title
        {
            get
            {
                var status = _webAppInfo.IsPaired
                    ? (_webAppInfo.IsComplete ? "complete" : "incomplete")
                    : "unpaired";

                if (_webAppInfo.IsPaired)
                {
                    return string.Format(
                                         "{0}({1}) | {2}({3}) | {4}",
                                         _webAppInfo.PairedIisAppInfo.Site + _webAppInfo.PairedIisAppInfo.VirtualPath,
                                         _webAppInfo.MainProductVersion,
                                         _webAppInfo.InstanceName,
                                         _webAppInfo.Version,
                                         status);
                }

                return string.Format(
                                     "{0}({1}) | {2}",
                                     _webAppInfo.InstanceName,
                                     _webAppInfo.Version,
                                     status);
            }
        }

        public BindableCollection<WebAppConfigurationViewModel> InstanceConfiguration { get; private set; }

        public bool ShouldDisplayResync => _webAppInfo.CanResync;

        public bool ShouldDisplayUpgrade => _webAppInfo.CanUpgrade;

        public bool ShouldDisplayResume => _webAppInfo.CanResume;

        public bool ShouldDisplaySettings => _webAppInfo.CanUpdate;

        public async void Remove()
        {
            var result = _messageBox.Confirm($"Are you sure to remove the paired instance for \"{Title}\"?", "Remove instance");
            if (result != MessageBoxResult.Yes) return;

            Context.RunMode = SetupRunMode.Remove;
            Context.SelectedWebApp = _webAppInfo;
            Context.PrivateKey = _appConfigReader.PrivateKey();

            var setupRunner = _setupRunnerViewModel();
            _shell.ShowScreen(setupRunner);

            await setupRunner.Run();
        }

        public async void Resync()
        {
            var result = _messageBox.Confirm($"Are you sure to resync the paired instance for \"{Title}\"?", "Resync instance");
            if (result != MessageBoxResult.Yes) return;

            Context.RunMode = SetupRunMode.Resync;
            Context.SelectedWebApp = _webAppInfo;
            Context.PrivateKey = _appConfigReader.PrivateKey();
            Context.RemoteIntegrationServerUrl = ReadRemoteIntegrationServerUrl();

            var setupRunner = _setupRunnerViewModel();
            _shell.ShowScreen(setupRunner);

            await setupRunner.Run();
        }

        public void Upgrade()
        {
            var diffLocationPrompt = string.Empty;

            if (IsFromDifferentInstallationLocation(_webAppInfo.InstancePath))
            {
                diffLocationPrompt = $"When you upgrade this instance, the instance location will be changed to: \"{GetNewInstanceLocation(_webAppInfo.InstanceName)}\"\n\n";
            }

            var message = diffLocationPrompt + "Click Yes if you want to proceed with upgrading this instance:{0}\"{1}\"{2}{3}Otherwise, click No and no changes will be made.";
            var result = _messageBox.Confirm(string.Format(message, Environment.NewLine, Title, Environment.NewLine, Environment.NewLine), "Upgrade instance");
            if (result != MessageBoxResult.Yes) return;

            Context.RunMode = SetupRunMode.Upgrade;
            Context.SelectedWebApp = _webAppInfo;
            Context.StorageLocation = ReadStorageLocation();
            Context.SetAuthMode(ReadAuthenticationModeForUpgrade());
            Context.Set2FAMode(ReadAuthentication2FaModeFromApps());
            Context.PrivateKey = _appConfigReader.PrivateKey();
            Context.IntegrationServerPort = ReadIntegrationServerPort();
            Context.RemoteIntegrationServerUrl = ReadRemoteIntegrationServerUrl();

            _shell.ShowScreen(_settingViewModel());
        }

        public async void Resume()
        {
            Context.RunMode = SetupRunMode.Resume;
            Context.SelectedWebApp = _webAppInfo;
            Context.PrivateKey = _appConfigReader.PrivateKey();

            var setupRunner = _setupRunnerViewModel();
            _shell.ShowScreen(setupRunner);

            await setupRunner.Run();
        }

        public void Settings()
        {
            Context.RunMode = SetupRunMode.Update;
            Context.SelectedWebApp = _webAppInfo;
            Context.StorageLocation = ReadStorageLocation();
            Context.SetAuthMode(ReadAuthenticationModeFromApps());
            Context.Set2FAMode(ReadAuthentication2FaModeFromApps());
            Context.PrivateKey = _appConfigReader.PrivateKey();
            Context.IntegrationServerPort = ReadIntegrationServerPort();
            Context.RemoteIntegrationServerUrl = ReadRemoteIntegrationServerUrl();

            _shell.ShowScreen(_settingViewModel());
        }

        public void ToggleDisplay(WebAppConfigurationViewModel viewModel)
        {
            viewModel.DisplayConnectionString = !viewModel.DisplayConnectionString;
        }

        string ReadStorageLocation()
        {
            var appSettings = InstanceConfiguration.AppSettings("Inprotech Server");

            var storageLocation = appSettings?.FirstOrDefault(_ => _.Key == "StorageLocation").Value;
            return storageLocation;
        }

        string ReadIntegrationServerPort()
        {
            var appSettings = InstanceConfiguration.AppSettings("Inprotech Integration Server");

            var integrationServerPort = appSettings?.FirstOrDefault(_ => _.Key == "Port").Value;
            return integrationServerPort;
        }

        Uri ReadRemoteIntegrationServerUrl()
        {
            var appSettings = InstanceConfiguration.AppSettings("Inprotech Server");

            var integrationServerBaseUrl = appSettings?.FirstOrDefault(_ => _.Key == "IntegrationServerBaseUrl").Value;

            if (Uri.TryCreate(integrationServerBaseUrl?.TrimEnd('/'), UriKind.Absolute, out Uri configuredUrl) && configuredUrl.Host != "localhost")
            {
                return configuredUrl;
            }

            return null;
        }

        string ReadAuthenticationModeFromApps()
        {
            var appSettings = InstanceConfiguration.AppSettings("Inprotech Server");

            return appSettings?.FirstOrDefault(_ => _.Key == "AuthenticationMode").Value ?? Constants.AuthenticationModeKeys.Forms;
        }

        string ReadAuthentication2FaModeFromApps()
        {
            var appSettings = InstanceConfiguration.AppSettings("Inprotech Server");

            return appSettings?.FirstOrDefault(_ => _.Key == "Authentication2FAMode").Value ?? string.Empty;
        }

        string ReadAuthenticationModeForUpgrade()
        {
            var appSettings = InstanceConfiguration.AppSettings("Inprotech Server");
            var inprotechLinkedToAppsNow = appSettings?.FirstOrDefault(_ => _.Key == "InprotechVersion").Value;
            var version = Context.SelectedWebApp.PairedIisAppInfo.Version;
            return _versionManager.IsAuthModeSetFromApps(version) && !string.IsNullOrEmpty(inprotechLinkedToAppsNow)
                ? ReadAuthenticationModeFromApps()
                : Context.SelectedWebApp.PairedIisAppInfo.GetAuthenticationMode();
        }

        static bool IsFromDifferentInstallationLocation(string fullPath)
        {
            var currentLocation = Path.GetDirectoryName(Assembly.GetEntryAssembly().Location);

            if (currentLocation == null)
                return true;

            return !fullPath.StartsWith(currentLocation, StringComparison.OrdinalIgnoreCase);
        }

        static string GetNewInstanceLocation(string instanceName)
        {
            var currentLocation = Path.GetDirectoryName(Assembly.GetEntryAssembly().Location);

            return Path.Combine(currentLocation ?? string.Empty, Constants.DefaultRootPath, instanceName);
        }
    }
}