using System;
using Inprotech.Contracts;

namespace Inprotech.Infrastructure.DateTimeHelpers
{
    public class TimeZoneService : ITimeZoneService
    {
        public bool TryConvertTimeFromUtc(DateTime dateTime, string timeZoneId, out DateTime output)
        {
            output = dateTime;

            try
            {
                var timeZoneInfo = TimeZoneInfo.FindSystemTimeZoneById(timeZoneId);
                output = TimeZoneInfo.ConvertTimeFromUtc(dateTime, timeZoneInfo);
                return true;
            }
            catch
            {
                // handling timeZoneInfo not found or missing 
                // due to underlying system configuration and or windows update changes.
            }

            return false;
        }
    }
}
