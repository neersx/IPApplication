using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.CaseviewEvents
{
    public class CaseViewEventsFacts
    {
        public class Occurred : FactBase
        {
            public Occurred()
            {
                _f = new CaseViewEventsFixture(Db).WithUser();

                _case = _f.Case;
            }

            readonly Case _case;
            readonly CaseViewEventsFixture _f;

            (CaseEvent CaseEvent, Event BaseEvent, ValidEvent ValidEvent, OpenAction oa) CreateOccurredEvent(int? knownEventId = null)
            {
                return _f.CreateOccurredEvent(knownEventId);
            }

            ICaseViewEvents CreateSubject()
            {
                return _f.Subject;
            }

            public static IEnumerable<object[]> ValidOccurredFlags => Enumerable.Range(1, 8).Select(_ => new object[] {_});

            [Theory]
            [MemberData(nameof(ValidOccurredFlags))]
            public void ShouldReturnEventsWithOccurredFlagsBetween1And8(int occurredFlag)
            {
                var ce1 = CreateOccurredEvent();

                ce1.CaseEvent.IsOccurredFlag = occurredFlag;

                var subject = CreateSubject();

                Assert.True(subject.Occurred(_case.Id).Any());
            }

            [Theory]
            [MemberData(nameof(ValidOccurredFlags))]
            public void ShouldNotReturnOccurredEventsWithEventDateNull(int occurredFlag)
            {
                var ce1 = CreateOccurredEvent();

                ce1.CaseEvent.IsOccurredFlag = occurredFlag;
                ce1.CaseEvent.EventDate = null;

                var subject = CreateSubject();

                Assert.False(subject.Occurred(_case.Id).Any());
            }

            [Theory]
            [InlineData(0)]
            [InlineData(9)]
            public void ShouldNotReturnEventsNotOccurred(int occurredFlag)
            {
                var ce1 = CreateOccurredEvent();

                ce1.CaseEvent.IsOccurredFlag = occurredFlag;

                var subject = CreateSubject();

                Assert.False(subject.Occurred(_case.Id).Any());
            }

            [Theory]
            [MemberData(nameof(ValidOccurredFlags))]
            public void ShouldNotReturnOccurredEventsWithControllingAction(int occurredFlag)
            {
                var ce1 = CreateOccurredEvent();

                ce1.CaseEvent.IsOccurredFlag = occurredFlag;
                ce1.ValidEvent.Event.ControllingAction = ce1.oa.ActionId;

                var subject = CreateSubject();

                Assert.False(subject.Occurred(_case.Id).Any());
            }

            [Theory]
            [MemberData(nameof(ValidOccurredFlags))]
            public void ShouldReturnOccurredEventsWithControllingActionIfActionIsOpen(int occurredFlag)
            {
                var ce1 = CreateOccurredEvent();

                ce1.CaseEvent.IsOccurredFlag = occurredFlag;
                ce1.ValidEvent.Event.ControllingAction = ce1.oa.ActionId;
                ce1.oa.PoliceEvents = 1;

                var subject = CreateSubject();

                Assert.True(subject.Occurred(_case.Id).Any());
            }

            [Theory]
            [MemberData(nameof(ValidOccurredFlags))]
            public void ShouldReturnOccurredEventsWithControllingActionIfShowAllEventDatesTrue(int occurredFlag)
            {
                var ce1 = CreateOccurredEvent();

                ce1.CaseEvent.IsOccurredFlag = occurredFlag;
                ce1.ValidEvent.Event.ControllingAction = ce1.oa.ActionId;

                _f.WithSiteControlValue<bool?>(SiteControls.AlwaysShowEventDate, true);

                var subject = CreateSubject();

                Assert.True(subject.Occurred(_case.Id).Any());
            }

            [Fact]
            public void ClientImportanceLevelIsPickedForExternalUsers()
            {
                _f.WithUser(true);
                var data = _f.CreateOccurredEvent();

                var r = _f.Subject.Occurred(_case.Id);

                Assert.True(r.Any());
                Assert.True(r.First().ImportanceLevel == data.BaseEvent.ClientImportanceLevel);
            }

            [Fact]
            public void ImportanceLevelIsPickedForInternalUsers()
            {
                var data = _f.CreateOccurredEvent();

                var r = _f.Subject.Occurred(_case.Id);

                Assert.True(r.Any());
                Assert.True(r.First().ImportanceLevel == data.ValidEvent.ImportanceLevel);
            }

            [Fact]
            public void ShouldReturnFromBaseEvents()
            {
                var ce = CreateOccurredEvent();

                // Unable to resolve event control as
                // Created By Criteria Key is null and Event Controlling Action is null
                ce.CaseEvent.CreatedByCriteriaKey = null;

                ce.BaseEvent.Description = Fixture.String();
                ce.BaseEvent.ImportanceLevel = "9";

                ce.ValidEvent.Description = Fixture.String();
                ce.ValidEvent.ImportanceLevel = "5";

                var result = CreateSubject().Occurred(_case.Id).Single();

                Assert.Equal(ce.BaseEvent.Description, result.EventDescription);
                Assert.Equal(ce.BaseEvent.ImportanceLevel, result.ImportanceLevel);
            }

            [Fact]
            public void ShouldReturnFromEventControlBasedOnControllingAction()
            {
                var ce = CreateOccurredEvent();

                // Resolves event control using Controlling Action
                ce.BaseEvent.ControllingAction = ce.oa.ActionId;
                ce.oa.PoliceEvents = 1;
                ce.CaseEvent.CreatedByCriteriaKey = null;

                ce.BaseEvent.Description = Fixture.String();
                ce.BaseEvent.ImportanceLevel = "9";

                ce.ValidEvent.Description = Fixture.String();
                ce.ValidEvent.ImportanceLevel = "5";

                var result = CreateSubject().Occurred(_case.Id).Single();

                Assert.Equal(ce.ValidEvent.Description, result.EventDescription);
                Assert.Equal(ce.ValidEvent.ImportanceLevel, result.ImportanceLevel);
            }

            [Fact]
            public void ShouldReturnFromEventControlBasedOnCreatedByCriteriaKey()
            {
                var ce = CreateOccurredEvent();

                // Resolves event control using Created By Criteria Key
                ce.CaseEvent.CreatedByCriteriaKey = ce.ValidEvent.CriteriaId;

                ce.BaseEvent.Description = Fixture.String();
                ce.BaseEvent.ImportanceLevel = "9";

                ce.ValidEvent.Description = Fixture.String();
                ce.ValidEvent.ImportanceLevel = "5";

                var result = CreateSubject().Occurred(_case.Id).Single();

                Assert.Equal(ce.ValidEvent.Description, result.EventDescription);
                Assert.Equal(ce.ValidEvent.ImportanceLevel, result.ImportanceLevel);
            }

            [Fact]
            public void ShouldReturnFromEventControlBasedOnHighestOpenActionCycle()
            {
                var ce = CreateOccurredEvent();

                ce.oa.Cycle = 1;
                ce.oa.PoliceEvents = 0; /* closed action */

                var higherCycleOa = new OpenAction(ce.oa.Action, _case, 2, null, ce.oa.Criteria).In(Db);

                higherCycleOa.Cycle = 2;
                higherCycleOa.PoliceEvents = 1; /* opened action */

                ce.BaseEvent.ControllingAction = ce.oa.ActionId;
                ce.CaseEvent.CreatedByCriteriaKey = null;

                ce.ValidEvent.Description = Fixture.String();
                ce.ValidEvent.ImportanceLevel = "5";

                var result = CreateSubject().Occurred(_case.Id).Single();

                Assert.Equal(ce.ValidEvent.Description, result.EventDescription);
                Assert.Equal(ce.ValidEvent.ImportanceLevel, result.ImportanceLevel);
            }

            [Fact]
            public void ShouldReturnOrderByEventDateDescending()
            {
                var ce1 = CreateOccurredEvent();

                var ce2 = CreateOccurredEvent();

                ce1.CaseEvent.EventDate = Fixture.PastDate();

                ce2.CaseEvent.EventDate = Fixture.Today();

                var result = CreateSubject().Occurred(_case.Id).ToArray();

                Assert.Equal(Fixture.Today(), result.First().EventDate);
                Assert.Equal(Fixture.PastDate(), result.Last().EventDate);
            }

            [Fact]
            public void ShouldReturnOrderByEventDescriptionIfEventDateSame()
            {
                var ce1 = CreateOccurredEvent();

                var ce2 = CreateOccurredEvent();

                ce1.CaseEvent.EventDate = Fixture.Today();
                ce1.ValidEvent.Description = "B";

                ce2.CaseEvent.EventDate = Fixture.Today();
                ce2.ValidEvent.Description = "A";

                var result = CreateSubject().Occurred(_case.Id).ToArray();

                Assert.Equal("A", result.First().EventDescription);
                Assert.Equal("B", result.Last().EventDescription);
            }

            [Fact]
            public void ShouldReturnAttachmentCount()
            {
                var ce1 = CreateOccurredEvent();
                var attachment1 = new Activity {EventId = ce1.BaseEvent.Id, Cycle = ce1.CaseEvent.Cycle};
                var attachment2 = new Activity {EventId = ce1.BaseEvent.Id, Cycle = ce1.CaseEvent.Cycle};
                var attachment3 = new Activity {EventId = Fixture.Integer(), Cycle = 1};
                _f.CaseViewAttachmentsProvider.GetActivityWithAttachments(Arg.Any<int>()).Returns(new[] {attachment1, attachment2, attachment3}.AsQueryable());

                var result = CreateSubject().Occurred(_case.Id).ToArray();
                Assert.Equal(2, result.Single().AttachmentCount);
                Assert.Equal(ce1.CaseEvent.CreatedByActionKey, result.Single().CreatedByAction);
            }
        }

        public class Due : FactBase
        {
            public Due()
            {
                _f = new CaseViewEventsFixture(Db).WithUser();
                _case = _f.Case;
            }

            readonly Case _case;
            readonly CaseViewEventsFixture _f;

            (CaseEvent CaseEvent, Event BaseEvent, ValidEvent ValidEvent, OpenAction oa) CreateDueEvent()
            {
                return _f.CreateDueEvent();
            }

            ICaseViewEvents CreateSubject()
            {
                return _f.Subject;
            }

            public static IEnumerable<object[]> ValidOccurredFlags => Enumerable.Range(1, 8).Select(_ => new object[] {_}).ToArray();

            [Theory]
            [InlineData(null)]
            [InlineData(0)]
            public void ShouldReturnEventsNotOccurred(int? occurredFlag)
            {
                var ce1 = _f.CreateDueEvent();

                ce1.CaseEvent.IsOccurredFlag = occurredFlag;
                Assert.True(_f.Subject.Due(_case.Id).Any());
            }

            [Theory]
            [MemberData(nameof(ValidOccurredFlags))]
            public void ShouldNotReturnOccurredEvents(int occurredFlag)
            {
                var ce1 = _f.CreateDueEvent();

                ce1.CaseEvent.IsOccurredFlag = occurredFlag;
                Assert.False(_f.Subject.Due(_case.Id).Any());
            }

            [Fact]
            public void ClientImportanceLevelIsPickedForExternalUsers()
            {
                _f.WithUser(true);
                var data = _f.CreateDueEvent();

                var r = _f.Subject.Due(_case.Id);

                Assert.True(r.Any());
                Assert.True(r.First().ImportanceLevel == data.BaseEvent.ClientImportanceLevel);
            }

            [Fact]
            public void ImportanceLevelIsPickedForInternalUsers()
            {
                _f.WithUser();
                var data = _f.CreateDueEvent();

                var r = _f.Subject.Due(_case.Id);

                Assert.True(r.Any());
                Assert.True(r.First().ImportanceLevel == data.ValidEvent.ImportanceLevel);
            }

            [Fact]
            public void ShouldConsiderClientDueDates_OverdueDaysWhenHasValue()
            {
                _f.WithUser(true)
                  .WithDueDateFilter(Fixture.PastDate().AddDays(1));
                _f.CreateDueEvent();

                Assert.False(_f.Subject.Due(_case.Id).Any());
            }

            [Fact]
            public void ShouldMatchCycleTo1IfNumberOfCyclesAllowedIsNotGreaterThan1()
            {
                var ce1 = _f.CreateDueEvent();

                ce1.oa.Action.NumberOfCyclesAllowed = 1;
                ce1.oa.Cycle = 1;
                Assert.True(_f.Subject.Due(_case.Id).Any());
            }

            [Fact]
            public void ShouldNotConsiderClientDueDates_OverdueDaysIfNull()
            {
                _f.CreateDueEvent();

                _f.WithDueDateFilter(null);
                Assert.True(_f.Subject.Due(_case.Id).Any());
            }

            [Fact]
            public void ShouldNotReturnDueEventsWithEventDueDateNull()
            {
                var ce1 = _f.CreateDueEvent();

                ce1.CaseEvent.EventDueDate = null;
                Assert.False(_f.Subject.Due(_case.Id).Any());
            }

            [Fact]
            public void ShouldNotReturnDueEventsWithNullControllingActionAndNonMatchingCriteria()
            {
                var ce1 = _f.CreateDueEvent();

                ce1.ValidEvent.Event.ControllingAction = null;
                ce1.ValidEvent.CriteriaId = Fixture.Integer();
                Assert.False(_f.Subject.Due(_case.Id).Any());
            }

            [Fact]
            public void ShouldOnlyMatchCycleIfNumberOfCyclesAllowedIsGreaterThan1()
            {
                var ce1 = _f.CreateDueEvent();

                ce1.oa.Action.NumberOfCyclesAllowed = 2;
                Assert.True(_f.Subject.Due(_case.Id).Any());
            }

            [Fact]
            public void ShouldReturnDueEventsWithControllingAction()
            {
                var ce1 = _f.CreateDueEvent();

                ce1.ValidEvent.Event.ControllingAction = ce1.oa.ActionId;
                Assert.True(_f.Subject.Due(_case.Id).Any());
            }

            [Fact]
            public void ShouldReturnDueEventsWithinRangeOfClientDueDates_OverdueDaysLimitForExternalUsers()
            {
                _f.WithUser(true);
                _f.CreateDueEvent();

                Assert.True(_f.Subject.Due(_case.Id).Any());
            }

            [Fact]
            public void ShouldReturnDueEventsWithNullControllingActionAndMatchingCriteria()
            {
                var ce1 = _f.CreateDueEvent();

                ce1.ValidEvent.Event.ControllingAction = null;
                Assert.True(_f.Subject.Due(_case.Id).Any());
            }

            [Fact]
            public void ShouldReturnOccurredEventsWithControllingActionIfAnyOpenActionForDueDateFalse()
            {
                var ce1 = _f.CreateDueEvent();

                _f.WithSiteControlValue<bool?>(SiteControls.AnyOpenActionForDueDate, false);
                Assert.True(_f.Subject.Due(_case.Id).Any());
            }

            [Fact]
            public void ShouldReturnOccurredEventsWithoutControllingActionIfAnyOpenActionForDueDateTrue()
            {
                var ce1 = _f.CreateDueEvent();

                ce1.ValidEvent.Event.ControllingAction = null;

                _f.WithSiteControlValue<bool?>(SiteControls.AnyOpenActionForDueDate, true);
                Assert.True(_f.Subject.Due(_case.Id).Any());
            }

            [Fact]
            public void ShouldTryMatchCycleTo1IfNumberOfCyclesAllowedIsNotGreaterThan1()
            {
                var ce1 = _f.CreateDueEvent();

                ce1.oa.Action.NumberOfCyclesAllowed = 1;
                Assert.False(_f.Subject.Due(_case.Id).Any());
            }

            [Fact]
            public void ShouldReturnAttachmentCount()
            {
                var ce1 = CreateDueEvent();
                ce1.CaseEvent.CreatedByActionKey = "AA";

                var attachment1 = new Activity {EventId = ce1.BaseEvent.Id, Cycle = ce1.CaseEvent.Cycle};
                var attachment2 = new Activity {EventId = ce1.BaseEvent.Id, Cycle = ce1.CaseEvent.Cycle};
                var attachment3 = new Activity {EventId = Fixture.Integer(), Cycle = 1};
                _f.CaseViewAttachmentsProvider.GetActivityWithAttachments(Arg.Any<int>()).Returns(new[] {attachment1, attachment2, attachment3}.AsQueryable());

                var result = CreateSubject().Due(_case.Id).ToArray();
                Assert.Equal(2, result.Single().AttachmentCount);
                Assert.Equal(ce1.CaseEvent.CreatedByActionKey, result.Single().CreatedByAction);
            }
        }

        class CaseViewEventsFixture : IFixture<CaseViewEvents>
        {
            readonly string _culture = Fixture.String();
            readonly ISiteControlReader _siteControlReader = Substitute.For<ISiteControlReader>();

            public CaseViewEventsFixture(InMemoryDbContext db)
            {
                Db = db;
                var preferedCultureResolver = Substitute.For<IPreferredCultureResolver>();
                preferedCultureResolver.Resolve().Returns(_culture);
                SecurityContext = Substitute.For<ISecurityContext>();
                var caseFilter = Substitute.For<ICaseAuthorization>();
                var namefilter = Substitute.For<INameAuthorization>();
                CaseViewAttachmentsProvider = Substitute.For<ICaseViewAttachmentsProvider>();
                Case = new CaseBuilder().Build().In(Db);
                CaseViewEventsDueDateClientFilter = Substitute.For<ICaseViewEventsDueDateClientFilter>();
                Subject = new CaseViewEvents(Db, preferedCultureResolver, _siteControlReader, SecurityContext, caseFilter, namefilter, CaseViewEventsDueDateClientFilter, CaseViewAttachmentsProvider);
            }

            public Case Case { get; }
            InMemoryDbContext Db { get; }
            ISecurityContext SecurityContext { get; }
            ICaseViewEventsDueDateClientFilter CaseViewEventsDueDateClientFilter { get; }
            public ICaseViewAttachmentsProvider CaseViewAttachmentsProvider { get; }
            public CaseViewEvents Subject { get; }

            public (CaseEvent CaseEvent, Event BaseEvent, ValidEvent ValidEvent, OpenAction oa) CreateOccurredEvent(int? knownEventId = null)
            {
                var cycle = Fixture.Short();

                var @event = new EventBuilder().Build().In(Db);

                var criteria = new CriteriaBuilder().Build().In(Db);

                var ve = new ValidEventBuilder
                {
                    Criteria = criteria,
                    Event = @event,
                    ImportanceLevel = "5"
                }.Build().In(Db);

                var ac = new ActionBuilder().Build().In(Db);

                var oa = new OpenAction(ac, Case, cycle, null, criteria).In(Db);

                var ce = new CaseEvent(Case.Id, ve.EventId, cycle)
                {
                    CreatedByCriteriaKey = ve.CriteriaId,
                    EventDate = Fixture.PastDate(),
                    IsOccurredFlag = 1,
                    DueDateResponsibilityNameType = "TYP"
                }.In(Db);

                var nameType = new NameTypeBuilder().Build().In(Db);
                new FilteredUserNameTypes
                {
                    NameType = ce.DueDateResponsibilityNameType
                }.In(Db);

                if (knownEventId.HasValue)
                {
                    ce.WithKnownId(x => x.EventNo, knownEventId.Value);
                }

                return (ce, @event, ve, oa);
            }

            public (CaseEvent CaseEvent, Event BaseEvent, ValidEvent ValidEvent, OpenAction oa) CreateDueEvent()
            {
                var cycle = Fixture.Short();

                var @event = new EventBuilder
                {
                    ClientImportanceLevel = "3"
                }.Build().In(Db);

                var criteria = new CriteriaBuilder().Build().In(Db);

                var ve = new ValidEventBuilder
                {
                    Criteria = criteria,
                    Event = @event,
                    ImportanceLevel = "5"
                }.Build().In(Db);

                var ac = new ActionBuilder {NumberOfCyclesAllowed = cycle}.Build().In(Db);

                var oa = new OpenAction(ac, Case, cycle, null, criteria, true).In(Db);

                var ce = new CaseEvent(Case.Id, ve.EventId, cycle)
                {
                    CreatedByCriteriaKey = ve.CriteriaId,
                    EventDueDate = Fixture.PastDate(),
                    IsOccurredFlag = 0
                }.In(Db);

                return (ce, @event, ve, oa);
            }

            public CaseViewEventsFixture WithSiteControlValue<T>(string siteControl, T value)
            {
                _siteControlReader.Read<T>(siteControl).Returns(value);
                return this;
            }

            public CaseViewEventsFixture WithUser(bool isExternal = false)
            {
                SecurityContext.User.Returns(new User(Fixture.String(), isExternal));
                return this;
            }

            public CaseViewEventsFixture WithDueDateFilter(DateTime? maxOverDue)
            {
                CaseViewEventsDueDateClientFilter.MaxDueDateLimit().Returns(maxOverDue);
                return this;
            }
        }
    }
}