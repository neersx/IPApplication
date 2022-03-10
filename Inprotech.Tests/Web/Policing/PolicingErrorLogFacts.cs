using System;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Model.Components.Policing;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Policing;
using InprotechKaizen.Model.Policing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Policing
{
    public class PolicingErrorLogFacts
    {
        public class RetrieveMethod : FactBase
        {
            public RetrieveMethod()
            {
                _fixture = new PolicingErrorLogFixture(Db);
            }

            readonly PolicingErrorLogFixture _fixture;
            readonly CommonQueryParameters _parameters = new CommonQueryParameters();

            [Fact]
            public void CallsCommonQueryService()
            {
                var r = _fixture.Subject.Retrieve(_parameters).ToArray();

                Assert.Empty(r);

                _fixture.CommonQueryService.Received(1).Filter(Arg.Any<IQueryable<PolicingErrorLogItem>>(), _parameters);
            }

            [Fact]
            public void ReturnDetails()
            {
                var @case = new CaseBuilder
                {
                    Irn = Fixture.String()
                }.Build().In(Db);

                var @event = new EventBuilder
                {
                    Description = Fixture.String()
                }.Build().In(Db);

                var error = new PolicingError(Fixture.Today(), 1)
                {
                    Case = @case,
                    CaseId = @case.Id,
                    Message = Fixture.String(),
                    EventNo = @event.Id,
                    CycleNo = Fixture.Short()
                }.In(Db);

                var r = _fixture.Subject.Retrieve(_parameters).Single();

                Assert.Equal(error.StartDateTime, r.ErrorDate);
                Assert.Equal(error.ErrorSeqNo, r.ErrorSeq);
                Assert.Equal(error.CaseId, r.CaseId);
                Assert.Equal(error.Case.Irn, r.CaseRef);
                Assert.Equal(@event.Description, r.EventDescription);
                Assert.Equal(error.CycleNo, r.EventCycle);
            }

            [Fact]
            public void ReturnEventControlDetails()
            {
                var @case = new CaseBuilder
                {
                    Irn = Fixture.String()
                }.Build().In(Db);

                var @event = new EventBuilder
                {
                    Description = Fixture.String()
                }.Build().In(Db);

                var criteria = new CriteriaBuilder().Build().In(Db);

                var eventControl = new ValidEventBuilder
                {
                    Description = Fixture.String()
                }.For(criteria, @event).Build().In(Db);

                var error = new PolicingError(Fixture.Today(), 1)
                {
                    Case = @case,
                    CaseId = @case.Id,
                    Message = Fixture.String(),
                    EventNo = @event.Id,
                    CycleNo = Fixture.Short(),
                    CriteriaNo = criteria.Id
                }.In(Db);

                var r = _fixture.Subject.Retrieve(_parameters).Single();

                Assert.Equal(error.StartDateTime, r.ErrorDate);
                Assert.Equal(error.ErrorSeqNo, r.ErrorSeq);
                Assert.Equal(error.CaseId, r.CaseId);
                Assert.Equal(error.Case.Irn, r.CaseRef);
                Assert.Equal(error.CycleNo, r.EventCycle);

                Assert.NotEqual(@event.Description, r.EventDescription);
                Assert.Equal(eventControl.Description, r.EventDescription);
            }

            [Fact]
            public void ReturnsPolicingErrorWithMostRecentFirst()
            {
                var previous = new PolicingErrorBuilder(Db)
                {
                    StartTime = Fixture.PastDate()
                }.Build();

                var current = new PolicingErrorBuilder(Db)
                {
                    StartTime = Fixture.Today()
                }.Build();

                var r = _fixture.Subject.Retrieve(_parameters).ToArray();

                Assert.Equal(current.StartDateTime, r.First().ErrorDate);
                Assert.Equal(previous.StartDateTime, r.Last().ErrorDate);
            }
        }

        public class SetInProgressFlag : FactBase
        {
            public SetInProgressFlag()
            {
                _fixture = new PolicingErrorLogFixture(Db);
            }

            readonly PolicingErrorLogFixture _fixture;

            [Fact]
            public void DoesNotSetInprogressForItemsForNotRunningPolicingRequest()
            {
                _fixture.PolicingRequestLogReader.GetInProgressRequests(Arg.Any<DateTime[]>()).Returns(new[] {Fixture.Monday}.AsQueryable());
                _fixture.PolicingQueue.GetPolicingInQueueItemsInfo().Returns(Enumerable.Empty<PolicingItemInQueue>().AsQueryable());

                var data = new[] {new PolicingErrorLogItem {ErrorDate = Fixture.Tuesday}.In(Db)};
                var result = _fixture.Subject.SetInProgressFlag(data);

                Assert.Equal(InprogressItem.None, result.First().ErrorForInProgressItem);
            }

            [Fact]
            public void DoesNotSetInprogressForItemsNotInPolicingQueue()
            {
                _fixture.PolicingQueue.GetPolicingInQueueItemsInfo(Arg.Any<int[]>())
                        .Returns(new[]
                        {
                            new PolicingItemInQueue {CaseId = 10, Earliest = Fixture.Tuesday}
                        }.AsQueryable());

                var data = new[] {new PolicingErrorLogItem {CaseId = 10, ErrorDate = Fixture.Monday}.In(Db)};
                var result = _fixture.Subject.SetInProgressFlag(data);

                Assert.Equal(InprogressItem.None, result.First().ErrorForInProgressItem);
            }

            [Fact]
            public void SetsInprogressForItemsInPolicingQueue()
            {
                _fixture.PolicingQueue.GetPolicingInQueueItemsInfo(Arg.Any<int[]>())
                        .Returns(new[]
                        {
                            new PolicingItemInQueue {CaseId = 10, Earliest = Fixture.Monday}
                        }.AsQueryable());
                var data = new[] {new PolicingErrorLogItem {CaseId = 10, ErrorDate = Fixture.Tuesday}.In(Db)};
                var result = _fixture.Subject.SetInProgressFlag(data);

                Assert.Equal(InprogressItem.Queue, result.First().ErrorForInProgressItem);
            }

            [Fact]
            public void SetsInprogressForItemsInProgreePolicingRequest()
            {
                _fixture.PolicingRequestLogReader.GetInProgressRequests(Arg.Any<DateTime[]>()).Returns(new[] {Fixture.Monday}.AsQueryable());
                _fixture.PolicingQueue.GetPolicingInQueueItemsInfo().Returns(Enumerable.Empty<PolicingItemInQueue>().AsQueryable());

                var data = new[] {new PolicingErrorLogItem {ErrorDate = Fixture.Monday}.In(Db)};
                var result = _fixture.Subject.SetInProgressFlag(data);

                Assert.Equal(InprogressItem.Request, result.First().ErrorForInProgressItem);
            }
        }

        public class PolicingErrorLogFixture : IFixture<IPolicingErrorLog>
        {
            public PolicingErrorLogFixture(InMemoryDbContext db)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                PolicingQueue = Substitute.For<IPolicingQueue>();

                PolicingRequestLogReader = Substitute.For<IPolicingRequestLogReader>();

                CommonQueryService = Substitute.For<ICommonQueryService>();
                CommonQueryService.Filter(Arg.Any<IQueryable<PolicingErrorLogItem>>(), Arg.Any<CommonQueryParameters>())
                                  .Returns(x => x[0]);

                CommonQueryService.Filter(Arg.Any<IQueryable<PolicingError>>(), Arg.Any<CommonQueryParameters>())
                                  .Returns(x => x[0]);

                Subject = new PolicingErrorLog(db, PreferredCultureResolver, CommonQueryService, PolicingQueue, PolicingRequestLogReader);
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }

            public ICommonQueryService CommonQueryService { get; set; }

            public IPolicingQueue PolicingQueue { get; set; }

            public IPolicingRequestLogReader PolicingRequestLogReader { get; set; }

            public IPolicingErrorLog Subject { get; }
        }
    }
}