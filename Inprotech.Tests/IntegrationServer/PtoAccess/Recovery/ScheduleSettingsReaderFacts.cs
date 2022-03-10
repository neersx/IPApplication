using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Recovery;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Recovery
{
    public class ScheduleSettingsReaderFacts : FactBase
    {
        [Fact]
        public void ShouldGetTempStorageId()
        {
            var tempStorageId = Fixture.Long();
            var schedule = new Schedule
            {
                ExtendedSettings = JsonConvert.SerializeObject(new
                {
                    TempStorageId = tempStorageId
                })
            }.In(Db);

            var subject = new ReadScheduleSettings(Db);

            Assert.Equal(tempStorageId, subject.GetTempStorageId(schedule.Id));
        }
    }
}