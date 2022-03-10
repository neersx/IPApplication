using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Model.Components.Cases.Comparison.Updaters;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.Cases.Comparison.Updaters;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Components.Cases.Comparison.Results.Case;
using CaseName = InprotechKaizen.Model.Components.Cases.Comparison.Results.CaseName;
using GoodsServices = InprotechKaizen.Model.Components.Cases.Comparison.Results.GoodsServices;
using OfficialNumber = InprotechKaizen.Model.Components.Cases.Comparison.Results.OfficialNumber;

#pragma warning disable 4014

namespace Inprotech.Tests.Model.Components.Cases.Comparison
{
    public class ComparisonUpdaterFacts
    {
        public class ApplyMethod : FactBase
        {
            readonly CaseComparisonSave _caseComparisonSave = new CaseComparisonSave
            {
                Case = new Case(),
                Events = new Event[0],
                OfficialNumbers = new OfficialNumber[0],
                GoodsServices = new GoodsServices[0],
                CaseNames = new CaseName[0]
            };

            [Fact]
            public void AddsCaseComparisonEvent()
            {
                var f = new ComparisonUpdaterFixture(Db);

                _caseComparisonSave.CaseId = f.Case.Id;

                f.Subject.ApplyChanges(_caseComparisonSave);

                f.CaseComparisonEvent.Received(1).Apply(f.Case);
            }

            [Fact]
            public void CallsPolicingWhenPoliceImmediate()
            {
                var f = new ComparisonUpdaterFixture(Db);

                f.BatchPolicingRequest.ShouldPoliceImmediately().ReturnsForAnyArgs(true);
                f.BatchPolicingRequest.Enqueue(Arg.Any<IEnumerable<IQueuedPolicingRequest>>()).ReturnsForAnyArgs(888);

                _caseComparisonSave.CaseId = f.Case.Id;

                f.Subject.ApplyChanges(_caseComparisonSave);

                f.BatchPolicingRequest.Received(1).Enqueue(Arg.Any<IEnumerable<IQueuedPolicingRequest>>());
                f.PolicingEngine.Received(1).PoliceAsync(888);
            }

            [Fact]
            public void DoesNotCallPolicingWhenNotPoliceImmediate()
            {
                var f = new ComparisonUpdaterFixture(Db);

                f.BatchPolicingRequest.ShouldPoliceImmediately().ReturnsForAnyArgs(false);

                _caseComparisonSave.CaseId = f.Case.Id;

                f.Subject.ApplyChanges(_caseComparisonSave);

                f.BatchPolicingRequest.Received(1).Enqueue(Arg.Any<IEnumerable<IQueuedPolicingRequest>>());
                f.PolicingEngine.DidNotReceive().PoliceAsync(Arg.Any<int>());
                f.PolicingEngine.DidNotReceive().Police(Arg.Any<int?>());
            }

            [Fact]
            public void EnqueuesPolicingRequestsForOfficialNumberEventsAndCaseEvents()
            {
                var f = new ComparisonUpdaterFixture(Db);

                var officialNumberEvent1 = new CaseEvent(f.Case.Id, -4, 1);
                var officialNumberEvent2 = new CaseEvent(f.Case.Id, -3, 2);
                var caseEvent1 = new CaseEvent(f.Case.Id, -2, 3);
                var caseEvent2 = new CaseEvent(f.Case.Id, -1, 4);

                f.OfficialNumberUpdater.AddOrUpdateOfficialNumbers(Arg.Any<InprotechKaizen.Model.Cases.Case>(),
                                                                   Arg.Any<IEnumerable<OfficialNumber>>())
                 .Returns(new[]
                              {
                                    new PoliceCaseEvent(officialNumberEvent1), new PoliceCaseEvent(officialNumberEvent2)
                              });

                f.EventsUpdater.AddOrUpdateEvents(Arg.Any<InprotechKaizen.Model.Cases.Case>(),
                                                  Arg.Any<IEnumerable<Event>>())
                 .Returns(new[] {new PoliceCaseEvent(caseEvent1), new PoliceCaseEvent(caseEvent2)});

                _caseComparisonSave.CaseId = f.Case.Id;
                _caseComparisonSave.OfficialNumbers = new[] {new OfficialNumber()};
                _caseComparisonSave.Events = new[] {new Event()};

                f.Subject.ApplyChanges(_caseComparisonSave);

                f.OfficialNumberUpdater.Received(1)
                 .AddOrUpdateOfficialNumbers(f.Case, _caseComparisonSave.OfficialNumbers);
                f.EventsUpdater.Received(1)
                 .AddOrUpdateEvents(f.Case, Arg.Is<IEnumerable<Event>>(
                                                                       _ => _.Count() == _caseComparisonSave.Events.Count()));

                f.BatchPolicingRequest.Received(1).Enqueue(Arg.Any<IEnumerable<IQueuedPolicingRequest>>());
            }

