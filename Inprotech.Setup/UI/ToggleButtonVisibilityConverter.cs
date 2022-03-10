using System;
using System.Globalization;
using System.Windows;
using System.Windows.Data;

namespace Inprotech.Setup.UI
{
    public class ToggleButtonVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            var settingsKey = value as string;
            return settingsKey == "ConnectionString" ? Visibility.Visible : Visibility.Hidden;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
