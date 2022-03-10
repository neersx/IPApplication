using System.Windows;

namespace Inprotech.Setup.Actions
{
    /// <summary>
    /// Interaction logic for SqlCredentialsWindowsOnlyAuthMode.xaml
    /// </summary>
    public partial class SqlCredentialsWindowsOnlyAuthMode : Window
    {
        public SqlCredentialsWindowsOnlyAuthMode()
        {
            InitializeComponent();

            Owner = Application.Current.MainWindow;
            DataContext = this;
        }

        void OkButton_OnClick(object sender, RoutedEventArgs e)
        {
            DialogResult = false;
        }
    }
}
