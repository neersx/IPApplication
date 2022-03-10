using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
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
    public class InterimLastOccurredDateResolverFacts : FactBase
    {
        readonly User _internalUser = new User(Fixture.String(), false);

        readonly CriticalDatesMetadata _meta = new CriticalDatesMetadata
        {
            CaseId = Fixture.Integer(),
            ImportanceLevel = 5
        };

        (CaseEvent CaseEvent, ValidEvent ValidEvent) CreateEvent(int? knownEventId = null)
        {
            var ve = new ValidEventBuilder
            {
                Criteria = new CriteriaBuilder().Build().In(Db),
                Event = new EventBuilder().Build().In(Db),
                ImportanceLevel = "5"
            }.Build().In(Db);

            var ce = new CaseEvent(_meta.CaseId, ve.EventId, Fixture.Short())
            {
                CreatedByCriteriaKey = ve.CriteriaId
            }.In(Db);

            if (knownEventId.HasValue)
            {
                ce.WithKnownId(x => x.EventNo, knownEventId.Value);
            }

            return (ce, ve);
        }

        [Theory]
        [InlineData((int) KnownEvents.InstructionsReceivedDateForNewCase)]
        [InlineData((int) KnownEvents.DateOfLastChange)]
        [InlineData((int) KnownEvents.DateOfEntry)]
        public async Task ShouldNotConsiderSpecificEvents(int eventNotConsidered)
        {
            var subject = new InterimLastOccurredDateResolver(Db);

            var a = CreateEvent(eventNotConsidered);

            a.CaseEvent.EventDate = Fixture.Today();

            Assert.Empty(await subject.Resolve(_internalUser, Fixture.String(), _meta));
        }

        [Theory]
        [InlineData(null)]
        [InlineData("4")]
        public async Task ShouldNotConsiderEventOfLowerImportanceFromCreatedByCriteriaConfig(string configuredImportanceLevel)
        {
            var subject = new InterimLastOccurredDateResolver(Db);

            var lessImportant = CreateEvent();
            var moreImportant = CreateEvent();

            lessImportant.CaseEvent.EventDate = Fixture.Today();
            lessImportant.ValidEvent.ImportanceLevel = configuredImportanceLevel;

            moreImportant.CaseEvent.EventDate = Fixture.PastDate();

            var last = (await subject.Resolve(_internalUser, Fixture.String(), _meta)).Single();

            Assert.Equal(moreImportant.CaseEvent.EventNo, last.EventKey);
            Assert.Equal(moreImportant.CaseEvent.EventDate, last.DisplayDate);
        }

        [Fact]
        public async Task ShouldNotReturnForExternalUsers()
        {
            var subject = new InterimLastOccurredDateResolver(Db);

            var a = CreateEvent();

            a.CaseEvent.EventDate = Fixture.Today();

            var externalUser = new User(Fixture.String(), true);

            Assert.Empty(await subject.Resolve(externalUser, Fixture.String(), _meta));
        }

        [Fact]
        public async Task ShouldReturnDateWithHigherDisplaySequenceIfDatesAndImportanceAreTheSame()
        {
            var subject = new InterimLastOccurredDateResolver(Db);

            var higherDisplayPrecedence = CreateEvent();
            var lowerDisplayPrecedence = CreateEvent();

            higherDisplayPrecedence.CaseEvent.LastModified = Fixture.PastDate();
            higherDisplayPrecedence.CaseEvent.EventDate = Fixture.PastDate();
            higherDisplayPrecedence.ValidEvent.ImportanceLevel = "6";
            higherDisplayPrecedence.ValidEvent.DisplaySequence = 3;

            lowerDisplayPrecedence.CaseEvent.LastModified = Fixture.PastDate();
            lowerDisplayPrecedence.CaseEvent.EventDate = Fixture.PastDate();
            lowerDisplayPrecedence.ValidEvent.ImportanceLevel = "6";
            lowerDisplayPrecedence.ValidEvent.DisplaySequence = 2;

            var last = (await subject.Resolve(_internalUser, Fixture.String(), _meta)).Single();

            Assert.Equal(higherDisplayPrecedence.CaseEvent.EventNo, last.EventKey);
            Assert.Equal(higherDisplayPrecedence.CaseEvent.EventDate, last.DisplayDate);
        }

        [Fact]
        public async Task ShouldReturnDateWithLatestEventDateIfLastModifiedIsTheSame()
        {
            var subject = new InterimLastOccurredDateResolver(Db);

            var moreRecent = CreateEvent();
            var lessRecent = CreateEvent();

            moreRecent.CaseEvent.LastModified = Fixture.PastDate();
            moreRecent.CaseEvent.EventDate = Fixture.Today();

            lessRecent.CaseEvent.LastModified = Fixture.PastDate();
            lessRecent.CaseEvent.EventDate = Fixture.PastDate();

            var last = (await subject.Resolve(_internalUser, Fixture.String(), _meta)).Single();

            Assert.Equal(moreRecent.CaseEvent.EventNo, last.EventKey);
            Assert.Equal(moreRecent.CaseEvent.EventDate, last.DisplayDate);
        }

        [Fact]
        public async Task ShouldReturnDateWithLatestLastModifiedDate()
        {
            var subject = new InterimLastOccurredDateResolver(Db);

            var moreRecent = CreateEvent();
            var lessRecent = CreateEvent();

            moreRecent.CaseEvent.LastModified = Fixture.Today();
            moreRecent.CaseEvent.EventDate = Fixture.PastDate();

            lessRecent.CaseEvent.LastModified = Fixture.PastDate();
            lessRecent.CaseEvent.EventDate = Fixture.PastDate();

            var last = (await subject.Resolve(_internalUser, Fixture.String(), _meta)).Single();

            Assert.Equal(moreRecent.CaseEvent.EventNo, last.EventKey);
            Assert.Equal(moreRecent.CaseEvent.EventDate, last.DisplayDate);
        }

        [Fact]
        public async Task ShouldReturnMoreImportantDateIfBothDatesTheSame()
        {
            var subject = new InterimLastOccurredDateResolver(Db);

            var moreImportant = CreateEvent();
            var lessImportant = CreateEvent();

            moreImportant.CaseEvent.LastModified = Fixture.PastDate();
            moreImportant.CaseEvent.EventDate = Fixture.PastDate();
            moreImportant.ValidEvent.ImportanceLevel = "7";

            lessImportant.CaseEvent.LastModified = Fixture.PastDate();
            lessImportant.CaseEvent.EventDate = Fixture.PastDate();
            lessImportant.ValidEvent.ImportanceLevel = "6";

            var last = (await subject.Resolve(_internalUser, Fixture.String(), _meta)).Single();

            Assert.Equal(moreImportant.CaseEvent.EventNo, last.EventKey);
            Assert.Equal(moreImportant.CaseEvent.EventDate, last.DisplayDate);
        }

        [Fact]
        public async Task ShouldReturnTheLastOccurredDate()
        {
            var subject = new InterimLastOccurredDateResolver(Db);

            var later = CreateEvent();
            var older = CreateEvent();

            later.CaseEvent.EventDate = Fixture.Today();
            older.CaseEvent.EventDate = Fixture.PastDate();

            var last = (await subject.Resolve(_internalUser, Fixture.String(), _meta)).Single();

            Assert.Equal("L", last.RowKey);
            Assert.Equal(_meta.CaseId, last.CaseKey);
            Assert.Equal(later.CaseEvent.EventNo, last.EventKey);
            Assert.Equal(later.ValidEvent.Description, last.EventDescription);
            Assert.Equal(later.ValidEvent.Event.Notes, last.EventDefinition);
            Assert.Equal(later.CaseEvent.EventDate, last.DisplayDate);
            Assert.Equal(later.ValidEvent.DisplaySequence, last.DisplaySequence);
            Assert.True(last.IsOccurred.GetValueOrDefault());
            Assert.True(last.IsLastOccurredEvent.GetValueOrDefault());
            Assert.False(last.IsNextDueEvent.GetValueOrDefault());
            Assert.False(last.IsCPARenewalDate.GetValueOrDefault());
            Assert.False(last.IsPriorityEvent.GetValueOrDefault());
            Assert.Null(last.OfficialNumber);
            Assert.Null(last.RenewalYear);
            Assert.Null(last.CountryCode);
            Assert.Null(last.CountryKey);
            Assert.Null(last.NumberTypeCode);
        }
    }
}