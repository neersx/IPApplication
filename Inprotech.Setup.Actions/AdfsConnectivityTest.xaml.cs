using System;
using System.ComponentModel;
using System.Linq;
using System.Net;
using System.Runtime.CompilerServices;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Navigation;
using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Annotations;

namespace Inprotech.Setup.Actions
{
    /// <summary>
    /// Interaction logic for AdfsConnectivityTest.xaml
    /// </summary>
    public partial class AdfsConnectivityTest : INotifyPropertyChanged
    {
        readonly AdfsSettings _settings;
        bool _result;
        int _currentUrlIndex;
        public AdfsConnectivityTest(AdfsSettings settings)
        {
            _settings = settings;
            InitializeComponent();
            DataContext = this;
            Navigate();
            Owner = Application.Current.MainWindow;
            SecNextUrl = _timeToTestNextUrl;
            TotalUrls = _settings.ReturnUrls.Count;
        }

        void Navigate()
        {
            Browser.Navigate(SigninUrl);
        }

        Uri AdfsUrl => new Uri(_settings.ServerUrl);
        string RelyingPartyAddress => WebUtility.UrlEncode(_settings.RelyingPartyTrustId);
        Uri SigninUrl => new Uri(AdfsUrl, $"adfs/oauth2/authorize?response_type=code&resource={RelyingPartyAddress}&client_id={_settings.ClientId}&redirect_uri={WebUtility.UrlEncode(GetRedirectUrl() + "?redirectUrl=setup_test")}");

        void Browser_OnNavigating(object sender, NavigatingCancelEventArgs e)
        {
            Address.Text = e.Uri.ToString().Replace("?redirectUrl=setup_test", string.Empty);
        }

        void Browser_OnLoadCompleted(object sender, NavigationEventArgs e)
        {
            if (Address.Text.StartsWith(@"res://ieframe.dll/navcancl.htm#"))
            {
                SafeInvokeScript(() => Browser.InvokeScript("clickRefresh"));
            }
            if (e.Uri.ToString().StartsWith(CurrentUrl))
            {
                dynamic doc = Browser.Document;
                if (doc.documentElement.InnerText == "Adfs test is successfull")
                {
                    Browser.Visibility = Visibility.Collapsed;
                    _currentUrlIndex++;
                    if (UrlsPending)
                    {
                        TestingNextGrid.Visibility = Visibility.Visible;
                        NextReturnUrlTimer();
                        return;
                    }
                    SuccessGrid.Visibility = Visibility.Visible;
                    _result = true;
                    AutoCloseTimer();
                }
                else if (doc.documentElement.InnerText == "Token authorization failed. Make sure you are using a valid jwt certificate")
                {
                    Browser.Visibility = Visibility.Collapsed;
                    ErrorGrid.Visibility = Visibility.Visible;
                }
            }
        }

        void SafeInvokeScript(Action scriptFunc)
        {
            try
            {
                scriptFunc();
            }
            catch
            {
                // ignored
            }
        }

        public int Sec { get; set; } = 10;

        int _timeToTestNextUrl = 3;
        public int SecNextUrl { get; set; }

        void AdfsConnectivityTest_OnClosing(object sender, CancelEventArgs e)
        {
            DialogResult = _result;
        }

        void AutoCloseTimer()
        {
            Task.Run(() =>
            {
                while (Sec > 0)
                {
                    Sec--;
                    NotifyPropertyChanged(nameof(Sec));
                    Thread.Sleep(1000);
                }
                Dispatcher.Invoke(Close);
            });
        }

        void NextReturnUrlTimer()
        {
            Task.Run(() =>
            {
                while (SecNextUrl > 0)
                {
                    SecNextUrl--;
                    NotifyPropertyChanged(nameof(SecNextUrl));
                    Thread.Sleep(1000);
                }
                SecNextUrl = _timeToTestNextUrl;
                Dispatcher.Invoke(() =>
                {
                    Browser.Visibility = Visibility.Visible;
                    TestingNextGrid.Visibility = Visibility.Collapsed;
                    Navigate();
                    NotifyPropertyChanged(nameof(CurrentUrlIndex));
                    NotifyPropertyChanged(nameof(CurrentUrl));
                });
            });
        }

        string GetRedirectUrl()
        {
            return _settings.ReturnUrls.Values.ToArray()[_currentUrlIndex];
        }

        bool UrlsPending => _currentUrlIndex < _settings.ReturnUrls.Count;

        public event PropertyChangedEventHandler PropertyChanged;

        [NotifyPropertyChangedInvocator]
        protected virtual void NotifyPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }

        public int CurrentUrlIndex => _currentUrlIndex + 1;

        public int TotalUrls { get; }

        public string CurrentUrl => GetRedirectUrl();
    }
}