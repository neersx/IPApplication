using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Integration.AutomaticDocketing;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.Cases.Comparison.Updaters;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Tests.Integration.AutomaticDocketing
{
    public class ApplyUpdatesFacts
    {
        public class FromMethod : FactBase
        {
            public FromMethod()
            {
                _case = new CaseBuilder().Build().In(Db);
            }

            readonly Case _case;

            readonly Event[] _singleEvent =
            {
                new Event
                {
                    EventNo = 1,
                    Cycle = 1,
                    EventDate = new Value<DateTime?>
                    {
                        TheirValue = Fixture.Today()
                    },
                    Sequence = 1
                }
            };

            readonly Event[] _cyclicEvents =
            {
                new Event
                {
                    EventNo = 1,
                    Cycle = 1,
                    EventDate = new Value<DateTime?>
                    {
                        TheirValue = Fixture.PastDate()
                    },
                    Sequence = 1
                },
                new Event
                {
                    EventNo = 1,
                    Cycle = 2,
                    EventDate = new Value<DateTime?>
                    {
                        TheirValue = Fixture.Today()
                    },
                    Sequence = 1
                }
            };

            [Fact]
            public void AppliesComparisonEvent()
            {
                var f = new ApplyUpdatesFixture(Db);

                f.Subject.From(_singleEvent, _case.Id);

                f.CaseComparisonEvent.Received(1).Apply(_case);
            }

            [Fact]
            public void AvoidsRecordingTransactionReason()
            {
                var f = new ApplyUpdatesFixture(Db);

                var reasonCode = Fixture.Integer();

                f.SiteConfiguration.TransactionReason.Returns(false);

                f.SiteConfiguration.ReasonIpOfficeVerification.Returns(reasonCode);

                f.Subject.From(_singleEvent, _case.Id);

                f.TransactionRecordal
                 .DidNotReceive()
                 .RecordTransactionFor(_case, CaseTransactionMessageIdentifier.AmendedCase, reasonCode);
            }

            [Fact]
            public void CallsPolicingWhenPoliceImmediate()
            {
                var f = new ApplyUpdatesFixture(Db);

                f.BatchPolicingRequest.ShouldPoliceImmediately().ReturnsForAnyArgs(true);
                f.BatchPolicingRequest.Enqueue(Arg.Any<IEnumerable<IQueuedPolicingRequest>>()).ReturnsForAnyArgs(888);

                f.Subject.From(_singleEvent, _case.Id);

                f.BatchPolicingRequest.Received(1).Enqueue(Arg.Any<IEnumerable<IQueuedPolicingRequest>>());
                f.PolicingEngine.Received(1).PoliceAsync(888);
            }

            [Fact]
            public void DoesNotCallPolicingWhenNotPoliceImmediate()
            {
                var f = new ApplyUpdatesFixture(Db);

                f.BatchPolicingRequest.ShouldPoliceImmediately().ReturnsForAnyArgs(false);

                f.Subject.From(_singleEvent, _case.Id);

                f.BatchPolicingRequest.Received(1).Enqueue(Arg.Any<IEnumerable<IQueuedPolicingRequest>>());
                f.PolicingEngine.DidNotReceive().PoliceAsync(Arg.Any<int>());
                f.PolicingEngine.DidNotReceive().Police(Arg.Any<int?>());
            }

            [Fact]
            public void RecordsTheTransaction()
            {
                var f = new ApplyUpdatesFixture(Db);

                f.Subject.From(_singleEvent, _case.Id);

                f.TransactionRecordal
                 .Received(1)
                 .RecordTransactionFor(_case, CaseTransactionMessageIdentifier.AmendedCase,
                                       Arg.Any<int?>());
            }

            [Fact]
            public void RecordsTheTransactionWithReason()
            {
                var f = new ApplyUpdatesFixture(Db);

                var reasonCode = Fixture.Integer();

                f.SiteConfiguration.TransactionReason.Returns(true);

                f.SiteConfiguration.ReasonIpOfficeVerification.Returns(reasonCode);

                f.Subject.From(_singleEvent, _case.Id);

                f.TransactionRecordal
                 .Received(1)
                 .RecordTransactionFor(_case, CaseTransactionMessageIdentifier.AmendedCase, reasonCode);
            }

            [Fact]
            public void ReturnsUpdatedEvents()
            {
                var f = new ApplyUpdatesFixture(Db);

                var r = f.Subject.From(_singleEvent, _case.Id).Single();

                var e = _singleEvent.Single();

                Assert.Equal(r.EventNo, e.EventNo);

                Assert.Equal(r.Cycle, e.Cycle);
            }

            [Fact]
            public void UpdatesEvents()
            {
                var f = new ApplyUpdatesFixture(Db);

                f.Subject.From(_singleEvent, _case.Id);

                f.EventUpdater.Received(1)
                 .AddOrUpdateEvents(_case, Arg.Is<IEnumerable<Event>>(_ => _.SequenceEqual(_singleEvent)));
            }

            [Fact]
            public void UpdatesMultipleEvents()
            {
                var f = new ApplyUpdatesFixture(Db);

                var r = f.Subject.From(_cyclicEvents, _case.Id).ToArray();

                f.EventUpdater.Received(1)
                 .AddOrUpdateEvents(_case, Arg.Is<IEnumerable<Event>>(_ => _.SequenceEqual(_cyclicEvents)));

                Assert.Equal(r.First().Cycle, (short) 1);

                Assert.Equal(r.Last().Cycle, (short) 2);
            }
        }

        public class ApplyUpdatesFixture : IFixture<ApplyUpdates>
        {
            public ApplyUpdatesFixture(InMemoryDbContext db)
            {
                SiteConfiguration = Substitute.For<ISiteConfiguration>();

                TransactionRecordal = Substitute.For<ITransactionRecordal>();

                PolicingEngine = Substitute.For<IPolicingEngine>();

                BatchPolicingRequest = Substitute.For<IBatchPolicingRequest>();

                EventUpdater = Substitute.For<IEventUpdater>();
                EventUpdater.AddOrUpdateEvents(Arg.Any<Case>(), Arg.Any<IEnumerable<Event>>())
                            .Returns(
                                     x =>
                                     {
                                         var c = (Case) x[0];
                                         var r = new List<PoliceCaseEvent>();
                                         foreach (var e in (IEnumerable<Event>) x[1])
                                         {
                                             r.Add(new PoliceCaseEvent(new CaseEventBuilder
                                             {
                                                 CaseId = c.Id,
                                                 Cycle = e.Cycle,
                                                 EventNo = e.EventNo,
                                                 EventDate = e.EventDate.TheirValue
                                             }.Build()));
                                         }

                                         return r;
                                     });

                CaseComparisonEvent = Substitute.For<ICaseComparisonEvent>();
                ComponentResolver = Substitute.For<IComponentResolver>();

                Subject = new ApplyUpdates(
                                           db, SiteConfiguration, TransactionRecordal, PolicingEngine, EventUpdater,
                                           CaseComparisonEvent, BatchPolicingRequest, ComponentResolver);
            }

            public ISiteConfiguration SiteConfiguration { get; set; }

            public ITransactionRecordal TransactionRecordal { get; set; }

            public IPolicingEngine PolicingEngine { get; set; }

            public IEventUpdater EventUpdater { get; set; }

            public ICaseComparisonEvent CaseComparisonEvent { get; set; }

            public IBatchPolicingRequest BatchPolicingRequest { get; set; }

            public IComponentResolver ComponentResolver { get; set; }

            public ApplyUpdates Subject { get; set; }
        }
    }
}