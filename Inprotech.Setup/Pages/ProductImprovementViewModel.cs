using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Threading.Tasks;
using Caliburn.Micro;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Pages
{
    public class ProductImprovementViewModel : Screen, INotifyDataErrorInfo, ISettingsViewModel
    {
        readonly IInprotechServerPersistingConfigManager _inprotechServerPersistingConfigManager;

        readonly Dictionary<string, ICollection<string>> _validationErrors = new Dictionary<string, ICollection<string>>();

        public ProductImprovementViewModel(IInprotechServerPersistingConfigManager inprotechServerPersistingConfigManager)
        {
            _inprotechServerPersistingConfigManager = inprotechServerPersistingConfigManager;
        }

        public bool FirmUsageStatisticsConsented { get; set; }
        public bool IsCookieBannerConfigured { get; set; }
        public bool AuthModeToBeSetFromApps { get; set; }
        public bool UserUsageStatisticsConsented { get; set; }
        public event EventHandler<DataErrorsChangedEventArgs> ErrorsChanged;

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

        public void SetInstanceDetails(InstanceDetails instanceDetails)
        {
        }

        public void SetSetupSettings(Dictionary<string, string> settings)
        {
        }

        protected override async void OnInitialize()
        {
            base.OnInitialize();

            await Task.Run(GetProductImprovementSettings);
        }

        async Task GetProductImprovementSettings()
        {
            var connectionString = Context.ResolvedIisApp.WebConfig.InprotechConnectionString;

            var persistedConfig = await _inprotechServerPersistingConfigManager.GetProductImprovement(connectionString);
            if (Context.UsageStatisticsSettings.FirmUsageStatisticsConsented.HasValue)
            {
                FirmUsageStatisticsConsented = Context.UsageStatisticsSettings.FirmUsageStatisticsConsented.Value;
            }
            else
            {
                FirmUsageStatisticsConsented = persistedConfig.FirmUsageStatisticsConsented ?? false;
            }
            NotifyOfPropertyChange(() => FirmUsageStatisticsConsented);

            if (Context.UsageStatisticsSettings.UserUsageStatisticsConsented.HasValue)
            {
                UserUsageStatisticsConsented = Context.UsageStatisticsSettings.UserUsageStatisticsConsented.Value;
            }
            else
            {
                UserUsageStatisticsConsented = persistedConfig.UserUsageStatisticsConsented ?? false;
            }
            NotifyOfPropertyChange(() => UserUsageStatisticsConsented);

            IsCookieBannerConfigured = !string.IsNullOrWhiteSpace(Context.CookieConsentSettings?.CookieConsentBannerHook);
            AuthModeToBeSetFromApps = Context.ResolvedIisApp.AuthModeToBeSetFromApps;

            if (!IsCookieBannerConfigured)
            {
                UserUsageStatisticsConsented = false;
                NotifyOfPropertyChange(() => UserUsageStatisticsConsented);
            }

            NotifyOfPropertyChange(() => IsCookieBannerConfigured);
            NotifyOfPropertyChange(() => AuthModeToBeSetFromApps);
        }

        protected override void OnDeactivate(bool close)
        {
            base.OnDeactivate(close);

            Context.UsageStatisticsSettings.FirmUsageStatisticsConsented = FirmUsageStatisticsConsented;
            Context.UsageStatisticsSettings.UserUsageStatisticsConsented = UserUsageStatisticsConsented;
        }

        void Validate()
        {
            ClearErrors();
        }

        void ClearErrors()
        {
            SetErrors(nameof(FirmUsageStatisticsConsented), null);
            SetErrors(nameof(UserUsageStatisticsConsented), null);
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
#pragma warning disable SA1132 // Do not combine fields
#pragma warning restore SA1132 // Do not combine fields
    }
}