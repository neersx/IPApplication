using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.ExchangeIntegration;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.ExchangeIntegration;
using InprotechKaizen.Model.Reminders;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

#pragma warning disable 618

namespace Inprotech.Tests.Web.ExchangeIntegration
{
    public class ExchangeIntegrationControllerFacts
    {
        public class GetViewDataMethod : FactBase
        {
            [Fact]
            public void CreatesModel()
            {
                var s = Db.Set<StaffReminder>();
                s.Add(new StaffReminder(1, Fixture.Today())
                {
                    Reference = Fixture.String()
                });

                var x = Db.Set<ExchangeRequestQueueItem>();
                x.Add(new ExchangeRequestQueueItem
                {
                    StaffId = 1,
                    DateCreated = Fixture.Today(),
                    SequenceDate = Fixture.Today(),
                    StatusId = 0,
                    RequestTypeId = 0,
                    Reference = Fixture.String()
                }.WithKnownId(1));

                x.Add(new ExchangeRequestQueueItem
                {
                    StaffId = 1,
                    DateCreated = Fixture.Today(),
                    SequenceDate = Fixture.Today(),
                    StatusId = 0,
                    RequestTypeId = 1,
                    Reference = Fixture.String()
                }.WithKnownId(2));

                x.Add(new ExchangeRequestQueueItem
                {
                    StaffId = 1,
                    DateCreated = Fixture.Today(),
                    SequenceDate = Fixture.Today(),
                    StatusId = 0,
                    RequestTypeId = 2,
                    Reference = Fixture.String()
                }.WithKnownId(3));

                x.Add(new ExchangeRequestQueueItem
                {
                    StaffId = 2,
                    DateCreated = Fixture.Today(),
                    SequenceDate = Fixture.Today(),
                    StatusId = 2,
                    RequestTypeId = 2,
                    Reference = Fixture.String()
                }.WithKnownId(4));

                x.Add(new ExchangeRequestQueueItem
                {
                    StaffId = 2,
                    DateCreated = Fixture.Today(),
                    SequenceDate = Fixture.Today(),
                    StatusId = 1,
                    RequestTypeId = 0,
                    Reference = Fixture.String()
                }.WithKnownId(5));

                var qp = CommonQueryParameters.Default;

                var f = new ExchangeIntegrationControllerFixture(Db);
                var result = f.Subject.GetViewData(qp);

                Assert.Equal(5, result.Pagination.Total);
            }

            [Fact]
            public void RequiresManageExchangeIntegrationTask()
            {
                var r = TaskSecurity.Secures<ExchangeIntegrationController>(ApplicationTask.ExchangeIntegrationAdministration);
                Assert.True(r);
            }
        }

        public class ResetMethod : FactBase
        {
            [Fact]
            public void OnlyUpdatesMatchingFailedRequests()
            {
                var r1 = new ExchangeRequestQueueItem(Fixture.Integer(), Fixture.PastDate(), Fixture.Today(), (short)ExchangeRequestType.Add, (short)ExchangeRequestStatus.Ready).In(Db);
                var r2 = new ExchangeRequestQueueItem(Fixture.Integer(), Fixture.PastDate(), Fixture.Today(), (short)ExchangeRequestType.Add, (short)ExchangeRequestStatus.Failed).In(Db);
                var r3 = new ExchangeRequestQueueItem(Fixture.Integer(), Fixture.PastDate(), Fixture.Today(), (short)ExchangeRequestType.Add, (short)ExchangeRequestStatus.Processing).In(Db);
                var f = new ExchangeIntegrationControllerFixture(Db);
                f.Subject.ResetExchangeRequests(new[] { r1.Id, r2.Id, r3.Id });

                Assert.Equal((short)ExchangeRequestStatus.Ready, Db.Set<ExchangeRequestQueueItem>().Single(_ => _.Id == r1.Id).StatusId);
                Assert.Equal((short)ExchangeRequestStatus.Ready, Db.Set<ExchangeRequestQueueItem>().Single(_ => _.Id == r2.Id).StatusId);
                Assert.Equal((short)ExchangeRequestStatus.Processing, Db.Set<ExchangeRequestQueueItem>().Single(_ => _.Id == r3.Id).StatusId);
                Db.Received(1).SaveChanges();
            }

            [Fact]
            public void ReturnsNumberOfUpdatedRequests()
            {
                var r1 = new ExchangeRequestQueueItem(Fixture.Integer(), Fixture.PastDate(), Fixture.Today(), (short)ExchangeRequestType.Add, (short)ExchangeRequestStatus.Ready).In(Db);
                var r2 = new ExchangeRequestQueueItem(Fixture.Integer(), Fixture.PastDate(), Fixture.Today(), (short)ExchangeRequestType.Add, (short)ExchangeRequestStatus.Failed).In(Db);
                var r3 = new ExchangeRequestQueueItem(Fixture.Integer(), Fixture.PastDate(), Fixture.Today(), (short)ExchangeRequestType.Add, (short)ExchangeRequestStatus.Failed).In(Db);
                var r4 = new ExchangeRequestQueueItem(Fixture.Integer(), Fixture.PastDate(), Fixture.Today(), (short)ExchangeRequestType.Add, (short)ExchangeRequestStatus.Processing).In(Db);
                var f = new ExchangeIntegrationControllerFixture(Db);
                var r = f.Subject.ResetExchangeRequests(new[] { r1.Id, r2.Id, r3.Id, r4.Id });

                Assert.Equal((short)ExchangeRequestStatus.Ready, Db.Set<ExchangeRequestQueueItem>().Single(_ => _.Id == r1.Id).StatusId);
                Assert.Equal((short)ExchangeRequestStatus.Ready, Db.Set<ExchangeRequestQueueItem>().Single(_ => _.Id == r2.Id).StatusId);
                Assert.Equal((short)ExchangeRequestStatus.Ready, Db.Set<ExchangeRequestQueueItem>().Single(_ => _.Id == r3.Id).StatusId);
                Assert.Equal((short)ExchangeRequestStatus.Processing, Db.Set<ExchangeRequestQueueItem>().Single(_ => _.Id == r4.Id).StatusId);
                Db.Received(2).SaveChanges();
                Assert.Equal(r.Result.Updated, 2);
                Assert.Equal(r.Result.Status, "success");
            }

