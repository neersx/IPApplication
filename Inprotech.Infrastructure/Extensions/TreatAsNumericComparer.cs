using System;
using System.Collections.Generic;

namespace Inprotech.Infrastructure.Extensions
{
    public class NumericComparer : IComparer<object>
    {
        public int Compare(object s1, object s2)
        {
            if (IsNumeric(s1) && IsNumeric(s2))
            {
                if (Convert.ToInt32(s1) > Convert.ToInt32(s2)) return 1;
                if (Convert.ToInt32(s1) < Convert.ToInt32(s2)) return -1;
                if (Convert.ToInt32(s1) == Convert.ToInt32(s2)) return 0;
            }

            if (IsNumeric(s1) && !IsNumeric(s2))
                return -1;

            if (!IsNumeric(s1) && IsNumeric(s2))
                return 1;

            return String.Compare(s1?.ToString(), s2?.ToString(), StringComparison.OrdinalIgnoreCase);
        }

        public static bool IsNumeric(object value)
        {
            if (value == null) return false;

            try
            {
                int result;
                return Int32.TryParse(value.ToString(), out result);
            }
            catch (FormatException)
            {
                return false;
            }
        }
    }
}