            [Fact]
            public void SavesCaseDetailsForTitle()
            {
                var f = new ComparisonUpdaterFixture(Db);

                _caseComparisonSave.CaseId = f.Case.Id;
                _caseComparisonSave.Case = new Case
                {
                    CaseId = f.Case.Id,
                    Title = new Value<string>().AsUpdatedValue("A", "B")
                };

                f.Subject.ApplyChanges(_caseComparisonSave);

                f.CaseUpdater.Received(1).UpdateTitle(f.Case, _caseComparisonSave.Case);
            }

            [Fact]
            public void SavesCaseDetailsForTypeOfMark()
            {
                var f = new ComparisonUpdaterFixture(Db);

                _caseComparisonSave.CaseId = f.Case.Id;
                _caseComparisonSave.Case = new Case
                {
                    CaseId = f.Case.Id,
                    TypeOfMark = new Value<string>().AsUpdatedValue(null, "5102")
                };

                f.Subject.ApplyChanges(_caseComparisonSave);

                f.CaseUpdater.Received(1).UpdateTypeOfMark(f.Case, _caseComparisonSave.Case);
            }

            [Fact]
            public void SavesCaseNameUpdates()
            {
                var f = new ComparisonUpdaterFixture(Db);

                var name = new CaseName
                {
                    Reference = new Value<string>().AsUpdatedValue("12345", "9999")
                };

                _caseComparisonSave.CaseId = f.Case.Id;
                _caseComparisonSave.CaseNames = new[] {name};

                f.Subject.ApplyChanges(_caseComparisonSave);

                f.CaseNameUpdator.Received(1).UpdateNameReferences(f.Case,
                                                                   Arg.Is<IEnumerable<CaseName>>(_ => _.Count() == _caseComparisonSave.CaseNames.Count()));
            }

            [Fact]
            public void SavesChanges()
            {
                var f = new ComparisonUpdaterFixture(Db);

                _caseComparisonSave.CaseId = f.Case.Id;

                f.Subject.ApplyChanges(_caseComparisonSave);

                Db.Received(1).SaveChanges();
            }

            [Fact]
            public void SavesEventDetails()
            {
                var f = new ComparisonUpdaterFixture(Db);

                var comparedEvents = new Event
                {
                    EventNo = 1,
                    EventDate = new Value<DateTime?>().AsUpdatedValue(Fixture.PastDate(), Fixture.Today())
                };

                _caseComparisonSave.CaseId = f.Case.Id;
                _caseComparisonSave.Events = new[] {comparedEvents};

                f.Subject.ApplyChanges(_caseComparisonSave);

                f.EventsUpdater.Received(1).AddOrUpdateEvents(f.Case,
                                                              Arg.Is<IEnumerable<Event>>(_ => _.Count() == _caseComparisonSave.Events.Count()));
            }

            [Fact]
            public void SavesGoodsAndServicesDetails()
            {
                var f = new ComparisonUpdaterFixture(Db);

                var comparedGoodsAndServices = new GoodsServices
                {
                    TextNo = 1,
                    TextType = "G",
                    Text = new Value<string>().AsUpdatedValue("A", "B")
                };

                _caseComparisonSave.CaseId = f.Case.Id;
                _caseComparisonSave.GoodsServices = new[] {comparedGoodsAndServices};

                f.Subject.ApplyChanges(_caseComparisonSave);

                f.GoodsServicesUpdater.Received(1).Update(f.Case, _caseComparisonSave.GoodsServices);
            }

