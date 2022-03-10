using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.CriticalDates
{
    public class InterimCriticalDatesResolverFacts : FactBase
    {
        public InterimCriticalDatesResolverFacts()
        {
            _culture = Fixture.String();
            _internalUser = new User(Fixture.String(), false);
            _externalUser = new User(Fixture.String(), true);
            _criticalDateCriteria = new CriteriaBuilder().Build().In(Db);
            _meta.CriteriaNo = _criticalDateCriteria.Id;
            _meta.CaseId = Fixture.Integer();
            _meta.CaseRef = Fixture.String();
            _meta.ImportanceLevel = 5;
        }

        readonly INumberForEventResolver _numberForEventResolver = Substitute.For<INumberForEventResolver>();
        readonly IExternalPatentInfoLinkResolver _externalPatentInfoLinkResolver = Substitute.For<IExternalPatentInfoLinkResolver>();

        readonly User _internalUser;
        readonly User _externalUser;
        readonly string _culture;
        readonly Criteria _criticalDateCriteria;
        readonly CriticalDatesMetadata _meta = new CriticalDatesMetadata();

        (CaseEvent CaseEvent, ValidEvent ValidEvent) CreateEvent(Event @event = null, short cycle = 1, bool availableForExternalUser = true)
        {
            var ve = @event != null
                ? Db.Set<ValidEvent>().SingleOrDefault(_ => _.CriteriaId == _criticalDateCriteria.Id && _.EventId == @event.Id)
                : null;

            ve = ve ?? new ValidEventBuilder
            {
                Criteria = _criticalDateCriteria,
                Event = @event ?? new EventBuilder().Build().In(Db),
                ImportanceLevel = "5"
            }.Build().In(Db);

            var ce = new CaseEvent(_meta.CaseId, ve.EventId, cycle).In(Db);

            if (availableForExternalUser && !Db.Set<FilteredUserEvent>().Any(_ => _.EventNo == ve.EventId))
            {
                new FilteredUserEvent
                {
                    EventNo = ve.Event.Id,
                    EventCode = ve.Event.Code,
                    EventDescription = ve.Event.Description,
                    ImportanceLevel = ve.Event.ImportanceLevel,
                    ControllingAction = ve.Event.ControllingAction,
                    Definition = ve.Event.Notes,
                    NumCyclesAllowed = ve.Event.NumberOfCyclesAllowed
                }.In(Db);
            }

            return (ce, ve);
        }

        (CaseDueDate DueDate, CaseEvent CaseEvent, ValidEvent ValidEvent) CreateDueDate(Event @event = null, short cycle = 1, bool availableForExternalUser = true)
        {
            var eventForTesting = CreateEvent(@event, cycle, availableForExternalUser);

            var dueDate = new CaseDueDate
            {
                CaseId = _meta.CaseId,
                EventNo = eventForTesting.ValidEvent.EventId,
                Cycle = cycle
            }.In(Db);

            return (dueDate, eventForTesting.CaseEvent, eventForTesting.ValidEvent);
        }

        InterimCriticalDatesResolver CreateSubject(params OfficialNumberForEvent[] numbers)
        {
            _numberForEventResolver.Resolve(_meta.CaseId).Returns(numbers.AsQueryable());

            return new InterimCriticalDatesResolver(Db, _numberForEventResolver, _externalPatentInfoLinkResolver);
        }

        [Theory]
        [InlineData(true, true, "'Client unaware of CPA' site control exists and set true")]
        [InlineData(true, false, "'Client unaware of CPA' site control exists and set false")]
        [InlineData(false, null, "'Client unaware of CPA' site control does not exists")]
#pragma warning disable xUnit1026
        public async Task ShouldReturnCpaRenewalDateForInternalUsers(bool createSiteControl, bool? siteControlValue, string reason)
#pragma warning restore xUnit1026
        {
            _meta.CpaRenewalDate = Fixture.FutureDate();

            if (createSiteControl) new SiteControl(SiteControls.ClientsUnawareofCPA) {BooleanValue = siteControlValue}.In(Db);

            var renewalDate = CreateEvent(new EventBuilder().Build().In(Db).WithKnownId(x => x.Id, (int) KnownEvents.NextRenewalDate));

            var subject = CreateSubject();

            var r = (await subject.Resolve(_internalUser, _culture, _meta)).Single();

            Assert.True(r.IsCPARenewalDate.GetValueOrDefault());

            Assert.Equal(renewalDate.ValidEvent.Description, r.EventDescription);
            Assert.Equal(renewalDate.ValidEvent.Event.Notes, r.EventDefinition);
            Assert.Equal(_meta.CpaRenewalDate, r.DisplayDate);
            Assert.False(r.IsOccurred.GetValueOrDefault());
        }

        [Theory]
        [InlineData(true, "'Client unaware of CPA' site control exists and set false")]
        [InlineData(false, "'Client unaware of CPA' site control does not exists")]
#pragma warning disable xUnit1026
        public async Task ShouldIndicateRenewalDateIsCpaIfNotExplicitlySetUnawareForExternalUser(bool createSiteControl, string reason)
#pragma warning restore xUnit1026
        {
            _meta.CpaRenewalDate = Fixture.FutureDate();

            if (createSiteControl) new SiteControl(SiteControls.ClientsUnawareofCPA) {BooleanValue = false}.In(Db);

            var renewalDate = CreateEvent(new EventBuilder().Build().In(Db).WithKnownId(x => x.Id, (int) KnownEvents.NextRenewalDate));

            var subject = CreateSubject();

            var r = (await subject.Resolve(_externalUser, _culture, _meta)).Single();

            Assert.True(r.IsCPARenewalDate.GetValueOrDefault());

            Assert.Equal(renewalDate.ValidEvent.Description, r.EventDescription);
            Assert.Equal(renewalDate.ValidEvent.Event.Notes, r.EventDefinition);
            Assert.Equal(_meta.CpaRenewalDate, r.DisplayDate);
            Assert.False(r.IsOccurred.GetValueOrDefault());
        }

        [Fact]
        public async Task ShouldIndicatePriorityEventFromDefaultPriorityEventForInternalUsers()
        {
            _meta.DefaultPriorityEventNo = (int) KnownEvents.ApplicationFilingDate;

            CreateEvent(new EventBuilder().Build().In(Db).WithKnownId(x => x.Id, _meta.DefaultPriorityEventNo));

            var subject = CreateSubject();

            var r = (await subject.Resolve(_internalUser, _culture, _meta)).Single();

            Assert.True(r.IsPriorityEvent.GetValueOrDefault());
        }

        [Fact]
        public async Task ShouldNotIndicateRenewalDateIsCpaIfExplicitlySetUnawareForExternalUser()
        {
            _meta.CpaRenewalDate = Fixture.FutureDate();

            new SiteControl(SiteControls.ClientsUnawareofCPA)
            {
                BooleanValue = true
            }.In(Db);

            var renewalDate = CreateEvent(new EventBuilder().Build().In(Db).WithKnownId(x => x.Id, (int) KnownEvents.NextRenewalDate));

            var subject = CreateSubject();

            var r = (await subject.Resolve(_externalUser, _culture, _meta)).Single();

            Assert.False(r.IsCPARenewalDate.GetValueOrDefault());

            Assert.Equal(renewalDate.ValidEvent.Description, r.EventDescription);
            Assert.Equal(renewalDate.ValidEvent.Event.Notes, r.EventDefinition);
            Assert.Equal(_meta.CpaRenewalDate, r.DisplayDate);
            Assert.False(r.IsOccurred.GetValueOrDefault());
        }

        [Fact]
        public async Task ShouldNotReturnEventsNotAvailableToExternalUsers()
        {
            var criticalDate1 = CreateDueDate(availableForExternalUser: false);
            var criticalDate2 = CreateEvent(availableForExternalUser: false);

            criticalDate1.CaseEvent.EventDate = Fixture.PastDate();
            criticalDate2.CaseEvent.EventDueDate = Fixture.FutureDate();

            var subject = CreateSubject();

            Assert.Empty(await subject.Resolve(_externalUser, _culture, _meta));
        }

        [Fact]
        public async Task ShouldReturnDerivedExternalLinkForEachDateHavingExternalInfoDataItemId()
        {
            var @event = CreateEvent();
            var numberType = Fixture.String();
            var number = Fixture.String();
            var docItemId = Fixture.Integer();

            var resolvedLink = new Uri("https://innography.com");

            @event.CaseEvent.EventDate = Fixture.PastDate();

            _externalPatentInfoLinkResolver.Resolve(_meta.CaseRef, docItemId, out var externalLink)
                                           .Returns(x =>
                                           {
                                               x[2] = resolvedLink;
                                               return true;
                                           });

            var subject = CreateSubject(new OfficialNumberForEvent
            {
                EventNo = @event.CaseEvent.EventNo,
                NumberType = numberType,
                OfficialNumber = number,
                DataItemId = docItemId
            });

            var r = (await subject.Resolve(_internalUser, _culture, _meta)).Single();

            Assert.Equal(resolvedLink, r.ExternalPatentInfoUri);
        }

        [Fact]
        public async Task ShouldReturnDerivedExternalLinkForPriorityEvent()
        {
            _meta.PriorityEventNo = (int) KnownEvents.EarliestPriority;
            _meta.EarliestPriorityDate = Fixture.PastDate();
            _meta.EarliestPriorityNumber = Fixture.String();
            _meta.EarliestPriorityCountry = Fixture.String("Priority Country");
            _meta.EarliestPriorityCountryId = Fixture.String("Priority Country Code");
            _meta.ExternalPatentInfoUriForPriorityEvent = new Uri("https://innography.com");

            var priorityDate = CreateEvent(new EventBuilder().Build().In(Db).WithKnownId(x => x.Id, _meta.PriorityEventNo));
            priorityDate.CaseEvent.EventDate = Fixture.PastDate();

            var subject = CreateSubject();

            var r = (await subject.Resolve(_internalUser, _culture, _meta)).Single();

            Assert.Equal(_meta.ExternalPatentInfoUriForPriorityEvent, r.ExternalPatentInfoUri);
        }

        [Fact]
        public async Task ShouldReturnDueDateOfLowestCycleBelongingToCriticalDatesCriteria()
        {
            var @event = new EventBuilder().Build().In(Db);

            var cycle1DueDate = CreateDueDate(@event, 1);
            var cycle2DueDate = CreateDueDate(@event, 2);

            cycle1DueDate.CaseEvent.EventDueDate = Fixture.PastDate();
            cycle2DueDate.CaseEvent.EventDueDate = Fixture.Today();

            var subject = CreateSubject();

            var r = (await subject.Resolve(_internalUser, _culture, _meta)).Single();

            Assert.Equal(cycle1DueDate.ValidEvent.Description, r.EventDescription);
            Assert.Equal(cycle1DueDate.ValidEvent.Event.Notes, r.EventDefinition);
            Assert.Equal(cycle1DueDate.CaseEvent.EventDueDate, r.DisplayDate);
            Assert.False(r.IsOccurred.GetValueOrDefault());
        }

        [Fact]
        public async Task ShouldReturnNextRenewalDate()
        {
            _meta.NextRenewalDate = Fixture.FutureDate();

            var renewalDate = CreateEvent(new EventBuilder().Build().In(Db).WithKnownId(x => x.Id, (int) KnownEvents.NextRenewalDate));

            var subject = CreateSubject();

            var r = (await subject.Resolve(_externalUser, _culture, _meta)).Single();

            Assert.False(r.IsCPARenewalDate.GetValueOrDefault());

            Assert.Equal(renewalDate.ValidEvent.Description, r.EventDescription);
            Assert.Equal(renewalDate.ValidEvent.Event.Notes, r.EventDefinition);
            Assert.Equal(_meta.NextRenewalDate, r.DisplayDate);
            Assert.False(r.IsOccurred.GetValueOrDefault());
        }

        [Fact]
        public async Task ShouldReturnOccurredDateBelongingToCriticalDatesCriteria()
        {
            var criticalDate1 = CreateEvent();
            var criticalDate2 = CreateEvent();

            criticalDate1.CaseEvent.EventDate = Fixture.PastDate();
            criticalDate2.CaseEvent.EventDate = Fixture.Today();

            var subject = CreateSubject();

            var r = (await subject.Resolve(_internalUser, _culture, _meta)).ToArray();

            Assert.Equal(criticalDate1.ValidEvent.Description, r.First().EventDescription);
            Assert.Equal(criticalDate1.ValidEvent.Event.Notes, r.First().EventDefinition);
            Assert.Equal(criticalDate1.CaseEvent.EventDate, r.First().DisplayDate);
            Assert.False(r.First().IsOccurred.GetValueOrDefault());

            Assert.Equal(criticalDate2.ValidEvent.Description, r.Last().EventDescription);
            Assert.Equal(criticalDate2.ValidEvent.Event.Notes, r.Last().EventDefinition);
            Assert.Equal(criticalDate2.CaseEvent.EventDate, r.Last().DisplayDate);
            Assert.False(r.Last().IsOccurred.GetValueOrDefault());
        }

        [Fact]
        public async Task ShouldReturnOccurredDateOfHighestCycleBelongingToCriticalDatesCriteria()
        {
            var @event = new EventBuilder().Build().In(Db);

            var cycle1Event = CreateEvent(@event, 1);
            var cycle2Event = CreateEvent(@event, 2);

            cycle1Event.CaseEvent.EventDate = Fixture.PastDate();
            cycle2Event.CaseEvent.EventDate = Fixture.Today();

            var subject = CreateSubject();

            var r = (await subject.Resolve(_internalUser, _culture, _meta)).Single();

            Assert.Equal(cycle2Event.ValidEvent.Description, r.EventDescription);
            Assert.Equal(cycle2Event.ValidEvent.Event.Notes, r.EventDefinition);
            Assert.Equal(cycle2Event.CaseEvent.EventDate, r.DisplayDate);
            Assert.False(r.IsOccurred.GetValueOrDefault());
        }

        [Fact]
        public async Task ShouldReturnOfficialNumberBasedOnDisplayPriorityOfNumberType()
        {
            var @event = CreateEvent();
            var numberType = Fixture.String();
            var number = Fixture.String();

            @event.CaseEvent.EventDate = Fixture.PastDate();

            var subject = CreateSubject(new OfficialNumberForEvent
            {
                EventNo = @event.CaseEvent.EventNo,
                NumberType = numberType,
                OfficialNumber = number
            });

            var r = (await subject.Resolve(_internalUser, _culture, _meta)).Single();

            Assert.Equal(number, r.OfficialNumber);
            Assert.Equal(numberType, r.NumberTypeCode);
        }

        [Fact]
        public async Task ShouldReturnPriorityEvent()
        {
            _meta.PriorityEventNo = (int) KnownEvents.EarliestPriority;
            _meta.EarliestPriorityDate = Fixture.PastDate();
            _meta.EarliestPriorityNumber = Fixture.String();
            _meta.EarliestPriorityCountry = Fixture.String("Priority Country");
            _meta.EarliestPriorityCountryId = Fixture.String("Priority Country Code");

            var priorityDate = CreateEvent(new EventBuilder().Build().In(Db).WithKnownId(x => x.Id, _meta.PriorityEventNo));
            priorityDate.CaseEvent.EventDate = Fixture.PastDate();

            var subject = CreateSubject();

            var r = (await subject.Resolve(_internalUser, _culture, _meta)).Single();

            Assert.Equal(_meta.EarliestPriorityDate, r.DisplayDate);
            Assert.Equal(_meta.EarliestPriorityNumber, r.OfficialNumber);
            Assert.Equal(_meta.EarliestPriorityCountry, r.CountryCode);
            Assert.Equal(_meta.EarliestPriorityCountryId, r.CountryKey);

            Assert.Equal(priorityDate.ValidEvent.Description, r.EventDescription);
            Assert.Equal(priorityDate.ValidEvent.Event.Notes, r.EventDefinition);
        }

        [Fact]
        public async Task ShouldReturnRenewalYear()
        {
            _meta.AgeOfCase = Fixture.Short();
            _meta.NextRenewalDate = Fixture.FutureDate();

            var renewalDate = CreateEvent(new EventBuilder().Build().In(Db).WithKnownId(x => x.Id, (int) KnownEvents.NextRenewalDate));

            var subject = CreateSubject();

            var r = (await subject.Resolve(_externalUser, _culture, _meta)).Single();

            Assert.Equal(_meta.AgeOfCase, r.RenewalYear.GetValueOrDefault());
            Assert.Equal(_meta.NextRenewalDate, r.DisplayDate);

            Assert.Equal(renewalDate.ValidEvent.Description, r.EventDescription);
            Assert.Equal(renewalDate.ValidEvent.Event.Notes, r.EventDefinition);
        }
    }
}