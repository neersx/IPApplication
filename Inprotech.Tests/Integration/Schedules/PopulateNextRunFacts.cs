using System;
using Inprotech.Integration.Schedules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class PopulateNextRunFacts
    {
        public class ForMethod
        {
            [Theory]
            [InlineData("Mon", DayOfWeek.Monday)]
            [InlineData("Tue", DayOfWeek.Tuesday)]
            [InlineData("Wed", DayOfWeek.Wednesday)]
            [InlineData("Thu", DayOfWeek.Thursday)]
            [InlineData("Fri", DayOfWeek.Friday)]
            [InlineData("Sat", DayOfWeek.Saturday)]
            [InlineData("Sun", DayOfWeek.Sunday)]
            public void ShouldReturnNextRunOnTheSameDay(string runDay, DayOfWeek expectedDayOfWeek)
            {
                var f = new PopulateNextRunFixture();

                var schedule = new Schedule
                {
                    RunOnDays = runDay,
                    LastRunStartOn = null
                };

                f.Now().Returns(Fixture.Today());

                f.Subject.For(schedule);

                Assert.Equal(expectedDayOfWeek, schedule.NextRun.GetValueOrDefault().DayOfWeek);
            }

            [Theory]
            [InlineData("Mon,Wed", DayOfWeek.Monday, DayOfWeek.Wednesday)]
            [InlineData("Tue,Fri", DayOfWeek.Friday, DayOfWeek.Tuesday)]
            public void ShouldDetermineTheNextRunDay(string runDay, DayOfWeek lastRunDay, DayOfWeek expectedNextRunDay)
            {
                var f = new PopulateNextRunFixture();

                var schedule = new Schedule
                {
                    RunOnDays = runDay,
                    LastRunStartOn = Fixture.From(lastRunDay)
                };

                f.Now().Returns(Fixture.From(DayOfWeek.Sunday));

                f.Subject.For(schedule);

                Assert.Equal(expectedNextRunDay, schedule.NextRun.GetValueOrDefault().DayOfWeek);
            }

            [Fact]
            public void NextRunConsidersStartTime()
            {
                var f = new PopulateNextRunFixture();

                var lastMonday = Fixture.Monday + TimeSpan.FromHours(1) - TimeSpan.FromDays(7);

                var schedule = new Schedule
                {
                    RunOnDays = "Mon",
                    StartTime = TimeSpan.FromHours(1),
                    LastRunStartOn = lastMonday
                };

                f.Now().Returns(Fixture.Monday);

                f.Subject.For(schedule);

                Assert.Equal(Fixture.Monday + TimeSpan.FromHours(1), schedule.NextRun);
            }

            [Fact]
            public void NextRunFromNow()
            {
                var f = new PopulateNextRunFixture();

                var schedule = new Schedule
                {
                    RunOnDays = "Mon",
                    StartTime = TimeSpan.FromHours(1),
                    LastRunStartOn = null
                };

                f.Now().Returns(Fixture.Monday);

                f.Subject.For(schedule);

                Assert.Equal(Fixture.Monday + TimeSpan.FromHours(1), schedule.NextRun);
            }

            [Fact]
            public void ShouldClearNextRunWhenExpired()
            {
                var f = new PopulateNextRunFixture();

                var schedule = new Schedule
                {
                    RunOnDays = "Mon",
                    StartTime = TimeSpan.FromHours(1),
                    LastRunStartOn = null,
                    NextRun = Fixture.PastDate(),
                    ExpiresAfter = Fixture.PastDate()
                };

                f.Now().Returns(Fixture.Monday);

                f.Subject.For(schedule);

                Assert.Null(schedule.NextRun);
            }

            [Fact]
            public void ShouldClearNextRunWhenNoDaysToRun()
            {
                var f = new PopulateNextRunFixture();

                var schedule = new Schedule
                {
                    RunOnDays = null,
                    NextRun = Fixture.FutureDate()
                };

                f.Subject.For(schedule);

                Assert.Null(schedule.NextRun);
            }
        }

        public class PopulateNextRunFixture : IFixture<PopulateNextRun>
        {
            public PopulateNextRunFixture()
            {
                Now = Substitute.For<Func<DateTime>>();

                Subject = new PopulateNextRun(Now);
            }

            public Func<DateTime> Now { get; set; }

            public PopulateNextRun Subject { get; }
        }
    }
}