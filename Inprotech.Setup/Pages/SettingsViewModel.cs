using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Caliburn.Micro;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Pages
{
    public enum ScreenType
    {
        Basic = 0,
        CookieConsent = 1,
        AuthMode = 2,
        Adfs = 3,
        Sso = 4,
        ProductImprovement = 5
    }

    public class SettingsViewModel : Conductor<object>.Collection.OneActive
    {
        readonly IShell _shell;
        readonly IIndex<ScreenType, Screen> _settingScreens;
        readonly Func<SetupRunnerViewModel> _setupRunnerViewFunc;
        readonly List<ScreenType> _settingScreensSequence;
        ScreenType _currentScreenType;
        Screen _currentScreen;
        bool _isNavigationInProgress;

        public SettingsViewModel(IShell shell, IIndex<ScreenType, Screen> settingScreens, Func<SetupRunnerViewModel> setupRunnerViewFunc)
        {
            _shell = shell;
            _settingScreens = settingScreens;
            _setupRunnerViewFunc = setupRunnerViewFunc;

            _settingScreensSequence = new List<ScreenType>();
        }

        protected override void OnActivate()
        {
            base.OnActivate();

            InitializeScreenSequence();
            DisplayScreen(ScreenType.Basic);
        }

        public ScreenType CurrentScreenType
        {
            set
            {
                _currentScreenType = value;
                NotifyOfPropertyChange(() => PrevVisible);
            }
            get => _currentScreenType;
        }

        public bool IsNavigationInProgress
        {
            get => _isNavigationInProgress;
            set
            {
                _isNavigationInProgress = value;
                NotifyOfPropertyChange(() => IsNavEnabled);
            }
        }

        public void Cancel()
        {
            _shell.ShowHome();
        }

        public string NextButtonText
        {
            get
            {
                if (IsLastSettingItem())
                {
                    return Context.RunMode == SetupRunMode.New ? "Install" : "Update";
                }
                return "Next";
            }
        }

        public bool IsNavEnabled => !_isNavigationInProgress;

        public bool PrevVisible => _settingScreensSequence.IndexOf(CurrentScreenType) != 0;

        public void Prev()
        {
            if (TryGetPrevItem(out ScreenType prevScreenType))
            {
                DisplayScreen(prevScreenType);
            }
        }

        public void Next()
        {
            IsNavigationInProgress = true;
            _currentScreen.CanClose(IsValid);
        }

        public void IsValid(bool result)
        {
            try
            {
                if (!result) return;

                DeactivateItem(_currentScreen, true);

                if (TryGetNextItem(out ScreenType nextScreenType))
                {
                    DisplayScreen(nextScreenType);
                    return;
                }

                Task.Run(async () => await ProceedWithInstallation());
            }
            finally
            {
                IsNavigationInProgress = false;
            }
        }

        public async Task ProceedWithInstallation()
        {
            var runner = _setupRunnerViewFunc();

            _shell.ShowScreen(runner);
            await runner.Run();
        }

        void DisplayScreen(ScreenType screenType)
        {
            CurrentScreenType = screenType;
            _currentScreen = _settingScreens[CurrentScreenType];
            NotifyOfPropertyChange(() => NextButtonText);
            ActivateItem(_currentScreen);
        }

        bool TryGetNextItem(out ScreenType nextScreenType)
        {
            nextScreenType = CurrentScreenType;
            var nextIndex = _settingScreensSequence.IndexOf(CurrentScreenType) + 1;
            if (nextIndex >= _settingScreensSequence.Count)
            {
                return false;
            }
            nextScreenType = _settingScreensSequence[nextIndex];
            return true;
        }

        bool IsLastSettingItem()
        {
            var nextIndex = _settingScreensSequence.IndexOf(CurrentScreenType) + 1;
            return nextIndex >= _settingScreensSequence.Count;
        }

        bool TryGetPrevItem(out ScreenType prevScreenType)
        {
            prevScreenType = CurrentScreenType;
            var prevIndex = _settingScreensSequence.IndexOf(CurrentScreenType) - 1;
            if (prevIndex < 0)
            {
                return false;
            }

            prevScreenType = _settingScreensSequence[prevIndex];
            return true;
        }

        void InitializeScreenSequence()
        {
            _settingScreensSequence.Add(ScreenType.Basic);
            if (Context.ResolvedIisApp.AuthModeToBeSetFromApps)
            {
                _settingScreensSequence.Add(ScreenType.CookieConsent);
            }

            _settingScreensSequence.Add(ScreenType.ProductImprovement);
            
            if (Context.ResolvedIisApp.AuthModeToBeSetFromApps)
            {
                _settingScreensSequence.Add(ScreenType.AuthMode);
                Context.AuthenticationSettings.PropertyChanged += AuthenticationSettings_PropertyChanged;
                SetScreensForAuthRelatedSettings();
            }
        }

        void AuthenticationSettings_PropertyChanged(object sender, System.ComponentModel.PropertyChangedEventArgs e)
        {
            SetScreensForAuthRelatedSettings();
        }

        void SetScreensForAuthRelatedSettings()
        {
            if (Context.AuthenticationSettings == null || string.IsNullOrWhiteSpace(Context.AuthenticationSettings.AuthenticationMode))
                return;

            InsertOrRemoveScreen(Constants.AuthenticationModeKeys.Adfs, ScreenType.Adfs);
            InsertOrRemoveScreen(Constants.AuthenticationModeKeys.Sso, ScreenType.Sso);
        }

        void InsertOrRemoveScreen(string authMode, ScreenType screenType)
        {
            if (Context.AuthenticationSettings.AuthenticationMode.Contains(authMode))
            {
                InsertScreen(screenType);
            }
            else
            {
                RemoveScreen(screenType);
            }
        }

        void InsertScreen(ScreenType screenType)
        {
            if (_settingScreensSequence.Contains(screenType))
                return;

            var screenBefore = _settingScreensSequence.Where(_ => (int)_ < (int)screenType).Max(_ => _);
            _settingScreensSequence.Insert(_settingScreensSequence.IndexOf(screenBefore) + 1, screenType);
            NotifyOfPropertyChange(() => NextButtonText);
        }

        void RemoveScreen(ScreenType screenType)
        {
            _settingScreensSequence.Remove(screenType);
            NotifyOfPropertyChange(() => NextButtonText);
        }

        public override void CanClose(Action<bool> callback)
        {
            callback(true);
        }
    }
}