            [Fact]
            public async Task OnlyUpdatesMatchingFailedRequestsByUserId()
            {
                int nameId = Fixture.Integer();
                var user = new User(userName: Fixture.UniqueName(), isExternalUser: false) { NameId = nameId }.In(Db);
                var r1 = new ExchangeRequestQueueItem(Fixture.Integer(), Fixture.PastDate(), Fixture.Today(), (short)ExchangeRequestType.Add, (short)ExchangeRequestStatus.Failed).In(Db);
                var r2 = new ExchangeRequestQueueItem(Fixture.Integer(), Fixture.PastDate(), Fixture.Today(), (short)ExchangeRequestType.Add, (short)ExchangeRequestStatus.Processing) { NameId = nameId, IdentityId = user.Id }.In(Db);
                var r3 = new ExchangeRequestQueueItem(Fixture.Integer(), Fixture.PastDate(), Fixture.Today(), (short)ExchangeRequestType.Add, (short)ExchangeRequestStatus.Failed) { NameId = nameId, IdentityId = user.Id }.In(Db);
                var f = new ExchangeIntegrationControllerFixture(Db);
                await f.Subject.ResetExchangeRequests(user.Id);

                Assert.Equal((short)ExchangeRequestStatus.Failed, Db.Set<ExchangeRequestQueueItem>().Single(_ => _.Id == r1.Id).StatusId);
                Assert.Equal((short)ExchangeRequestStatus.Processing, Db.Set<ExchangeRequestQueueItem>().Single(_ => _.Id == r2.Id).StatusId);
                Assert.Equal((short)ExchangeRequestStatus.Ready, Db.Set<ExchangeRequestQueueItem>().Single(_ => _.Id == r3.Id).StatusId);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeletesCorrectRequest()
            {
                var rx = new ExchangeRequestQueueItem(Fixture.Integer(), Fixture.PastDate(), Fixture.Today(), (short)ExchangeRequestType.Add, (short)ExchangeRequestStatus.Failed).In(Db);
                var r1 = new ExchangeRequestQueueItem(Fixture.Integer(), Fixture.PastDate(), Fixture.Today(), (short)ExchangeRequestType.Add, (short)ExchangeRequestStatus.Ready).In(Db);
                var r2 = new ExchangeRequestQueueItem(Fixture.Integer(), Fixture.PastDate(), Fixture.Today(), (short)ExchangeRequestType.Add, (short)ExchangeRequestStatus.Failed).In(Db);
                var f = new ExchangeIntegrationControllerFixture(Db);
                var r = f.Subject.DeleteExchangeRequests(new[] { r1.Id, r2.Id });

                Assert.Equal(r.Result.Status, "success");
                Assert.False(Db.Set<ExchangeRequestQueueItem>().Any(_ => _.Id == r1.Id));
                Assert.False(Db.Set<ExchangeRequestQueueItem>().Any(_ => _.Id == r2.Id));
                Assert.True(Db.Set<ExchangeRequestQueueItem>().Any(_ => _.Id == rx.Id));
            }

            [Fact]
            public void HandlesNonMatchingRequests()
            {
                var nonExistent = Fixture.Integer();
                var r1 = new ExchangeRequestQueueItem(Fixture.Integer(), Fixture.PastDate(), Fixture.Today(), (short)ExchangeRequestType.Add, (short)ExchangeRequestStatus.Ready).In(Db);
                var r2 = new ExchangeRequestQueueItem(Fixture.Integer(), Fixture.PastDate(), Fixture.Today(), (short)ExchangeRequestType.Add, (short)ExchangeRequestStatus.Failed).In(Db);
                var r3 = new ExchangeRequestQueueItem(Fixture.Integer(), Fixture.PastDate(), Fixture.Today(), (short)ExchangeRequestType.Add, (short)ExchangeRequestStatus.Processing).In(Db);
                var f = new ExchangeIntegrationControllerFixture(Db);
                var r = f.Subject.DeleteExchangeRequests(new[] { (long)nonExistent });

                Assert.Equal(r.Result.Status, "success");
                Assert.True(Db.Set<ExchangeRequestQueueItem>().All(_ => _.Id == r1.Id || _.Id == r2.Id || _.Id == r3.Id));
            }
        }

        public class ExchangeIntegrationControllerFixture : IFixture<ExchangeIntegrationController>
        {
            public ExchangeIntegrationControllerFixture(InMemoryDbContext db)
            {
                RequestQueueItemModel = Substitute.For<IRequestQueueItemModel>();
                RequestQueueItemModel.Get(Arg.Any<ExchangeRequestQueueItem>(), Arg.Any<string>(), Arg.Any<string>()).Returns(new RequestQueueItem());
                CultureResolver = Substitute.For<IPreferredCultureResolver>();
                CryptoService = Substitute.For<ICryptoService>();
                Subject = new ExchangeIntegrationController(db, RequestQueueItemModel, CultureResolver);
            }

            public IRequestQueueItemModel RequestQueueItemModel { get; set; }
            public IPreferredCultureResolver CultureResolver { get; set; }

            public ICryptoService CryptoService { get; set; }

            public ExchangeIntegrationController Subject { get; set; }
        }
    }
}