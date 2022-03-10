using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Recovery;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public class RecoveryCompleteFacts : FactBase
    {
        [Fact]
        public async Task ShouldDeleteScheduleRecoverableRecords()
        {
            var cases = new[]
            {
                new Case {ApplicationNumber = "4", Id = 40}.In(Db),
                new Case {ApplicationNumber = "5", Id = 50}.In(Db)
            };

            var fixture = new RecoveryCompleteFixture(Db)
                          .WithExecution()
                          .WithRecoverableCase(4, cases[0])
                          .WithRecoverableCase(5, cases[1])
                          .WithRecoverableDocument(6, new Document {ApplicationNumber = "6", Id = 60}.In(Db));

            fixture.ScheduleSettingsReader.GetTempStorageId(fixture.Session.ScheduleId)
                   .Returns(RecoveryCompleteFixture.TempStorageId);

            fixture.RecoveryInfoManager.GetIds(RecoveryCompleteFixture.TempStorageId).Returns(
                                                                                              new[]
                                                                                              {
                                                                                                  new RecoveryInfo
                                                                                                  {
                                                                                                      ScheduleRecoverableIds = new long[] {4, 5, 6}
                                                                                                  }
                                                                                              });

            await fixture.Subject.Complete(fixture.Session.ScheduleId);

            Assert.False(Db.Set<ScheduleRecoverable>().Any());
        }

        [Fact]
        public async Task ShouldDeleteTempStorageRecoveryInfoRecord()
        {
            var fixture = new RecoveryCompleteFixture(Db);

            fixture.ScheduleSettingsReader.GetTempStorageId(fixture.Session.ScheduleId)
                   .Returns(RecoveryCompleteFixture.TempStorageId);

            fixture.RecoveryInfoManager.GetIds(RecoveryCompleteFixture.TempStorageId).Returns(
                                                                                              new[]
                                                                                              {
                                                                                                  new RecoveryInfo
                                                                                                  {
                                                                                                      ScheduleRecoverableIds = new long[] {4, 5, 6}
                                                                                                  }
                                                                                              });

            await fixture.Subject.Complete(fixture.Session.ScheduleId);

            fixture.RecoveryInfoManager.Received(1).DeleteIds(RecoveryCompleteFixture.TempStorageId);
        }
    }

    internal class RecoveryCompleteFixture : IFixture<RecoveryComplete>
    {
        public const int TempStorageId = 2;
        public const int ScheduleExecutionid = 3;
        readonly InMemoryDbContext _db;

        public IManageRecoveryInfo RecoveryInfoManager = Substitute.For<IManageRecoveryInfo>();

        public Schedule Schedule = new Schedule
        {
            Id = 1,
            DataSourceType = DataSourceType.UsptoPrivatePair,
            DownloadType = DownloadType.Documents,
            Name = "Test Schedule",
            Type = ScheduleType.Retry
        };

        public IReadScheduleSettings ScheduleSettingsReader =
            Substitute.For<IReadScheduleSettings>();

        public Session Session = new Session
        {
            Id = Guid.NewGuid(),
            ScheduleId = 1
        };

        public RecoveryCompleteFixture(InMemoryDbContext db)
        {
            _db = db;
            Schedule.In(db);
        }

        public RecoveryComplete Subject => new RecoveryComplete(RecoveryInfoManager, _db,
                                                                ScheduleSettingsReader);

        public RecoveryCompleteFixture WithExecution()
        {
            new ScheduleExecution(Session.Id, Schedule, Fixture.Today()) {Id = ScheduleExecutionid}.In(_db);
            return this;
        }

        public RecoveryCompleteFixture WithRecoverableCase(long id, Case @case)
        {
            var execution = _db.Set<ScheduleExecution>()
                               .Single(se => se.Id == ScheduleExecutionid);

            new ScheduleRecoverable(execution, @case, Fixture.Today()) {Id = id}.In(_db);

            return this;
        }

        public RecoveryCompleteFixture WithRecoverableDocument(long id, Document document)
        {
            var execution = _db.Set<ScheduleExecution>()
                               .Single(se => se.Id == ScheduleExecutionid);

            new ScheduleRecoverable(execution, document, Fixture.Today()) {Id = id}.In(_db);

            return this;
        }
    }
}