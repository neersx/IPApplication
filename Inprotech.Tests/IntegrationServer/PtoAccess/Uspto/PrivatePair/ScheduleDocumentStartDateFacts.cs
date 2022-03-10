using System;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Schedules.Extensions.Uspto.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public class ScheduleDocumentStartDateFacts : FactBase
    {
        ScheduleDocumentStartDate CreateSubject()
        {
            return new ScheduleDocumentStartDate(Db, Fixture.Today);
        }

        Schedule BuildPrivatePairSchedule(int? daysWithLast = null)
        {
            return new Schedule
            {
                ExtendedSettings = JsonConvert.SerializeObject(new PrivatePairSchedule
                {
                    DaysWithinLast = daysWithLast
                })
            }.In(Db);
        }

        [Theory]
        [InlineData(1)]
        [InlineData(3)]
        [InlineData(7)]
        [InlineData(30)]
        [InlineData(90)]
        public void ReturnsFirstExecutionDateByOffsetingDaysWithinLast(int daysWithinLast)
        {
            var schedule = BuildPrivatePairSchedule(daysWithinLast);

            schedule.Executions.Add(new ScheduleExecution(Guid.NewGuid(), schedule, Fixture.Today()));

            var result = CreateSubject().Resolve(new Session
            {
                ScheduleId = schedule.Id
            });

            Assert.Equal(Fixture.Today().AddDays(-1 * daysWithinLast), result);
        }

        [Fact]
        public void ReturnsFirstExecutionDate()
        {
            var schedule = BuildPrivatePairSchedule();

            schedule.Executions.Add(new ScheduleExecution(Guid.NewGuid(), schedule, Fixture.Today()));
            schedule.Executions.Add(new ScheduleExecution(Guid.NewGuid(), schedule, Fixture.PastDate()));

            var result = CreateSubject().Resolve(new Session
            {
                ScheduleId = schedule.Id
            });

            Assert.Equal(Fixture.PastDate(), result);
        }

        [Fact]
        public void ReturnsFirstExecutionDateFromMainSchedule()
        {
            var schedule = BuildPrivatePairSchedule();

            var childSchedule = BuildPrivatePairSchedule();

            childSchedule.Parent = schedule;

            childSchedule.Executions.Add(
                                         new ScheduleExecution(Guid.NewGuid(), childSchedule, Fixture.PastDate().AddYears(-20)));
            /* note: child schedule will never have an execution date earlier than the parent schedule */

            schedule.Executions.Add(
                                    new ScheduleExecution(Guid.NewGuid(), schedule, Fixture.Today()));

            schedule.Executions.Add(
                                    new ScheduleExecution(Guid.NewGuid(), schedule, Fixture.PastDate()));

            var result = CreateSubject().Resolve(new Session
            {
                ScheduleId = childSchedule.Id
            });

            Assert.Equal(Fixture.PastDate(), result);
        }
    }
}