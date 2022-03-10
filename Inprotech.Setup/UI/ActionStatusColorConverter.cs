using System;
using System.Globalization;
using System.Windows.Data;
using System.Windows.Media;

namespace Inprotech.Setup.UI
{
    public class ActionStatusColorConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            switch((ActionStatus)value)
            {
                case ActionStatus.Ready:
                    return new SolidColorBrush(Color.FromRgb(0xab, 0xba, 0xc3));
                case ActionStatus.InProgress:
                    return new SolidColorBrush(Color.FromRgb(0x42, 0x8b, 0xca));
                case ActionStatus.Success:
                    return new SolidColorBrush(Color.FromRgb(0x87, 0xb8, 0x7f));
                case ActionStatus.Warning:
                    return new SolidColorBrush(Color.FromRgb(0xec, 0x97, 0x1f));
                case ActionStatus.Failed:
                    return new SolidColorBrush(Color.FromRgb(0xd1, 0x5b, 0x47));
            }

            throw new ArgumentOutOfRangeException("value");
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
