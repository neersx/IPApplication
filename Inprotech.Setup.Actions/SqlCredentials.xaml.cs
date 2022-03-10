using System;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media;

namespace Inprotech.Setup.Actions
{
    /// <summary>
    /// Interaction logic for SqlCredentials.xaml
    /// </summary>
    public partial class SqlCredentials : Window
    {
        readonly SqlAccessProber _probe;
        Brush _normalBorderBrush;

        public SqlCredentials(SqlAccessProber probe)
        {
            _probe = probe;

            InitializeComponent();
            Owner = Application.Current.MainWindow;

            DataContext = this;

            Loaded += SqlCredentials_Loaded;
        }

        void SqlCredentials_Loaded(object sender, RoutedEventArgs e)
        {
            SqlUser.Focus();
            _normalBorderBrush = PasswordBox.BorderBrush;
        }

        public bool CanTestConnection { get; set; }

        public bool IsConnectionValid { get; set; }

        public string SqlUserId { get; set; }

        public async void TestConnection()
        {
            RunningState();

            var watch = Stopwatch.StartNew();
            await Task.Run(
                           () =>
                           {
                               IsConnectionValid = _probe.CanAccess(SqlUserId, PasswordBox.Password);
                               if (watch.ElapsedMilliseconds < 1000)
                                   Thread.Sleep(TimeSpan.FromMilliseconds(1000 - watch.ElapsedMilliseconds));
                           });

            if (IsConnectionValid)
                DialogResult = true;
            else
                ErrorState();
        }

        void RunningState()
        {
            OkButton.IsEnabled = false;
            ErrorMsg.Visibility = Visibility.Collapsed;
            RunningMsg.Visibility = Visibility.Visible;
            SqlUser.BorderBrush = _normalBorderBrush;
            PasswordBox.BorderBrush = _normalBorderBrush;
        }

        void ErrorState()
        {
            OkButton.IsEnabled = true;
            ErrorMsg.Visibility = Visibility.Visible;
            RunningMsg.Visibility = Visibility.Collapsed;
            SqlUser.BorderBrush = new SolidColorBrush(Colors.IndianRed);
            PasswordBox.BorderBrush = new SolidColorBrush(Colors.IndianRed);
        }

        void OkButton_OnClick(object sender, RoutedEventArgs e)
        {
            TestConnection();
        }

        void CancelButton_OnClick(object sender, RoutedEventArgs e)
        {
            DialogResult = false;
        }
    }
}
