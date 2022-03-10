using System;
using System.Linq;
using Inprotech.Contracts;

namespace Inprotech.Integration.DataSources
{
     public interface IAvailabilityCalculator
    {
        bool TryCalculateTimeToAvailability(TimeSpan startTime, TimeSpan endTime,
            DayOfWeek[] affectedDays, string timeZone, out TimeSpan availableIn);
    }

     public class AvailabilityCalculator : IAvailabilityCalculator
    {
        readonly ITimeZoneService _timeZoneService;
        readonly Func<DateTime> _now;

        public AvailabilityCalculator(ITimeZoneService timeZoneService, Func<DateTime> now)
        {
            _timeZoneService = timeZoneService;
            _now = now;
        }

        public bool TryCalculateTimeToAvailability(TimeSpan startTime, TimeSpan endTime,
            DayOfWeek[] affectedDays, string timeZone, out TimeSpan availableIn)
        {
            if (timeZone == null) throw new ArgumentNullException("timeZone");
            if (affectedDays == null || !affectedDays.Any())
                throw new ArgumentException("affectedDays must be provided");

            availableIn = TimeSpan.Zero;
            var utc = _now().ToUniversalTime();

            DateTime timeNowAtDestination;
            if (!_timeZoneService.TryConvertTimeFromUtc(utc, timeZone, out timeNowAtDestination))
                return false;

            if (!affectedDays.Contains(timeNowAtDestination.DayOfWeek))
                return true;

            var timeOfDay = timeNowAtDestination.TimeOfDay;
            if (timeOfDay < startTime)
                return true;

            TimeSpan adjustedEndTime;
            var isAdjusted = Adjusted(endTime, out adjustedEndTime);
            if (timeOfDay >= adjustedEndTime)
                return true;

            availableIn =
                isAdjusted
                    ? TimeSpan.FromDays(1) - timeOfDay
                    : (endTime - timeOfDay);

            return true;
        }

        static bool Adjusted(TimeSpan endTime, out TimeSpan adjustedEndTime)
        {
            if (endTime == TimeSpan.Zero)
            {
                adjustedEndTime = TimeSpan.Parse("23:59:59.999999");
                return true;
            }

            adjustedEndTime = endTime;
            return false;
        }
    }
}