            [Fact]
            public void SavesOfficialNumberDetails()
            {
                var f = new ComparisonUpdaterFixture(Db);

                var comparedOfficialNumber = new OfficialNumber
                {
                    Id = 1,
                    Number = new Value<string>().AsUpdatedValue("A", "B"),
                    EventDate = new Value<DateTime?>().AsUpdatedValue(null, Fixture.PastDate())
                };

                _caseComparisonSave.CaseId = f.Case.Id;
                _caseComparisonSave.OfficialNumbers = new[] {comparedOfficialNumber};

                f.Subject.ApplyChanges(_caseComparisonSave);

                f.OfficialNumberUpdater.Received(1)
                 .AddOrUpdateOfficialNumbers(f.Case, _caseComparisonSave.OfficialNumbers);
            }

            [Fact]
            public void TransactionReasonIsNotSet()
            {
                var f = new ComparisonUpdaterFixture(Db);

                _caseComparisonSave.CaseId = f.Case.Id;

                f.Subject.ApplyChanges(_caseComparisonSave);

                f.TransactionRecordal.Received(1)
                 .RecordTransactionFor(Arg.Any<InprotechKaizen.Model.Cases.Case>(), Arg.Is(CaseTransactionMessageIdentifier.AmendedCase), Arg.Is((int?) null));
            }

            [Fact]
            public void TransactionReasonIsSet()
            {
                var f = new ComparisonUpdaterFixture(Db)
                    .WithTransactionReason(true);

                _caseComparisonSave.CaseId = f.Case.Id;

                f.Subject.ApplyChanges(_caseComparisonSave);

                f.TransactionRecordal.Received(1)
                 .RecordTransactionFor(Arg.Any<InprotechKaizen.Model.Cases.Case>(), Arg.Is(CaseTransactionMessageIdentifier.AmendedCase), Arg.Is(-1));
            }
        }

        public class ComparisonUpdaterFixture : IFixture<ComparisonUpdater>
        {
            public ComparisonUpdaterFixture(InMemoryDbContext db)
            {
                CaseUpdater = Substitute.For<ICaseUpdater>();
                OfficialNumberUpdater = Substitute.For<IOfficialNumberUpdater>();
                GoodsServicesUpdater = Substitute.For<IGoodsServicesUpdater>();
                EventsUpdater = Substitute.For<IEventUpdater>();
                CaseComparisonEvent = Substitute.For<ICaseComparisonEvent>();
                PolicingEngine = Substitute.For<IPolicingEngine>();
                TransactionRecordal = Substitute.For<ITransactionRecordal>();
                SiteConfiguration = Substitute.For<ISiteConfiguration>();
                CaseImageImporter = Substitute.For<IImportCaseImages>();
                BatchPolicingRequest = Substitute.For<IBatchPolicingRequest>();
                CaseNameUpdator = Substitute.For<ICaseNameUpdator>();
                ComponentResolver = Substitute.For<IComponentResolver>();

                Case = new CaseBuilder().Build().In(db);

                Subject = new ComparisonUpdater(db, CaseUpdater, OfficialNumberUpdater,
                                                GoodsServicesUpdater, EventsUpdater,
                                                PolicingEngine, TransactionRecordal, SiteConfiguration, CaseComparisonEvent, CaseImageImporter,
                                                BatchPolicingRequest, CaseNameUpdator, ComponentResolver);

                WithTransactionReason();
            }

            public IOfficialNumberUpdater OfficialNumberUpdater { get; set; }

            public ICaseUpdater CaseUpdater { get; set; }

            public IGoodsServicesUpdater GoodsServicesUpdater { get; set; }

            public IEventUpdater EventsUpdater { get; set; }

            public ICaseComparisonEvent CaseComparisonEvent { get; set; }

            public IPolicingEngine PolicingEngine { get; set; }

            public ITransactionRecordal TransactionRecordal { get; }

            public ISiteConfiguration SiteConfiguration { get; }

            public InprotechKaizen.Model.Cases.Case Case { get; }

            public IImportCaseImages CaseImageImporter { get; }

            public IBatchPolicingRequest BatchPolicingRequest { get; set; }

            public ICaseNameUpdator CaseNameUpdator { get; set; }

            public IComponentResolver ComponentResolver { get; set; }

            public ComparisonUpdater Subject { get; }

            public ComparisonUpdaterFixture WithTransactionReason(bool value = false)
            {
                SiteConfiguration.TransactionReason.Returns(value);

                if (value)
                {
                    SiteConfiguration.ReasonIpOfficeVerification.Returns(-1);
                }

                return this;
            }
        }
    }
}