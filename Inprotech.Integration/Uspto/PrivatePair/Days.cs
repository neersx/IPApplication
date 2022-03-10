using System;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Integration.Uspto.PrivatePair
{
    public static class Days
    {
        static readonly Dictionary<string, DayOfWeek> String2DayOfWeekMap =
            new Dictionary<string, DayOfWeek>(StringComparer.InvariantCultureIgnoreCase)
            {
                {"mon", DayOfWeek.Monday},
                {"tue", DayOfWeek.Tuesday},
                {"wed", DayOfWeek.Wednesday},
                {"thu", DayOfWeek.Thursday},
                {"fri", DayOfWeek.Friday},
                {"sat", DayOfWeek.Saturday},
                {"sun", DayOfWeek.Sunday},
            };

        public static DayOfWeek[] ConvertToDaysOfWeek(this string days)
        {
            return days
                   .Split(new[] {','}, StringSplitOptions.RemoveEmptyEntries)
                   .Select(s => String2DayOfWeekMap[s.Trim()])
                   .ToArray();
        }
    }
}