using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.CleanUp;
using Inprotech.Tests.Fakes;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.CleanUp
{
    public class IdentifyProcessIdsToCleanupFacts : FactBase
    {
        void AddBaseData()
        {
            var usptoSchedule = new Schedule {DataSourceType = DataSourceType.UsptoPrivatePair, ExtendedSettings = "{ProcessId:11}"}.In(Db);
            new ScheduleExecution(new Guid(), usptoSchedule, Fixture.Monday) {Finished = Fixture.Today().AddMonths(-7), IsTidiedUp = true}.In(Db);
        }

        [Fact]
        public async Task ConsidersOnlyUsptoSchedules()
        {
            AddBaseData();

            var innographySchedule = new Schedule {DataSourceType = DataSourceType.IpOneData, ExtendedSettings = "{ProcessId:12}"}.In(Db);
            new ScheduleExecution(new Guid(), innographySchedule, Fixture.Monday) {Finished = Fixture.Today().AddMonths(-7), IsTidiedUp = true}.In(Db);

            var f = new IdentifyProcessIdsToCleanup(Db, Fixture.Today);
            await f.MarkProcessIdsToCleanup();

            var dataAdded = Db.Set<ProcessIdsToCleanup>().ToList();
            Assert.NotNull(dataAdded);
            Assert.Equal(1, dataAdded.Count);
            Assert.Equal(11, dataAdded.Single().ProcessId);
        }

        [Fact]
        public async Task ConsidersOnlyScheduleExecutionsWhichAreTiedUp()
        {
            AddBaseData();

            var usptoSchedule2 = new Schedule {DataSourceType = DataSourceType.UsptoPrivatePair, ExtendedSettings = "{ProcessId:12}"}.In(Db);
            new ScheduleExecution(new Guid(), usptoSchedule2, Fixture.Monday) {Finished = Fixture.Today().AddMonths(-7), IsTidiedUp = false}.In(Db);

            var f = new IdentifyProcessIdsToCleanup(Db, Fixture.Today);
            await f.MarkProcessIdsToCleanup();

            var dataAdded = Db.Set<ProcessIdsToCleanup>().ToList();
            Assert.NotNull(dataAdded);
            Assert.Equal(1, dataAdded.Count);
            Assert.Equal(11, dataAdded.Single().ProcessId);
        }

        [Fact]
        public async Task ConsidersOnlyScheduleExecutionsFinishedBefore6Months()
        {
            AddBaseData();

            var usptoSchedule2 = new Schedule {DataSourceType = DataSourceType.UsptoPrivatePair, ExtendedSettings = "{ProcessId:12}"}.In(Db);
            new ScheduleExecution(new Guid(), usptoSchedule2, Fixture.Monday) {Finished = Fixture.Today().AddMonths(-3), IsTidiedUp = true}.In(Db);

            var f = new IdentifyProcessIdsToCleanup(Db, Fixture.Today);
            await f.MarkProcessIdsToCleanup();

            var dataAdded = Db.Set<ProcessIdsToCleanup>().ToList();
            Assert.NotNull(dataAdded);
            Assert.Equal(1, dataAdded.Count);
            Assert.Equal(11, dataAdded.Single().ProcessId);
        }

        [Fact]
        public async Task AddsProcessIdsNotAlreadyAddedInTable()
        {
            AddBaseData();
            new ProcessIdsToCleanup(12, 10, Fixture.Today()).In(Db);
            var f = new IdentifyProcessIdsToCleanup(Db, Fixture.Today);
            await f.MarkProcessIdsToCleanup();

            var allProcessIds = Db.Set<ProcessIdsToCleanup>().OrderBy(_ => _.ProcessId).ToList();
            Assert.True(allProcessIds.All(_ => _.IsCleanedUp == false));
            Assert.True(allProcessIds.All(_ => _.CleanupCompletedOn == null));

            Assert.Equal(10, allProcessIds.First().ProcessId);
            Assert.Equal(11, allProcessIds.Last().ProcessId);
        }
    }
}