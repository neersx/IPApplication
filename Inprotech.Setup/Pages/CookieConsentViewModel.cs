using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Threading.Tasks;
using Caliburn.Micro;
using Inprotech.Setup.Core;
using Nito.AsyncEx;

namespace Inprotech.Setup.Pages
{
    public class CookieConsentViewModel : Screen, INotifyDataErrorInfo, ISettingsViewModel
    {
#pragma warning disable SA1132 // Do not combine fields
        readonly bool _isBannerSet, _isDeclarationSet, _isResetCookieSet, _isConsentVerificationSet, _isPreferenceConsentVerificationSet, _isStatisticsConsentVerificationSet;
#pragma warning restore SA1132 // Do not combine fields

        readonly Dictionary<string, ICollection<string>> _validationErrors = new Dictionary<string, ICollection<string>>();

        public CookieConsentViewModel()
        {
            if (CookieConsentBannerHook != Context.CookieConsentSettings.CookieConsentBannerHook)
            {
                CookieConsentBannerHook = Context.CookieConsentSettings.CookieConsentBannerHook;
                _isBannerSet = true;
            }

            if (CookieDeclarationHook != Context.CookieConsentSettings.CookieDeclarationHook)
            {
                CookieDeclarationHook = Context.CookieConsentSettings.CookieDeclarationHook;
                _isDeclarationSet = true;
            }

            if (CookieConsentVerificationHook != Context.CookieConsentSettings.CookieConsentVerificationHook)
            {
                CookieConsentVerificationHook = Context.CookieConsentSettings.CookieConsentVerificationHook;
                _isResetCookieSet = true;
            }

            if (CookieResetConsentHook != Context.CookieConsentSettings.CookieResetConsentHook)
            {
                CookieResetConsentHook = Context.CookieConsentSettings.CookieResetConsentHook;
                _isConsentVerificationSet = true;
            }

            if (PreferenceConsentVerificationHook != Context.CookieConsentSettings.PreferenceConsentVerificationHook)
            {
                PreferenceConsentVerificationHook = Context.CookieConsentSettings.PreferenceConsentVerificationHook;
                _isPreferenceConsentVerificationSet = true;
            }
            if (StatisticsConsentVerificationHook != Context.CookieConsentSettings.StatisticsConsentVerificationHook)
            {
                StatisticsConsentVerificationHook = Context.CookieConsentSettings.StatisticsConsentVerificationHook;
                _isStatisticsConsentVerificationSet = true;
            }

            NotifyTaskCompletion.Create(PopulateInstances(this));
        }

        public bool HasErrors { get; }
        public event EventHandler<DataErrorsChangedEventArgs> ErrorsChanged;

        public string CookieConsentBannerHook { get; set; }
        public string CookieDeclarationHook { get; set; }
        public string CookieConsentVerificationHook { get; set; }
        public string CookieResetConsentHook { get; set; }
        public string PreferenceConsentVerificationHook { get; set; }
        public string StatisticsConsentVerificationHook { get; set; }

        protected override void OnDeactivate(bool close)
        {
            base.OnDeactivate(close);

            Context.CookieConsentSettings.CookieConsentBannerHook = CookieConsentBannerHook?.Trim();
            Context.CookieConsentSettings.CookieDeclarationHook = CookieDeclarationHook?.Trim();
            Context.CookieConsentSettings.CookieResetConsentHook = CookieResetConsentHook?.Trim();
            Context.CookieConsentSettings.CookieConsentVerificationHook = CookieConsentVerificationHook?.Trim();
            Context.CookieConsentSettings.PreferenceConsentVerificationHook = PreferenceConsentVerificationHook?.Trim();
            Context.CookieConsentSettings.StatisticsConsentVerificationHook = StatisticsConsentVerificationHook?.Trim();
        }

        void Validate()
        {
            ClearErrors();
            var cookieScriptRequired = "Cookie Script is Required for configuring rest of the cookie properties";
            var removeSemicolon = "Remove semicolon at the end of the script";

            if (string.IsNullOrEmpty(CookieConsentBannerHook) && (!string.IsNullOrEmpty(CookieDeclarationHook?.Trim())
                                                                  || !string.IsNullOrEmpty(CookieResetConsentHook?.Trim())
                                                                  || !string.IsNullOrEmpty(CookieConsentVerificationHook?.Trim())
                                                                  || !string.IsNullOrEmpty(PreferenceConsentVerificationHook?.Trim())
                                                                  || !string.IsNullOrEmpty(StatisticsConsentVerificationHook?.Trim())))
            {
                SetErrors(nameof(CookieConsentBannerHook), new[] { cookieScriptRequired });
            }

            if (!string.IsNullOrEmpty(CookieConsentVerificationHook) && CookieConsentVerificationHook.EndsWith(";"))
                SetErrors(nameof(CookieConsentVerificationHook), new[] { removeSemicolon });
            if (!string.IsNullOrEmpty(PreferenceConsentVerificationHook) && PreferenceConsentVerificationHook.EndsWith(";"))
                SetErrors(nameof(PreferenceConsentVerificationHook), new[] { removeSemicolon });
            if (!string.IsNullOrEmpty(StatisticsConsentVerificationHook) && StatisticsConsentVerificationHook.EndsWith(";"))
                SetErrors(nameof(StatisticsConsentVerificationHook), new[] { removeSemicolon });
        }

