using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.MessageQueueMonitor;
using Inprotech.Tests.Fakes;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities.MessageQueueMonitor
{
    public class CleanupMessageStoreJobFacts : FactBase
    {
        long _processIdA = 10;
        long _processIdB = 99;

        void AddBaseData()
        {
            Enumerable.Range(1, 100).ToList().ForEach(_ => new MessageStore {ProcessId = _processIdA}.In(Db));
            Enumerable.Range(1, 1000).ToList().ForEach(_ => new MessageStore {ProcessId = _processIdB}.In(Db));
        }

        [Fact]
        public async Task MessageStoreNotDeletedIfProcessIdsNotFlagged()
        {
            AddBaseData();
            Assert.Equal(1100, Db.Set<MessageStore>().Count());

            await new CleanupMessageStoreJob(Db, Fixture.Today, null).CleanupMessageStoreTable();

            Assert.Equal(1100, Db.Set<MessageStore>().Count());
        }

        [Fact]
        public async Task DeletesMessageStoreAndSetsCleanupFlag()
        {
            AddBaseData();
            Assert.Equal(1100, Db.Set<MessageStore>().Count());

            new ProcessIdsToCleanup(1, _processIdA, DateTime.Today).In(Db);
            new ProcessIdsToCleanup(2, _processIdB, DateTime.Today.AddDays(-1)).In(Db);

            await new CleanupMessageStoreJob(Db, Fixture.Today, null).CleanupMessageStoreTable();
            Assert.Equal(100, Db.Set<MessageStore>().Count());
            var processIdDetailsB = Db.Set<ProcessIdsToCleanup>().Single(_ => _.ProcessId == _processIdB);
            Assert.True(processIdDetailsB.IsCleanedUp);
            Assert.NotNull(processIdDetailsB.CleanupCompletedOn);

            await new CleanupMessageStoreJob(Db, Fixture.Today, new NLogBackgroundProcessLogger<ICleanupMessageStoreJob>()).CleanupMessageStoreTable();
            Assert.Equal(0, Db.Set<MessageStore>().Count());
            var processIdDetailsA = Db.Set<ProcessIdsToCleanup>().Single(_ => _.ProcessId == _processIdA);
            Assert.True(processIdDetailsA.IsCleanedUp);
        }
    }
}