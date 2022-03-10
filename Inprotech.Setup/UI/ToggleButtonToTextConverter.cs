using System;
using System.Globalization;
using System.Windows.Data;

namespace Inprotech.Setup.UI
{
    public class ToggleButtonToTextConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return value != null && (bool) value ? "Click to hide" : "Click to show";
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
