using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using Xunit;

namespace Inprotech.Tests.Web.Cases.CriticalDates
{
    public class InterimNextDueEventResolverFacts : FactBase
    {
        public InterimNextDueEventResolverFacts()
        {
            _meta.CaseId = new CaseBuilder().Build().In(Db).Id;
            _meta.ImportanceLevel = 5;
        }

        readonly User _internalUser = new User(Fixture.String(), false);

        readonly CriticalDatesMetadata _meta = new CriticalDatesMetadata();

        (CaseEvent CaseEvent, ValidEvent ValidEvent, OpenAction OpenAction) CreateDueEvent(int? knownEventId = null, string action = null)
        {
            var criteria = new CriteriaBuilder().Build().In(Db);

            var @event = new EventBuilder().Build().In(Db);

            if (knownEventId.HasValue)
            {
                @event.WithKnownId(knownEventId);
            }

            var ve = new ValidEventBuilder
            {
                Criteria = criteria,
                Event = @event,
                ImportanceLevel = "5"
            }.Build().In(Db);

            var oa = new OpenActionBuilder(Db)
            {
                Action = new ActionBuilder
                {
                    Id = action,
                    NumberOfCyclesAllowed = 1
                }.Build().In(Db),
                Case = Db.Set<Case>().Single(),
                Criteria = criteria,
                IsOpen = true,
                Cycle = 1
            }.Build().In(Db);

            var ce = new CaseEvent(_meta.CaseId, ve.EventId, 1).In(Db);
            ce.Event = ve.Event;

            if (knownEventId.HasValue)
            {
                ce.WithKnownId(x => x.EventNo, knownEventId.Value);
            }

            return (ce, ve, oa);
        }

        [Fact]
        public async Task ShouldConsiderEventWhoseControllingActionMatchesOpenAction()
        {
            var d = CreateDueEvent();

            d.CaseEvent.EventDueDate = Fixture.FutureDate();
            d.CaseEvent.IsOccurredFlag = 0;
            d.CaseEvent.Event.ControllingAction = Fixture.String();

            var subject = new InterimNextDueEventResolver(Db);

            Assert.Empty(await subject.Resolve(_internalUser, Fixture.String(), _meta));
        }

        [Fact]
        public async Task ShouldFilterDueEventsAppropriatelyForExternalUser()
        {
            var externalUser = new User(Fixture.String(), true);
            var dueEvent = CreateDueEvent();

            dueEvent.CaseEvent.EventDueDate = Fixture.Today();
            dueEvent.CaseEvent.IsOccurredFlag = 0;

            var subject = new InterimNextDueEventResolver(Db);

            Assert.Empty(await subject.Resolve(externalUser, Fixture.String(), _meta));
        }

        [Fact]
        public async Task ShouldNotConsiderClosedActions()
        {
            var d = CreateDueEvent();

            d.CaseEvent.EventDueDate = Fixture.FutureDate();
            d.CaseEvent.IsOccurredFlag = 0;
            d.OpenAction.PoliceEvents = 0; /* action closed, no longer policed */

            var subject = new InterimNextDueEventResolver(Db);

            Assert.Empty(await subject.Resolve(_internalUser, Fixture.String(), _meta));
        }

        [Fact]
        public async Task ShouldNotConsiderUnimportantEvents()
        {
            var d = CreateDueEvent();

            d.CaseEvent.EventDueDate = Fixture.FutureDate();
            d.CaseEvent.IsOccurredFlag = 0;
            d.ValidEvent.ImportanceLevel = "3";

            var subject = new InterimNextDueEventResolver(Db);

            Assert.Empty(await subject.Resolve(_internalUser, Fixture.String(), _meta));
        }

        [Fact]
        public async Task ShouldNotReturnOccurredEvents()
        {
            var d = CreateDueEvent();

            d.CaseEvent.EventDueDate = Fixture.Today();
            d.CaseEvent.EventDate = Fixture.Today();
            d.CaseEvent.IsOccurredFlag = 1;

            var subject = new InterimNextDueEventResolver(Db);

            Assert.Empty(await subject.Resolve(_internalUser, Fixture.String(), _meta));
        }

        [Fact]
        public async Task ShouldNotReturnRenewalEventIfIncludedInCriticalDateCriteria()
        {
            var d = CreateDueEvent((int) KnownEvents.NextRenewalDate);

            new ValidEventBuilder
            {
                Criteria = new CriteriaBuilder().Build().In(Db).WithKnownId(_meta.CriteriaNo),
                Event = d.CaseEvent.Event,
                ImportanceLevel = "5"
            }.Build().In(Db);

            d.CaseEvent.EventDueDate = Fixture.FutureDate();
            d.CaseEvent.IsOccurredFlag = 0;

            var subject = new InterimNextDueEventResolver(Db);

            Assert.Empty(await subject.Resolve(_internalUser, Fixture.String(), _meta));
        }

