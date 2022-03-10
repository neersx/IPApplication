using System;
using Caliburn.Micro;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Pages
{
    public class IisAppDetailsViewModel : Screen
    {
        readonly IShell _shell;
        readonly Func<SettingsViewModel> _settingsConductor;
        readonly IAppConfigReader _appConfigReader;
        bool _displayConnectionString;
        
        public IisAppDetailsViewModel(IShell shell, Func<SettingsViewModel> settingsConductor, IAppConfigReader appConfigReader)
        {
            _shell = shell;
            _settingsConductor = settingsConductor;
            _appConfigReader = appConfigReader;
        }

        public IisAppInfo IisAppInfo => Context.SelectedIisApp;

        public bool DisplayAuthenticationInfo => !IisAppInfo.AuthModeToBeSetFromApps;

        public bool DisplaySmtpServer => !string.IsNullOrWhiteSpace(IisAppInfo.WebConfig.SmtpServer);

        public void ToggleDisplay()
        {
            DisplayConnectionString = !DisplayConnectionString;
        }

        public bool DisplayConnectionString
        {
            get => _displayConnectionString;
            set
            {
                _displayConnectionString = value;
                NotifyOfPropertyChange(() => DisplayConnectionString);
            }
        }

        public void Cancel()
        {
            _shell.ShowHome();
        }

        public void Next()
        {
            InitializeContextSettings();

            var next = _settingsConductor();
            _shell.ShowScreen(next);
        }

        public void InitializeContextSettings()
        {
            Context.AuthenticationSettings.AuthenticationMode = Context.SelectedIisApp?.GetAuthenticationMode();
            Context.PrivateKey = _appConfigReader.PrivateKey();
        }
    }
}