using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Security.Cryptography.X509Certificates;
using System.Threading.Tasks;
using Caliburn.Micro;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Pages
{
    public class AdfsSettingsViewModel : Screen, INotifyDataErrorInfo
    {
        const string Required = "This is required field";
        readonly AdfsSettings _adfsSettings;
        readonly Dictionary<string, ICollection<string>> _validationErrors;
        readonly IAdfsConfigPersistence _adfsConfigPersistence;
        string _newReturnUrl;
        ObservableCollection<string> _returnUrls;

        public AdfsSettingsViewModel(Func<string, IAdfsConfigPersistence> adfsConfigPersistence)
        {
            _adfsSettings = new AdfsSettings();
            _validationErrors = new Dictionary<string, ICollection<string>>();
            var connectionString = Context.ResolvedIisApp.WebConfig.InprotechConnectionString;
            if (string.IsNullOrWhiteSpace(connectionString))
                throw new Exception("Connection string not defined");
            _adfsConfigPersistence = adfsConfigPersistence(connectionString);
        }

        public string ServerUrl
        {
            get => _adfsSettings.ServerUrl;
            set
            {
                _adfsSettings.ServerUrl = value;
                SetErrors(nameof(IpPlatformSettings), null);
                SetErrors(nameof(ServerUrl), null);
                NotifyOfPropertyChange(() => ServerUrl);
            }
        }

        public string ClientId
        {
            get => _adfsSettings.ClientId;
            set
            {
                _adfsSettings.ClientId = value;
                SetErrors(nameof(IpPlatformSettings), null);
                SetErrors(nameof(ClientId), null);
                NotifyOfPropertyChange(() => ClientId);
            }
        }

        public string RelyingPartyTrustId
        {
            get => _adfsSettings.RelyingPartyTrustId;
            set
            {
                _adfsSettings.RelyingPartyTrustId = value;
                SetErrors(nameof(IpPlatformSettings), null);
                SetErrors(nameof(RelyingPartyTrustId), null);
                NotifyOfPropertyChange(() => RelyingPartyTrustId);
            }
        }

        public string Certificate
        {
            get => _adfsSettings.Certificate;
            set
            {
                _adfsSettings.Certificate = value;
                if (!string.IsNullOrEmpty(value))
                    _adfsSettings.Certificate = _adfsSettings.Certificate.Replace("-----BEGIN CERTIFICATE-----", string.Empty).Replace("-----END CERTIFICATE-----", string.Empty).Trim();
                SetErrors(nameof(IpPlatformSettings), null);
                SetErrors(nameof(Certificate), null);
                NotifyOfPropertyChange(() => Certificate);
            }
        }

        public string NewReturnUrl
        {
            get => _newReturnUrl;
            set
            {
                _newReturnUrl = value;
                SetErrors(nameof(NewReturnUrl), null);
                NotifyOfPropertyChange(() => NewReturnUrl);
            }
        }

        public ObservableCollection<string> ReturnUrls
        {
            get => _returnUrls;
            private set
            {
                _returnUrls = value;
                NotifyOfPropertyChange(() => ReturnUrls);
            }
        }

        protected override async void OnInitialize()
        {
            base.OnInitialize();

            await Task.Run(GetAdfsSettings);
        }

        async Task GetAdfsSettings()
        {
            if (Context.AuthenticationSettings.AdfsSettings == null)
            {
                var adfsSettings = await _adfsConfigPersistence.GetAdfsSettings(Context.PrivateKey);

                SetAdfsSettings(adfsSettings);
            }
            else
            {
                SetAdfsSettings(Context.AuthenticationSettings.AdfsSettings);
            }
        }

        void SetAdfsSettings(AdfsSettings settings)
        {
            ServerUrl = settings.ServerUrl;
            ClientId = settings.ClientId;
            RelyingPartyTrustId = settings.RelyingPartyTrustId;
            Certificate = settings.Certificate;
            ReturnUrls = new ObservableCollection<string>(settings.ReturnUrls.Select(_ => _.Value));
        }

        public bool ValidateErrors()
        {
            Uri uriResult;

            if (string.IsNullOrWhiteSpace(ServerUrl))
                SetErrors(nameof(ServerUrl), new[] { Required });
            else if (!(Uri.TryCreate(ServerUrl, UriKind.Absolute, out uriResult) && uriResult.Scheme == Uri.UriSchemeHttps))
                SetErrors(nameof(ServerUrl), new[] { "The ADFS server URL should be a valid URL with https" });

            if (string.IsNullOrWhiteSpace(ClientId))
                SetErrors(nameof(ClientId), new[] { Required });

            if (string.IsNullOrWhiteSpace(RelyingPartyTrustId))
                SetErrors(nameof(RelyingPartyTrustId), new[] { Required });

            if (string.IsNullOrWhiteSpace(Certificate))
                SetErrors(nameof(Certificate), new[] { Required });
            else if (!IsCertificateParsed())
                SetErrors(nameof(Certificate), new[] { "The certificate parsing failed" });

            if (ReturnUrls?.Count == 0)
            {
                var error = new[] { Required };
                if (!string.IsNullOrEmpty(NewReturnUrl))
                    error = new[] { "Click the 'Add' button to register this URL" };
                SetErrors(nameof(NewReturnUrl), error);
            }
            else
            {
                SetErrors(nameof(NewReturnUrl), null);
            }

            return HasErrors;
        }

        bool IsCertificateParsed()
        {
            try
            {
                var unused = new X509Certificate2(Convert.FromBase64String(Certificate));
                return true;
            }
            catch
            {
                return false;
            }
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

        public IEnumerable GetErrors(string propertyName)
        {
            if (string.IsNullOrEmpty(propertyName)
                || !_validationErrors.ContainsKey(propertyName))
                return null;

            return _validationErrors[propertyName];
        }

        public void AddReturnUrl()
        {
            if (!ValidateNewReturnUrl())
                return;
            ReturnUrls.Insert(0, NewReturnUrl);
            NewReturnUrl = string.Empty;
            NotifyOfPropertyChange(() => ReturnUrls);
        }

        public void DeleteReturnUrl(object o)
        {
            var url = o.ToString();
            ReturnUrls.Remove(url);
            NewReturnUrl = url;
        }

        bool ValidateNewReturnUrl()
        {
            var status = true;
            Uri uriResult;
            if (string.IsNullOrWhiteSpace(NewReturnUrl))
            {
                status = false;
                SetErrors(nameof(NewReturnUrl), new[] { Required });
            }
            else if (!Uri.TryCreate(NewReturnUrl, UriKind.Absolute, out uriResult))
            {
                status = false;
                SetErrors(nameof(NewReturnUrl), new[] { "The return URL must be a valid URL" });
            }
            else if (ReturnUrls.Contains(NewReturnUrl))
            {
                status = false;
                SetErrors(nameof(NewReturnUrl), new[] { "The return URL is already added" });
            }
            else if (!NewReturnUrl.EndsWith("apps/api/signin/adfsreturn", StringComparison.InvariantCultureIgnoreCase) && !NewReturnUrl.EndsWith("apps/api/signin/adfsreturn/", StringComparison.InvariantCultureIgnoreCase))
            {
                status = false;
                SetErrors(nameof(NewReturnUrl), new[] { "The return URL does not point to correct Inprotech end point" });
            }
            return status;
        }
        void RaiseErrorsChanged(string propertyName)
        {
            ErrorsChanged?.Invoke(this, new DataErrorsChangedEventArgs(propertyName));
        }

        public bool HasErrors => _validationErrors.Count > 0;
        public event EventHandler<DataErrorsChangedEventArgs> ErrorsChanged;

        public override void CanClose(Action<bool> callback)
        {
            callback(!ValidateErrors());
        }

        protected override void OnDeactivate(bool close)
        {
            _adfsSettings.ReturnUrls = ReturnUrls.Select((v, k) => new { k, v }).ToDictionary(k => $"url-{k.k}", v => v.v);

            Context.AuthenticationSettings.AdfsSettings = _adfsSettings;
        }
    }
}