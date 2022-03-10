using System;
using System.Linq;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Uspto.PrivatePair;

namespace Inprotech.Integration.DataSources
{
    public interface IAvailabilityResolver
    {
        /// <summary>
        /// Resolves known time to downtime for a given site.
        /// </summary>
        /// <returns>time to availability; or TimeSpan.Zero</returns>
        TimeSpan Resolve(int siteIdentifier = 0);
    }

    public class DataSourceAvailabilityResolver : IAvailabilityResolver
    {
        readonly IRepository _repository;
        readonly IAvailabilityCalculator _availabilityCalculator;
        readonly IDataExtractionLogger _logger;

        public DataSourceAvailabilityResolver(IRepository repository,
            IAvailabilityCalculator availabilityCalculator,
            IDataExtractionLogger logger)
        {
            _repository = repository;
            _availabilityCalculator = availabilityCalculator;
            _logger = logger;
        }

        public TimeSpan Resolve(int siteIdentifier)
        {
            var availability = _repository.Set<DataSourceAvailability>()
                .Where(_ => (int) _.Source == siteIdentifier)
                .ToArray();

            foreach (var a in availability)
            {
                TimeSpan availableIn;
                if (!_availabilityCalculator.TryCalculateTimeToAvailability(
                    a.StartTime,
                    a.EndTime,
                    a.UnavailableDays.ConvertToDaysOfWeek(),
                    a.TimeZone,
                    out availableIn))
                {
                    _logger.Warning(string.Format("Unable to resolve '{0}' when processing '{1}' requests.",
                        a.TimeZone, a.Source));
                    continue;
                }

                if (availableIn != TimeSpan.Zero)
                    return availableIn;
            }

            return TimeSpan.Zero;
        }
    }
}