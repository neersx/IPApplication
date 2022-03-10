using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Input;

namespace Inprotech.Setup.Pages
{
    public partial class IntegrationServerHttpIdentity : Window
    {
        public IntegrationServerHttpIdentity(IntegrationServerHttpIdentityViewModel viewModel)
        {
            InitializeComponent();

            Owner = Application.Current.MainWindow;
            DataContext = viewModel;

            Height = viewModel.IsMultiNode ? 500 : 250;
        }

        void NumberValidationTextBox(object sender, TextCompositionEventArgs e)
        {
            var regex = new Regex("[^0-9]+");
            e.Handled = regex.IsMatch(e.Text);
        }

        async void OkButton_OnClick(object sender, RoutedEventArgs e)
        {
            if (await ((IntegrationServerHttpIdentityViewModel) DataContext).CanProceed())
                DialogResult = true;
        }

        void CancelButton_OnClick(object sender, RoutedEventArgs e)
        {
            DialogResult = false;
        }

        void NextAvailable_OnClick(object sender, RoutedEventArgs e)
        {
            ((IntegrationServerHttpIdentityViewModel)DataContext).NextAvailable();
        }

        async void TestConnectivity_Click(object sender, RoutedEventArgs e)
        {
            await ((IntegrationServerHttpIdentityViewModel)DataContext).Validate();
        }
    }
}