using System;
using Inprotech.Infrastructure.DateTimeHelpers;
using Xunit;

namespace Inprotech.Tests.Infrastructure.DateTimeHelpers
{
    public class TimeZoneServiceFacts
    {
        private readonly DateTime _utcDateTime = new DateTime(2014, 9, 1, 13, 45, 0);
        private readonly DateTime _expectedDateTime = new DateTime(2014, 9, 1, 23, 45, 0);

        private const string AedtTimezone = "AUS Eastern Standard Time";
        private const string EastTimezone = "E. Australia Standard Time";

        [Fact]
        public void ShouldConvertToSpecifiedLocalTimezoneWithDaylightSaving()
        {
            DateTime result;

            var f = new TimeZoneServiceFixture();
            Assert.True(f.Subject.TryConvertTimeFromUtc(_utcDateTime, AedtTimezone, out result));
            Assert.Equal(_expectedDateTime, result);
        }

        [Fact]
        public void ShouldConvertToSpecifiedLocalTimezoneWithoutDaylightSaving()
        {
            DateTime result;

            var f = new TimeZoneServiceFixture();
            Assert.True(f.Subject.TryConvertTimeFromUtc(_utcDateTime, EastTimezone, out result));
            Assert.Equal(_expectedDateTime, result);
        }

        [Fact]
        public void ShouldReturnFalseIfTimezoneDoesNotExist()
        {
            DateTime result;

            var f = new TimeZoneServiceFixture();
            Assert.False(f.Subject.TryConvertTimeFromUtc(_utcDateTime, "missing", out result));
            Assert.Equal(_utcDateTime, result);
        }
    }

    internal class TimeZoneServiceFixture : IFixture<TimeZoneService>
    {
        public TimeZoneService Subject { get { return new TimeZoneService(); } }
    }
}
