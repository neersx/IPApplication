using System.ComponentModel;
using System.Runtime.CompilerServices;
using Inprotech.Setup.Core.Annotations;

namespace Inprotech.Setup.Core
{
    public class CookieConsentSettings : INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler PropertyChanged;

        [NotifyPropertyChangedInvocator]
        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }

        string _cookieConsentBannerHook;
        string _cookieDeclarationHook;
        string _cookieConsentVerificationHook;
        string _cookieResetConsentHook;
        string _preferenceConsentVerificationHook;
        string _statisticsConsentVerificationHook;
        public string CookieConsentBannerHook
        {
            get => _cookieConsentBannerHook;
            set
            {
                if (string.Equals(_cookieConsentBannerHook, value)) return;

                _cookieConsentBannerHook = value;
                OnPropertyChanged(nameof(CookieConsentBannerHook));
            }
        }

        public string CookieDeclarationHook
        {
            get => _cookieDeclarationHook;
            set
            {
                if (string.Equals(_cookieDeclarationHook, value)) return;

                _cookieDeclarationHook = value;
                OnPropertyChanged(nameof(CookieDeclarationHook));
            }
        }

        public string CookieResetConsentHook
        {
            get => _cookieResetConsentHook;
            set
            {
                if (string.Equals(_cookieResetConsentHook, value)) return;

                _cookieResetConsentHook = value;
                OnPropertyChanged(nameof(CookieResetConsentHook));
            }
        }

        public string CookieConsentVerificationHook
        {
            get => _cookieConsentVerificationHook;
            set
            {
                if (string.Equals(_cookieConsentVerificationHook, value)) return;

                _cookieConsentVerificationHook = value;
                OnPropertyChanged(nameof(CookieConsentVerificationHook));
            }
        }

        public string PreferenceConsentVerificationHook
        {
            get => _preferenceConsentVerificationHook;
            set
            {
                if (string.Equals(_preferenceConsentVerificationHook, value)) return;

                _preferenceConsentVerificationHook = value;
                OnPropertyChanged(nameof(PreferenceConsentVerificationHook));
            }
        }

        public string StatisticsConsentVerificationHook
        {
            get => _statisticsConsentVerificationHook;
            set
            {
                if (string.Equals(_statisticsConsentVerificationHook, value)) return;

                _statisticsConsentVerificationHook = value;
                OnPropertyChanged(nameof(StatisticsConsentVerificationHook));
            }
        }

        public void Reset()
        {
            CookieConsentBannerHook = null;
            CookieDeclarationHook = null;
            CookieResetConsentHook = null;
            CookieConsentVerificationHook = null;
            PreferenceConsentVerificationHook = null;
            StatisticsConsentVerificationHook = null;
        }
    }
}