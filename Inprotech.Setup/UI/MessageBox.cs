using System.Windows;

namespace Inprotech.Setup.UI
{
    public interface IMessageBox
    {
        MessageBoxResult Confirm(string text, string caption);

        MessageBoxResult Alert(string text, string caption);
    }

    class MessageBox : IMessageBox
    {
        public MessageBoxResult Confirm(string text, string caption)
        {
            return System.Windows.MessageBox.Show(text, caption, MessageBoxButton.YesNo, MessageBoxImage.Information);
        }

        public MessageBoxResult Alert(string text, string caption)
        {
            return System.Windows.MessageBox.Show(text, caption, MessageBoxButton.OK, MessageBoxImage.Information);
        }
    }
}
