using System.Diagnostics;
using System.Windows.Controls;
using System.Windows.Navigation;

namespace Inprotech.Setup.Pages
{
    /// <summary>
    /// Interaction logic for AdfsSettingsView.xaml
    /// </summary>
    public partial class AdfsSettingsView : UserControl
    {
        public AdfsSettingsView()
        {
            InitializeComponent();
        }

        void OnlineGuide(object sender, RequestNavigateEventArgs e)
        {
            Process.Start(new ProcessStartInfo(e.Uri.AbsoluteUri));
            e.Handled = true;
        }
    }
}