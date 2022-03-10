using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class ActionEventsFacts
    {
        class ActionEventsFixture : IFixture<ActionEvents>
        {
            public ActionEventsFixture(InMemoryDbContext db)
            {
                Db = db;
                
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(_ => new User("user", false));
                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                SiteControl = Substitute.For<ISiteControlReader>();
                var filter = Substitute.For<ICaseViewEventsDueDateClientFilter>();
                CaseFilter = Substitute.For<ICaseAuthorization>();
                NameFilter = Substitute.For<INameAuthorization>();
                SubjectSecurity = Substitute.For<ISubjectSecurityProvider>();
                AuditLogs = Substitute.For<IAuditLogs>();
                preferredCultureResolver.Resolve().ReturnsForAnyArgs("en");
                Subject = new ActionEvents(Db, securityContext, preferredCultureResolver, SiteControl, filter, CaseFilter, NameFilter, SubjectSecurity, AuditLogs);
            }
            public IAuditLogs AuditLogs { get; }
            public ISubjectSecurityProvider SubjectSecurity { get; }

            public ICaseAuthorization CaseFilter { get; }

            public INameAuthorization NameFilter { get; }

            InMemoryDbContext Db { get; }
            public ISiteControlReader SiteControl { get; }
            public ActionEvents Subject { get; }

            public (Case @case, int criteriaId, CaseEvent caseEvent) Setup()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var fromCase = new CaseBuilder().Build().In(Db);
                fromCase.Id = Fixture.Integer();

                var name = new NameBuilder(Db).Build().In(Db);
                var nameType = new NameTypeBuilder().Build().In(Db);
                var ve = new ValidEventBuilder().Build().In(Db);
                var va = ValidActionBuilder.ForCase(@case).Build().In(Db);
                var ce = new CaseEventBuilder
                {
                    CaseId = @case.Id,
                    Event = ve.Event,
                    PeriodTypeId = Fixture.String(),
                    EmployeeNo = name.Id,
                    DueDateResponsibilityNameType = nameType.NameTypeCode,
                    CreatedByActionKey = va.ActionId,
                    IsDateDueSaved = 2
                }.Build().In(Db);
                ce.FromCaseId = fromCase.Id;
                ce.EventDueDate = Fixture.Date();

                new TableCodeBuilder
                {
                    TableType = (int) TableTypes.PeriodType,
                    UserCode = ce.PeriodType
                }.Build().In(Db);

                return (@case, ve.CriteriaId, ce);
            }
        }

        public class EventsMethod : FactBase
        {
            [Fact]
            public void AllEvents()
            {
                var f = new ActionEventsFixture(Db);
                var data = f.Setup();
                var ce = new CaseEventBuilder
                {
                    CaseId = data.@case.Id,
                    Event = data.caseEvent.Event,
                    PeriodTypeId = data.caseEvent.PeriodType,
                    EmployeeNo = data.caseEvent.EmployeeNo,
                    DueDateResponsibilityNameType = data.caseEvent.DueDateResponsibilityNameType,
                    Cycle = data.caseEvent.Cycle
                }.Build().In(Db);
                ce.FromCaseId = data.caseEvent.FromCaseId;
                ce.EventDate = Fixture.Date();

                var ceDifferentCycleStillIncluded = new CaseEventBuilder
                {
                    CaseId = data.@case.Id,
                    Event = data.caseEvent.Event,
                    PeriodTypeId = data.caseEvent.PeriodType,
                    EmployeeNo = data.caseEvent.EmployeeNo,
                    DueDateResponsibilityNameType = data.caseEvent.DueDateResponsibilityNameType
                }.Build().In(Db);
                ceDifferentCycleStillIncluded.FromCaseId = data.caseEvent.FromCaseId;
                ceDifferentCycleStillIncluded.EventDate = Fixture.Date();

                var result = f.Subject.Events(data.@case, Fixture.String(), new ActionEventQuery
                {
                    CriteriaId = data.criteriaId,
                    AllEvents = true
                });
                Assert.Equal(3, result.Count());
            }

            [Fact]
            public void AllEventsCyclic()
            {
                var f = new ActionEventsFixture(Db);
                var data = f.Setup();
                var ce = new CaseEventBuilder
                {
                    CaseId = data.@case.Id,
                    Event = data.caseEvent.Event,
                    PeriodTypeId = data.caseEvent.PeriodType,
                    EmployeeNo = data.caseEvent.EmployeeNo,
                    DueDateResponsibilityNameType = data.caseEvent.DueDateResponsibilityNameType,
                    Cycle = data.caseEvent.Cycle
                }.Build().In(Db);
                ce.FromCaseId = data.caseEvent.FromCaseId;
                ce.EventDate = Fixture.Date();

                var ceDifferentCycle = new CaseEventBuilder
                {
                    CaseId = data.@case.Id,
                    Event = data.caseEvent.Event,
                    PeriodTypeId = data.caseEvent.PeriodType,
                    EmployeeNo = data.caseEvent.EmployeeNo,
                    DueDateResponsibilityNameType = data.caseEvent.DueDateResponsibilityNameType
                }.Build().In(Db);
                ceDifferentCycle.FromCaseId = data.caseEvent.FromCaseId;
                ceDifferentCycle.EventDate = Fixture.Date();

                var result = f.Subject.Events(data.@case, Fixture.String(), new ActionEventQuery
                {
                    CriteriaId = data.criteriaId,
                    AllEvents = true,
                    IsCyclic = true,
                    Cycle = data.caseEvent.Cycle
                });
                Assert.Equal(2, result.Count());
            }

            [Fact]
            public void CyclicWithoutAllEvents()
            {
                var f = new ActionEventsFixture(Db);
                var data = f.Setup();
                var ce = new CaseEventBuilder
                {
                    CaseId = data.@case.Id,
                    Event = data.caseEvent.Event,
                    PeriodTypeId = data.caseEvent.PeriodType,
                    EmployeeNo = data.caseEvent.EmployeeNo,
                    DueDateResponsibilityNameType = data.caseEvent.DueDateResponsibilityNameType,
                    Cycle = data.caseEvent.Cycle
                }.Build().In(Db);
                ce.FromCaseId = data.caseEvent.FromCaseId;
                ce.EventDate = Fixture.Date();

                // different cycle
                new CaseEventBuilder
                {
                    CaseId = data.@case.Id,
                    Event = data.caseEvent.Event,
                    PeriodTypeId = data.caseEvent.PeriodType,
                    EmployeeNo = data.caseEvent.EmployeeNo,
                    DueDateResponsibilityNameType = data.caseEvent.DueDateResponsibilityNameType
                }.Build().In(Db);
                ce.FromCaseId = data.caseEvent.FromCaseId;
                ce.EventDate = Fixture.Date();

                var result = f.Subject.Events(data.@case, Fixture.String(), new ActionEventQuery
                {
                    CriteriaId = data.criteriaId,
                    IsCyclic = true,
                    Cycle = data.caseEvent.Cycle
                });

                Assert.Equal(2, result.Count());
            }

            [Fact]
            public void EventWithDueDateEntered()
            {
                var f = new ActionEventsFixture(Db);
                var data = f.Setup();

                var result = f.Subject.Events(data.@case, Fixture.String(), new ActionEventQuery
                {
                    CriteriaId = data.criteriaId
                });

                Assert.Single(result);
                Assert.True(result.ToArray()[0].IsManuallyEntered);
            }

            [Fact]
            public void MostRecentEventsWithMinimumMatchingCycle()
            {
                var f = new ActionEventsFixture(Db);
                var data = f.Setup();

                var result = f.Subject.Events(data.@case, Fixture.String(), new ActionEventQuery
                {
                    CriteriaId = data.criteriaId
                });
                Assert.Equal(1, result.Count());
            }

            [Fact]
            public void MostRecentEventsWithoutSortByCycleWithAllNullDates()
            {
                var f = new ActionEventsFixture(Db);
                f.SiteControl.Read<string>(SiteControls.CaseEventDefaultSorting).Returns("CD");
                var data = f.Setup();
                data.caseEvent.EventDueDate = null;
                var ce = new CaseEventBuilder
                {
                    CaseId = data.@case.Id,
                    Event = data.caseEvent.Event,
                    PeriodTypeId = data.caseEvent.PeriodType,
                    EmployeeNo = data.caseEvent.EmployeeNo,
                    DueDateResponsibilityNameType = data.caseEvent.DueDateResponsibilityNameType
                }.Build().In(Db);
                ce.FromCaseId = data.caseEvent.FromCaseId;
                ce.EventDate = Fixture.Date();
                ce.EventDueDate = Fixture.Date();
                ce.ReminderDate = Fixture.Date();

                var result = f.Subject.Events(data.@case, Fixture.String(), new ActionEventQuery
                {
                    CriteriaId = data.criteriaId
                });
                Assert.Equal(1, result.Count());
            }

            [Fact]
            public void MostRecentEventsWithSortByCycle()
            {
                var f = new ActionEventsFixture(Db);
                f.SiteControl.Read<string>(SiteControls.CaseEventDefaultSorting).Returns("CD");
                var data = f.Setup();
                var ceEventDate = new CaseEventBuilder
                {
                    CaseId = data.@case.Id,
                    Event = data.caseEvent.Event,
                    PeriodTypeId = data.caseEvent.PeriodType,
                    EmployeeNo = data.caseEvent.EmployeeNo,
                    DueDateResponsibilityNameType = data.caseEvent.DueDateResponsibilityNameType
                }.Build().In(Db);
                ceEventDate.FromCaseId = data.caseEvent.FromCaseId;
                ceEventDate.EventDate = Fixture.Date();

                var ceEventDueDate = new CaseEventBuilder
                {
                    CaseId = data.@case.Id,
                    Event = data.caseEvent.Event,
                    PeriodTypeId = data.caseEvent.PeriodType,
                    EmployeeNo = data.caseEvent.EmployeeNo,
                    DueDateResponsibilityNameType = data.caseEvent.DueDateResponsibilityNameType
                }.Build().In(Db);
                ceEventDueDate.FromCaseId = data.caseEvent.FromCaseId;
                ceEventDueDate.EventDueDate = Fixture.Date();

                var ceReminderDate = new CaseEventBuilder
                {
                    CaseId = data.@case.Id,
                    Event = data.caseEvent.Event,
                    PeriodTypeId = data.caseEvent.PeriodType,
                    EmployeeNo = data.caseEvent.EmployeeNo,
                    DueDateResponsibilityNameType = data.caseEvent.DueDateResponsibilityNameType
                }.Build().In(Db);
                ceReminderDate.FromCaseId = data.caseEvent.FromCaseId;
                ceReminderDate.ReminderDate = Fixture.Date();

                // without any date
                new CaseEventBuilder
                {
                    CaseId = data.@case.Id,
                    Event = data.caseEvent.Event,
                    PeriodTypeId = data.caseEvent.PeriodType,
                    EmployeeNo = data.caseEvent.EmployeeNo,
                    DueDateResponsibilityNameType = data.caseEvent.DueDateResponsibilityNameType
                }.Build().In(Db);
                ceReminderDate.FromCaseId = data.caseEvent.FromCaseId;

                var result = f.Subject.Events(data.@case, Fixture.String(), new ActionEventQuery
                {
                    CriteriaId = data.criteriaId
                });
                Assert.Equal(4, result.Count());
            }

            [Theory]
            [InlineData(true, true)]
            [InlineData(false, false)]
            public void ShouldReturnTestLinkabilityOnlyIfSiteControlAllowed(bool eventLinktoWorkflowAllowed, bool expected)
            {
                var f = new ActionEventsFixture(Db);
                var data = f.Setup();
                var ce = new CaseEventBuilder
                {
                    CaseId = data.@case.Id,
                    Event = data.caseEvent.Event,
                    PeriodTypeId = data.caseEvent.PeriodType,
                    EmployeeNo = data.caseEvent.EmployeeNo,
                    DueDateResponsibilityNameType = data.caseEvent.DueDateResponsibilityNameType,
                    Cycle = data.caseEvent.Cycle
                }.Build().In(Db);
                ce.FromCaseId = data.caseEvent.FromCaseId;
                ce.EventDate = Fixture.Date();

                var ceDifferentCycleStillIncluded = new CaseEventBuilder
                {
                    CaseId = data.@case.Id,
                    Event = data.caseEvent.Event,
                    PeriodTypeId = data.caseEvent.PeriodType,
                    EmployeeNo = data.caseEvent.EmployeeNo,
                    DueDateResponsibilityNameType = data.caseEvent.DueDateResponsibilityNameType
                }.Build().In(Db);
                ceDifferentCycleStillIncluded.FromCaseId = data.caseEvent.FromCaseId;
                ceDifferentCycleStillIncluded.EventDate = Fixture.Date();

                f.SiteControl.Read<bool>(SiteControls.EventLinktoWorkflowAllowed)
                 .Returns(eventLinktoWorkflowAllowed);

                var result = f.Subject.Events(data.@case, Fixture.String(), new ActionEventQuery
                {
                    CriteriaId = data.criteriaId,
                    AllEvents = true
                });

                // during unit test DbFuncs.DoesEntryExistForCaseEvent will always return true.
                Assert.True(result.All(_ => _.CanLinkToWorkflow == expected));
            }
        }

        public class ClearValueByCaseAndNameAccessMethod : FactBase
        {
            [Fact]
            public async Task RemoveFilteredNameandCaseWithoutRestriction()
            {
                var f = new ActionEventsFixture(Db);
                var data = f.Setup();

                var namesRowAccess = data.caseEvent.EmployeeNo;
                var casesRowAccess = data.caseEvent.FromCaseId;

                f.NameFilter.AccessibleNames().ReturnsForAnyArgs(new[] {namesRowAccess.GetValueOrDefault()});
                f.CaseFilter.AccessibleCases().ReturnsForAnyArgs(new[] {casesRowAccess.GetValueOrDefault()});

                var result = f.Subject.Events(data.@case, Fixture.String(), new ActionEventQuery
                {
                    CriteriaId = data.criteriaId
                }).ToArray();

                var clearedResult = (await f.Subject.ClearValueByCaseAndNameAccess(result)).ToArray();

                Assert.Single(clearedResult);
                Assert.Equal(result[0].NameId, clearedResult[0].NameId);
                Assert.Equal(result[0].CaseKey, clearedResult[0].CaseKey);
            }

            [Fact]
            public async Task RemoveFilteredNameAndCaseWithRestriction()
            {
                var f = new ActionEventsFixture(Db);
                var data = f.Setup();

                var result = f.Subject.Events(data.@case, Fixture.String(), new ActionEventQuery
                {
                    CriteriaId = data.criteriaId
                });

                var clearedResult = (await f.Subject.ClearValueByCaseAndNameAccess(result)).ToArray();

                Assert.Single(clearedResult);
                Assert.Null(clearedResult[0].NameId);
                Assert.Null(clearedResult[0].FromCaseKey);
            }
        }
    }
}