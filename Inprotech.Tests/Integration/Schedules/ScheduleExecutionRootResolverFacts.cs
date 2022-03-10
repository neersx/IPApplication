using System;
using Inprotech.Integration;
using Inprotech.Integration.Schedules;
using Inprotech.Tests.Fakes;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class ScheduleExecutionRootResolverFacts : FactBase
    {
        [Theory]
        [InlineData(DataSourceType.UsptoPrivatePair, "Sha\\wn's |do?wnload", "619ae8b3-2840-4a1f-bb83-ab65e0425006", @"UsptoIntegration\Shawn's download\619ae8b3-2840-4a1f-bb83-ab65e0425006")]
        [InlineData(DataSourceType.UsptoTsdr, "Sha\\wn's |do?wnload", "619ae8b3-2840-4a1f-bb83-ab65e0425006", @"PtoIntegration\UsptoTsdr\Shawn's download\619ae8b3-2840-4a1f-bb83-ab65e0425006")]
        [InlineData(DataSourceType.Epo, "Sha\\wn's |do?wnload", "619ae8b3-2840-4a1f-bb83-ab65e0425006", @"PtoIntegration\Epo\Shawn's download\619ae8b3-2840-4a1f-bb83-ab65e0425006")]
        public void ShouldResolveValidPath(DataSourceType dataSourceType, string scheduleName,
                                           string sessionGuid, string expectedPath)
        {
            var schedule = new Schedule
            {
                DataSourceType = dataSourceType,
                Name = scheduleName
            }.In(Db);

            var scheduleExecution = new ScheduleExecution(new Guid(sessionGuid), schedule, Fixture.Today()).In(Db);

            var result = new ScheduleExecutionRootResolver(Db).Resolve(scheduleExecution.SessionGuid);

            Assert.Equal(expectedPath, result);
        }
    }
}