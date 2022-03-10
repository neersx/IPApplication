using System.Linq;
using System.Threading.Tasks;
using Inprotech.IntegrationServer.ExchangeIntegration;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.ExchangeIntegration;
using Xunit;

#pragma warning disable 618

namespace Inprotech.Tests.IntegrationServer.ExchangeIntegration
{
    public class RequestQueueFacts
    {
        public class NextRequest : FactBase
        {
            [Fact]
            public async Task ExitsWhenNothingIsReady()
            {
                new ExchangeRequestQueueItem {StaffId = Fixture.Integer(), SequenceDate = Fixture.PastDate(), StatusId = (short) ExchangeRequestStatus.Failed}.In(Db);
                new ExchangeRequestQueueItem {StaffId = Fixture.Integer(), SequenceDate = Fixture.PastDate(), StatusId = (short) ExchangeRequestStatus.Failed}.In(Db);
                var r = await new ExchangeRequestQueue(Db).NextRequest();

                Assert.Null(r);
                Assert.False(Db.Set<ExchangeRequestQueueItem>().Any(_ => _.StatusId == (short) ExchangeRequestStatus.Ready));
            }

            [Fact]
            public async Task PicksTheFirstReadyRequestAndSetsToProcessing()
            {
                var staffId = Fixture.Integer();
                new ExchangeRequestQueueItem {StaffId = Fixture.Integer(), SequenceDate = Fixture.PastDate(), StatusId = (short) ExchangeRequestStatus.Failed}.In(Db);
                new ExchangeRequestQueueItem {StaffId = Fixture.Integer(), SequenceDate = Fixture.PastDate(), StatusId = (short) ExchangeRequestStatus.Failed}.In(Db);
                new ExchangeRequestQueueItem {StaffId = staffId, SequenceDate = Fixture.PastDate(), StatusId = (short) ExchangeRequestStatus.Ready}.In(Db);
                new ExchangeRequestQueueItem {StaffId = Fixture.Integer(), SequenceDate = Fixture.PastDate(), StatusId = (short) ExchangeRequestStatus.Ready}.In(Db);

                var r = await new ExchangeRequestQueue(Db).NextRequest();
                var p = Db.Set<ExchangeRequestQueueItem>().Single(_ => _.Id == r.Id);

                Assert.Equal(3, r.Id);
                Assert.Equal(staffId, r.StaffId);
                Assert.Equal((short) ExchangeRequestStatus.Processing, p.StatusId);
            }
        }

        public class Completed : FactBase
        {
            [Fact]
            public async Task SetsTheStatusToCompleted()
            {
                new ExchangeRequestQueueItem {StaffId = Fixture.Integer(), SequenceDate = Fixture.PastDate(), StatusId = (short) ExchangeRequestStatus.Failed}.In(Db);
                new ExchangeRequestQueueItem {StaffId = Fixture.Integer(), SequenceDate = Fixture.PastDate(), StatusId = (short) ExchangeRequestStatus.Failed}.In(Db);
                new ExchangeRequestQueueItem {StaffId = Fixture.Integer(), SequenceDate = Fixture.PastDate(), StatusId = (short) ExchangeRequestStatus.Ready}.In(Db);
                new ExchangeRequestQueueItem {StaffId = Fixture.Integer(), SequenceDate = Fixture.PastDate(), StatusId = (short) ExchangeRequestStatus.Ready}.In(Db);

                await new ExchangeRequestQueue(Db).Completed(3);
                Assert.False(Db.Set<ExchangeRequestQueueItem>().Any(_ => _.Id == 3));
            }
        }

        public class Failed : FactBase
        {
            [Fact]
            public async Task SetsStatusToFailedAndAddsMessage()
            {
                var staffId = Fixture.Integer();
                var error = Fixture.String("Error");
                new ExchangeRequestQueueItem {StaffId = Fixture.Integer(), SequenceDate = Fixture.PastDate(), StatusId = (short) ExchangeRequestStatus.Failed}.In(Db);
                new ExchangeRequestQueueItem {StaffId = Fixture.Integer(), SequenceDate = Fixture.PastDate(), StatusId = (short) ExchangeRequestStatus.Failed}.In(Db);
                new ExchangeRequestQueueItem {StaffId = staffId, SequenceDate = Fixture.PastDate(), StatusId = (short) ExchangeRequestStatus.Ready}.In(Db);
                new ExchangeRequestQueueItem {StaffId = Fixture.Integer(), SequenceDate = Fixture.PastDate(), StatusId = (short) ExchangeRequestStatus.Ready}.In(Db);

                await new ExchangeRequestQueue(Db).Failed(4, error, KnownStatuses.Failed);
                var p = Db.Set<ExchangeRequestQueueItem>().SingleOrDefault(_ => _.Id == 4);

                Assert.NotNull(p);
                Assert.Equal((short) ExchangeRequestStatus.Failed, p.StatusId);
                Assert.Equal(error, p.ErrorMessage);
            }
        }
    }
}