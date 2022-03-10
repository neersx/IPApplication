using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using Inprotech.Setup.Core.Annotations;

namespace Inprotech.Setup.Core
{
    public class AuthenticationSettings : INotifyPropertyChanged
    {
        string _authenticationMode;
        public string AuthenticationMode
        {
            get => _authenticationMode;
            set
            {
                if(string.Equals(_authenticationMode , value))
                    return;
                
                _authenticationMode = value;
                OnPropertyChanged(nameof(AuthenticationMode));
            }
        }

        string _2FAMode;
        public string TwoFactorAuthenticationMode
        {
            get => _2FAMode;
            set
            {
                if(string.Equals(_2FAMode , value))
                    return;
                
                _2FAMode = value;
                OnPropertyChanged(nameof(TwoFactorAuthenticationMode));
            }
        }

        public IpPlatformSettings IpPlatformSettings { get; set; }

        public AdfsSettings AdfsSettings { get; set; }

        public void Reset()
        {
            AuthenticationMode = null;
            TwoFactorAuthenticationMode = null;
            IpPlatformSettings = null;
            AdfsSettings = null;
        }

        public event PropertyChangedEventHandler PropertyChanged;
        [NotifyPropertyChangedInvocator]
        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    public class IpPlatformSettings
    {
        public IpPlatformSettings(string clientId = null, string clientSecret = null)
        {
            ClientId = clientId;
            ClientSecret = clientSecret;
        }

        public string ClientId { get; set; }

        public string ClientSecret { get; set; }
    }

    public class AdfsSettings
    {
        public AdfsSettings()
        {
            ReturnUrls = new Dictionary<string, string>();
        }
        public string ServerUrl { get; set; }
        public string ClientId { get; set; }
        public string RelyingPartyTrustId { get; set; }
        public string Certificate { get; set; }

        public Dictionary<string, string> ReturnUrls { get; set; }
    }
}
