using System;
using Inprotech.Integration;
using Inprotech.Integration.DataSources;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.DataSources
{
    public class DataSourceAvailabilityResolverFacts : FactBase
    {
        public class DataSourceAvailabilityResolverFixture : IFixture<DataSourceAvailabilityResolver>
        {
            readonly InMemoryDbContext _db;

            public DataSourceAvailabilityResolverFixture(InMemoryDbContext db)
            {
                _db = db;
                AvailabilityCalculator = Substitute.For<IAvailabilityCalculator>();

                DataExtractionLogger = Substitute.For<IDataExtractionLogger>();

                Subject = new DataSourceAvailabilityResolver(_db, AvailabilityCalculator,
                                                             DataExtractionLogger);
            }

            public IAvailabilityCalculator AvailabilityCalculator { get; set; }

            public IDataExtractionLogger DataExtractionLogger { get; set; }

            public DataSourceAvailabilityResolver Subject { get; set; }

            public DataSourceAvailabilityResolverFixture WithSiteConfiguration(DataSourceType dataSourceType)
            {
                new DataSourceAvailability
                {
                    Source = dataSourceType,
                    UnavailableDays = "Sun",
                    StartTimeValue = "00:00",
                    EndTimeValue = "00:00",
                    TimeZone = "Any TimeZone, Really."
                }.In(_db);
                return this;
            }

            public DataSourceAvailabilityResolverFixture WithAvailableIn(TimeSpan availableIn, bool result = true)
            {
                TimeSpan t1;
                AvailabilityCalculator.TryCalculateTimeToAvailability(
                                                                      Arg.Any<TimeSpan>(),
                                                                      Arg.Any<TimeSpan>(),
                                                                      Arg.Any<DayOfWeek[]>(),
                                                                      Arg.Any<string>(), out t1)
                                      .ReturnsForAnyArgs(
                                                         x =>
                                                         {
                                                             x[4] = availableIn;
                                                             return result;
                                                         }
                                                        );
                return this;
            }
        }

        [Fact]
        public void ReportsErrorToLog()
        {
            var f = new DataSourceAvailabilityResolverFixture(Db)
                    .WithSiteConfiguration(DataSourceType.UsptoTsdr)
                    .WithAvailableIn(TimeSpan.Zero, false);

            f.Subject.Resolve((int) DataSourceType.UsptoTsdr);

            f.DataExtractionLogger.Received(1).Warning(Arg.Any<string>());
        }

        [Fact]
        public void ResolvesForEachAvailabilityRunForTheSource()
        {
            var f = new DataSourceAvailabilityResolverFixture(Db)
                    .WithSiteConfiguration(DataSourceType.UsptoPrivatePair)
                    .WithSiteConfiguration(DataSourceType.UsptoPrivatePair)
                    .WithSiteConfiguration(DataSourceType.UsptoTsdr)
                    .WithAvailableIn(TimeSpan.Zero);

            var r = f.Subject.Resolve((int) DataSourceType.UsptoPrivatePair);

            f.AvailabilityCalculator
             .ReceivedWithAnyArgs(2)
             .TryCalculateTimeToAvailability(
                                             Arg.Any<TimeSpan>(),
                                             Arg.Any<TimeSpan>(),
                                             Arg.Any<DayOfWeek[]>(),
                                             Arg.Any<string>(), out _);

            Assert.Equal(TimeSpan.Zero, r);
        }

        [Fact]
        public void ReturnsTimeToUpTime()
        {
            var f = new DataSourceAvailabilityResolverFixture(Db)
                    .WithSiteConfiguration(DataSourceType.UsptoTsdr)
                    .WithAvailableIn(TimeSpan.FromHours(1));

            var r = f.Subject.Resolve((int) DataSourceType.UsptoTsdr);

            Assert.Equal(TimeSpan.FromHours(1), r);
        }
    }
}