        void ClearErrors()
        {
            SetErrors(nameof(CookieConsentBannerHook), null);
            SetErrors(nameof(CookieConsentVerificationHook), null);
            SetErrors(nameof(PreferenceConsentVerificationHook), null);
            SetErrors(nameof(StatisticsConsentVerificationHook), null);
        }

        bool INotifyDataErrorInfo.HasErrors => _validationErrors.Count > 0;

        IEnumerable INotifyDataErrorInfo.GetErrors(string propertyName)
        {
            if (string.IsNullOrEmpty(propertyName)
                || !_validationErrors.ContainsKey(propertyName))
            {
                return null;
            }

            return _validationErrors[propertyName];
        }

        void SetErrors(string propertyName, ICollection<string> errors)
        {
            if (errors == null || errors.Count == 0)
            {
                if (_validationErrors.ContainsKey(propertyName))
                {
                    _validationErrors.Remove(propertyName);
                    RaiseErrorsChanged(propertyName);
                }
            }
            else
            {
                _validationErrors[propertyName] = errors;
                RaiseErrorsChanged(propertyName);
            }
        }

        void RaiseErrorsChanged(string propertyName)
        {
            ErrorsChanged?.Invoke(this, new DataErrorsChangedEventArgs(propertyName));
        }

        public override void CanClose(Action<bool> callback)
        {
            Validate();
            if (((INotifyDataErrorInfo)this).HasErrors)
            {
                callback(false);
                return;
            }

            callback(true);
        }

        public void SetInstanceDetails(InstanceDetails instanceDetails)
        {
        }

        static async Task PopulateInstances(ISettingsViewModel viewModel)
        {
            var connectionString = Context.ResolvedIisApp.WebConfig.InprotechConnectionString;

            var configManager = new InprotechServerPersistingConfigManager();

            viewModel.SetSetupSettings(await configManager.GetSetupDetails(connectionString));
        }

        public void SetSetupSettings(Dictionary<string, string> settings)
        {
            if (!_isBannerSet && settings.TryGetValue(Constants.InprotechServer.SetupConfiguration.CookieConsentBannerHook, out string cookieConsentHook))
            {
                CookieConsentBannerHook = cookieConsentHook;
                NotifyOfPropertyChange(() => CookieConsentBannerHook);
            }

            if (!_isDeclarationSet && settings.TryGetValue(Constants.InprotechServer.SetupConfiguration.CookieDeclarationHook, out string cookieDeclarationHook))
            {
                CookieDeclarationHook = cookieDeclarationHook;
                NotifyOfPropertyChange(() => CookieDeclarationHook);
            }

            if (!_isResetCookieSet && settings.TryGetValue(Constants.InprotechServer.SetupConfiguration.CookieResetConsentHook, out string resetCookieConsentHook))
            {
                CookieResetConsentHook = resetCookieConsentHook;
                NotifyOfPropertyChange(() => CookieResetConsentHook);
            }

            if (!_isConsentVerificationSet && settings.TryGetValue(Constants.InprotechServer.SetupConfiguration.CookieConsentVerificationHook, out string cookieConsentVerificationHook))
            {
                CookieConsentVerificationHook = cookieConsentVerificationHook;
                NotifyOfPropertyChange(() => CookieConsentVerificationHook);
            }

            if (!_isPreferenceConsentVerificationSet && settings.TryGetValue(Constants.InprotechServer.SetupConfiguration.PreferenceConsentVerificationHook, out string preferenceConsentVerificationHook))
            {
                PreferenceConsentVerificationHook = preferenceConsentVerificationHook;
                NotifyOfPropertyChange(() => PreferenceConsentVerificationHook);
            }

            if (!_isStatisticsConsentVerificationSet && settings.TryGetValue(Constants.InprotechServer.SetupConfiguration.StatisticsConsentVerificationHook, out string statisticsConsentVerificationHook))
            {
                StatisticsConsentVerificationHook = statisticsConsentVerificationHook;
                NotifyOfPropertyChange(() => StatisticsConsentVerificationHook);
            }
        }

    }
}