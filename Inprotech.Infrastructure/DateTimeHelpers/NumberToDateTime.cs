using System;

namespace Inprotech.Infrastructure.DateTimeHelpers
{
    public class NumberToDateTime
    {
        public static DateTime? Convert(int? totalTime)
        {
            if (totalTime != null && totalTime != 0)
            {
                var hours = (int) totalTime / 60;
                var minutes = (int) totalTime % 60;

                return new DateTime(1899, 1, 1, hours, minutes, 0);
            }

            return null;
        }
    }
}
