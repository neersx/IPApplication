using System;
using System.Collections.Generic;
using System.Globalization;
using System.Windows.Data;

namespace Inprotech.Setup.UI
{
    public class SettingsValueTextConverter : IValueConverter
    {
        const string ConnectionStringSettingName = "ConnectionString";

        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            var setting = (KeyValuePair<string, string>)value;

            if (parameter == null)
            {
                return setting.Key != ConnectionStringSettingName ? setting.Value : string.Empty;
            }
            
            var param = parameter as string;
            return setting.Key == ConnectionStringSettingName && param == ConnectionStringSettingName ? setting.Value : string.Empty;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
