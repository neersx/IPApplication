using System;
using System.Globalization;
using System.Windows.Data;
using System.Windows.Media;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.UI
{
    public class EventTypeColorConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            switch ((EventType)value)
            {
                case EventType.Information:
                    return new SolidColorBrush(Color.FromRgb(0xab, 0xba, 0xc3));
                case EventType.Warning:
                    return new SolidColorBrush(Color.FromRgb(0xff, 0xb7, 0x52));
                case EventType.Error:
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
