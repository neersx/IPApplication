using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Threading.Tasks;
using Caliburn.Micro;
using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Utilities;
using Newtonsoft.Json;
using NLog;
using LogManager = NLog.LogManager;

namespace Inprotech.Setup.Pages
{
    public class IpPlatformSettingsViewModel : Screen, INotifyDataErrorInfo
    {
        static readonly Logger Logger = LogManager.GetCurrentClassLogger();

        readonly IConfigurationSettingsReader _configurationSettingsReader;
        readonly IpPlatformSettings _ipPlatformSettings = new IpPlatformSettings();
        IpPlatformAllSettings _ipPlatformAllSettings;
        readonly Dictionary<string, ICollection<string>> _validationErrors = new Dictionary<string, ICollection<string>>();
        public event EventHandler<DataErrorsChangedEventArgs> ErrorsChanged;

        string _status = string.Empty;

        static class StatusValue
        {
            public const string Initialising = "Initialising ...";
            public const string TestInProgress = "Validating the details. This may take a few minutes...";
            public const string None = "";
        }

        static readonly Dictionary<string, string> TesterErrors = new Dictionary<string, string>
        {
            {"required", "This is a required field"},
            {"error-token-generation", "Failed to connect to The IP Platform with the provided details."},
            {"error-user-search", "Connection with The IP Platform is successful. However, Identity Access Management (IAM) access is not successful."},
            {"unknown", "Error occurred while testing connectivity to The IP Platform."}
        };

        public IpPlatformSettingsViewModel(IConfigurationSettingsReader configurationSettingsReader)
        {
            _configurationSettingsReader = configurationSettingsReader;
        }

        protected override async void OnInitialize()
        {
            base.OnInitialize();

            await Task.Run(GetIpPlatformSettingsSettings);
        }

        async Task GetIpPlatformSettingsSettings()
        {
            Status = StatusValue.Initialising;

            _ipPlatformAllSettings = await _configurationSettingsReader.GetIpPlatformSettings();

            if (!string.IsNullOrWhiteSpace(Context.AuthenticationSettings.IpPlatformSettings?.ClientId))
            {
                ClientId = Context.AuthenticationSettings.IpPlatformSettings.ClientId;
                ClientSecret = Context.AuthenticationSettings.IpPlatformSettings.ClientSecret;
            }
            else
            {
                ClientId = _ipPlatformAllSettings.PersistedSettings?.ClientId;
                ClientSecret = _ipPlatformAllSettings.PersistedSettings?.ClientSecret;
            }

            Status = StatusValue.None;
        }

        public string IpPlatformSettings { get; set; }

        public string ClientId
        {
            get => _ipPlatformSettings.ClientId;
            set
            {
                _ipPlatformSettings.ClientId = value;
                SetErrors(nameof(IpPlatformSettings), null);
                SetErrors(nameof(ClientId), null);
                NotifyOfPropertyChange(() => ClientId);
            }
        }

        public string ClientSecret
        {
            get => _ipPlatformSettings.ClientSecret;
            set
            {
                _ipPlatformSettings.ClientSecret = value;
                SetErrors(nameof(IpPlatformSettings), null);
                SetErrors(nameof(ClientSecret), null);
                NotifyOfPropertyChange(() => ClientSecret);
            }
        }

        public string Status
        {
            get => _status;
            set
            {
                _status = value;
                NotifyOfPropertyChange(()=> Status);
            }
        }

        public IEnumerable GetErrors(string propertyName)
        {
            if (string.IsNullOrEmpty(propertyName)
                || !_validationErrors.ContainsKey(propertyName))
                return null;

            return _validationErrors[propertyName];
        }

        public bool HasErrors => _validationErrors.Count > 0;

        public bool Validate()
        {
            if (string.IsNullOrWhiteSpace(ClientId))
            {
                SetErrors(nameof(ClientId), new List<string> {TesterErrors["required"]});
                return false;
            }

            if (string.IsNullOrWhiteSpace(ClientSecret))
            {
                SetErrors(nameof(ClientSecret), new List<string> {TesterErrors["required"]});
                return false;
            }

            return true;
        }

        async Task TryConnect()
        {
            Status = StatusValue.TestInProgress;

            var settings = _ipPlatformAllSettings.ConfigSettings;

            settings[Constants.IpPlatformSettings.ClientId] = ClientId;
            settings[Constants.IpPlatformSettings.ClientSecret] = ClientSecret;

            var result = await CommandLineUtility.RunAsync(Constants.IpPlatformSettings.TesterUtilityPath,
                                                           CommandLineUtility.EncodeArgument(JsonConvert.SerializeObject(settings)));

            if (result.ExitCode == -1)
            {
                ICollection<string> errors = new List<string>();

                var output = result.Output?.Trim();
                if (!string.IsNullOrWhiteSpace(output) && TesterErrors.ContainsKey(output))
                {
                    errors.Add(TesterErrors[output]);
                }
                else
                {
                    errors.Add(TesterErrors["unknown"]);
                }

                SetErrors(nameof(IpPlatformSettings), errors);
                Logger.Error(result.Error);
            }

            Status = StatusValue.None;
        }

        void SetErrors(string propertyName, ICollection<string> errors)
        {
            if (errors == null || errors.Count == 0)
            {
                if (!_validationErrors.ContainsKey(propertyName))
                    return;

                _validationErrors.Remove(propertyName);
                RaiseErrorsChanged(propertyName);
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
            if (!Validate())
            {
                callback(false);
                return;
            }
            SetErrors(nameof(IpPlatformSettings), null);

            var testConnectTask = Task.Run(async () => await TryConnect());
            
            testConnectTask.ContinueWith(task =>
                                         {
                                             if (((INotifyDataErrorInfo)this).HasErrors)
                                             {
                                                 callback(false);
                                                 return;
                                             }

                                             callback(true);
                                         });
        }

        protected override void OnDeactivate(bool close)
        {
            Context.AuthenticationSettings.IpPlatformSettings = _ipPlatformSettings;
        }
    }
}