        [Fact]
        public async Task ShouldReturnEarliestDueEvent()
        {
            var earlier = CreateDueEvent();
            var later = CreateDueEvent();

            earlier.CaseEvent.EventDueDate = Fixture.Today();
            earlier.CaseEvent.IsOccurredFlag = 0;

            later.CaseEvent.EventDueDate = Fixture.FutureDate();
            later.CaseEvent.IsOccurredFlag = 0;

            var subject = new InterimNextDueEventResolver(Db);

            var nextDue = (await subject.Resolve(_internalUser, Fixture.String(), _meta)).Single();

            Assert.Equal(earlier.CaseEvent.EventNo, nextDue.EventKey);
            Assert.Equal(earlier.CaseEvent.EventDueDate, nextDue.DisplayDate);
        }

        [Fact]
        public async Task ShouldReturnHigherDisplayOrderDueEventIfAllDueOnSameDateAndAreImportant()
        {
            var higherDisplaySequence = CreateDueEvent();
            var lowerDisplaySequence = CreateDueEvent();

            higherDisplaySequence.CaseEvent.EventDueDate = Fixture.Today();
            higherDisplaySequence.CaseEvent.IsOccurredFlag = 0;
            higherDisplaySequence.ValidEvent.DisplaySequence = 9;

            lowerDisplaySequence.CaseEvent.EventDueDate = Fixture.FutureDate();
            lowerDisplaySequence.CaseEvent.IsOccurredFlag = 0;
            lowerDisplaySequence.ValidEvent.DisplaySequence = 6;

            var subject = new InterimNextDueEventResolver(Db);

            var nextDue = (await subject.Resolve(_internalUser, Fixture.String(), _meta)).Single();

            Assert.Equal(higherDisplaySequence.CaseEvent.EventNo, nextDue.EventKey);
            Assert.Equal(higherDisplaySequence.CaseEvent.EventDueDate, nextDue.DisplayDate);
        }

        [Fact]
        public async Task ShouldReturnMostImportantDueEventIfBothDueOnSameDate()
        {
            var moreImportant = CreateDueEvent();
            var lessImportant = CreateDueEvent();

            moreImportant.CaseEvent.EventDueDate = Fixture.Today();
            moreImportant.CaseEvent.IsOccurredFlag = 0;
            moreImportant.ValidEvent.ImportanceLevel = "9";

            lessImportant.CaseEvent.EventDueDate = Fixture.FutureDate();
            lessImportant.CaseEvent.IsOccurredFlag = 0;
            lessImportant.ValidEvent.ImportanceLevel = "7";

            var subject = new InterimNextDueEventResolver(Db);

            var nextDue = (await subject.Resolve(_internalUser, Fixture.String(), _meta)).Single();

            Assert.Equal(moreImportant.CaseEvent.EventNo, nextDue.EventKey);
            Assert.Equal(moreImportant.CaseEvent.EventDueDate, nextDue.DisplayDate);
        }

        [Fact]
        public async Task ShouldReturnNextDueEvent()
        {
            var d = CreateDueEvent();

            d.CaseEvent.EventDueDate = Fixture.FutureDate();
            d.CaseEvent.IsOccurredFlag = 0;

            var subject = new InterimNextDueEventResolver(Db);

            var nextDue = (await subject.Resolve(_internalUser, Fixture.String(), _meta)).Single();

            Assert.Equal("N", nextDue.RowKey);
            Assert.Equal(_meta.CaseId, nextDue.CaseKey);
            Assert.Equal(d.CaseEvent.EventNo, nextDue.EventKey);
            Assert.Equal(d.ValidEvent.Description, nextDue.EventDescription);
            Assert.Equal(d.ValidEvent.Event.Notes, nextDue.EventDefinition);
            Assert.Equal(d.CaseEvent.EventDueDate, nextDue.DisplayDate);
            Assert.Equal(d.ValidEvent.DisplaySequence, nextDue.DisplaySequence);
            Assert.True(nextDue.IsNextDueEvent.GetValueOrDefault());
            Assert.False(nextDue.IsOccurred.GetValueOrDefault());
            Assert.False(nextDue.IsLastOccurredEvent.GetValueOrDefault());
            Assert.False(nextDue.IsCPARenewalDate.GetValueOrDefault());
            Assert.False(nextDue.IsPriorityEvent.GetValueOrDefault());
            Assert.Null(nextDue.OfficialNumber);
            Assert.Null(nextDue.RenewalYear);
            Assert.Null(nextDue.CountryCode);
            Assert.Null(nextDue.CountryKey);
            Assert.Null(nextDue.NumberTypeCode);
        }

        [Fact]
        public async Task ShouldReturnRenewalEventIfNotIncludedInCriticalDateCriteriaAndTheActionIsRenewalAction()
        {
            _meta.RenewalAction = "RN";

            var d = CreateDueEvent((int) KnownEvents.NextRenewalDate, "RN");

            d.CaseEvent.EventDueDate = Fixture.FutureDate();
            d.CaseEvent.IsOccurredFlag = 0;

            var subject = new InterimNextDueEventResolver(Db);

            var nextDue = (await subject.Resolve(_internalUser, Fixture.String(), _meta)).Single();

            Assert.Equal(d.CaseEvent.EventNo, nextDue.EventKey);
            Assert.Equal(d.CaseEvent.EventDueDate, nextDue.DisplayDate);
        }
    }
}