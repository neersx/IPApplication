using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Documents;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

#pragma warning disable 618

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowEntryControlControllerFacts : FactBase
    {
        public class GetEntryControlMethod : FactBase
        {
            [Fact]
            public async Task GetEventControlMethodShouldForwardParameters()
            {
                var c = new Criteria().In(Db);
                var d = new DataEntryTask(c, 2).In(Db);

                var f = new Fixture(Db);
                await f.Subject.GetEntryControl(c.Id, d.Id);
                await f.WorkflowEntryControlService.Received(1).GetEntryControl(1, 2);
            }

            [Fact]
            public void GetStepsShouldForwardParameters()
            {
                var f = new Fixture(Db);
                f.Subject.GetSteps(1, 2);
                f.WorkflowEntryStepsService.Received(1).GetSteps(1, 2);
            }
        }

        public class GetDetailsMethod : FactBase
        {
            [Fact]
            public void FavoursValidDescriptionOverBaseDescription()
            {
                var @event = new Event {Description = "a"}.In(Db);
                var alsoUpdateEvent = new Event {Description = "b"}.In(Db);

                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);

                new ValidEventBuilder
                {
                    Criteria = criteria,
                    Event = @event,
                    Description = "a-valid"
                }.Build().In(Db);

                new ValidEventBuilder
                {
                    Criteria = criteria,
                    Event = alsoUpdateEvent,
                    Description = "b-valid"
                }.Build().In(Db);

                var item1 = new AvailableEvent
                {
                    CriteriaId = criteria.Id,
                    Event = @event,
                    AlsoUpdateEvent = alsoUpdateEvent,
                    DataEntryTaskId = 1,
                    DisplaySequence = 2
                }.In(Db);

                var f = new Fixture(Db);
                var r = f.Subject.GetDetails(item1.CriteriaId, item1.DataEntryTaskId).Single();

                Assert.Equal("a-valid", r.EventName);
                Assert.Equal("b-valid", r.EventToUpdateDescription);
            }

            [Fact]
            public void ReturnsData()
            {
                var item1 = new AvailableEvent
                {
                    CriteriaId = 1,
                    Inherited = 1,
                    DataEntryTaskId = 2,
                    Event = new Event {Description = "a"},
                    AlsoUpdateEvent = new Event {Description = "b"},
                    EventAttribute = 0,
                    DueAttribute = 1,
                    PolicingAttribute = 2,
                    PeriodAttribute = 3,
                    DueDateResponsibleNameAttribute = 0
                }.In(Db);

                var f = new Fixture(Db);
                var r = f.Subject.GetDetails(item1.CriteriaId, item1.DataEntryTaskId).Single();

                Assert.True(r.IsInherited);
                Assert.Equal(item1.Event.Id, r.EventId);
                Assert.Equal(item1.Event.Description, r.EventName);
                Assert.Equal(item1.AlsoUpdateEventId, r.EventToUpdateId);
                Assert.Equal(item1.AlsoUpdateEvent.Description, r.EventToUpdateDescription);
                Assert.Equal(item1.EventAttribute, r.EventDate);
                Assert.Equal(item1.DueAttribute, r.DueDate);
                Assert.Equal(item1.PolicingAttribute, r.Policing);
                Assert.Equal(item1.PeriodAttribute, r.Period);
                Assert.Equal(item1.DueDateResponsibleNameAttribute, r.DueDateResp);
            }

            [Fact]
            public void ReturnsInDisplaySequenceOrder()
            {
                var item1 = new AvailableEvent
                {
                    CriteriaId = 1,
                    DataEntryTaskId = 2,
                    Event = new Event {Description = "a"},
                    AlsoUpdateEvent = new Event {Description = "a"},
                    DisplaySequence = 2
                }.In(Db);

                var item2 = new AvailableEvent
                {
                    CriteriaId = 1,
                    DataEntryTaskId = 2,
                    Event = new Event {Description = "b"},
                    AlsoUpdateEvent = new Event {Description = "b"},
                    DisplaySequence = 1
                }.In(Db);

                var f = new Fixture(Db);
                var r = f.Subject.GetDetails(item1.CriteriaId, item1.DataEntryTaskId).ToArray();

                Assert.Equal(item2.Event.Description, r[0].EventName);
                Assert.Equal(item1.Event.Description, r[1].EventName);
            }
        }

        public class GetDocumentsMethod : FactBase
        {
            [Fact]
            public void ReturnsDocumentsOrderedByName()
            {
                var criteria = new CriteriaBuilder().Build();
                var dataEntryTask = new DataEntryTaskBuilder().Build();
                var document1 = new DocumentBuilder {Name = "A"}.Build();
                var document2 = new DocumentBuilder {Name = "B"}.Build();

                var documentRequirement1 = new DocumentRequirement(criteria, dataEntryTask, document1, true).In(Db);
                var documentRequirement2 = new DocumentRequirement(criteria, dataEntryTask, document2) {Inherited = 1}.In(Db);

                var f = new Fixture(Db);
                var r = f.Subject.GetDocuments(criteria.Id, dataEntryTask.Id).ToArray();

                Assert.Equal(document1.Id, r[0].Document.Key);
                Assert.Equal(document1.Name, r[0].Document.Value);
                Assert.Equal(documentRequirement1.IsMandatory, r[0].MustProduce);
                Assert.False(r[0].IsInherited);

                Assert.Equal(document2.Id, r[1].Document.Key);
                Assert.Equal(document2.Name, r[1].Document.Value);
                Assert.Equal(documentRequirement2.IsMandatory, r[1].MustProduce);
                Assert.True(r[1].IsInherited);
            }
        }

        public class SaveEntryDetails : FactBase
        {
            [Fact]
            public void ShouldReturnErrorIfUpdatedValuesInvalid()
            {
                var criteria = new CriteriaBuilder().Build().In(Db);
                var dataEntryTask = new DataEntryTaskBuilder
                {
                    Criteria = criteria
                }.Build().In(Db);
                criteria.DataEntryTasks.Add(dataEntryTask);

                var input = new WorkflowEntryControlSaveModel();
                var f = new Fixture(Db);
                f.WorkflowEntryDetailService.ValidateChange(Arg.Any<DataEntryTask>(), Arg.Any<WorkflowEntryControlSaveModel>()).ReturnsForAnyArgs(new[] {ValidationErrors.NotUnique("description")});
                var result = f.Subject.SaveEntryDetails(criteria.Id, dataEntryTask.Id, input);

                f.WorkflowEntryDetailService.Received(1).ValidateChange(dataEntryTask, input);
                f.WorkflowEntryDetailService.Received(0).UpdateEntryDetail(Arg.Any<DataEntryTask>(), Arg.Any<WorkflowEntryControlSaveModel>());

                Assert.Equal("error", result.Status);
                Assert.Equal(1, result.Errors.Length);
                Assert.Equal("description", result.Errors[0].Field);
            }

            [Fact]
            public void ShouldSaveEntryDetails()
            {
                var criteria = new CriteriaBuilder().Build().In(Db);
                var dataEntryTask = new DataEntryTaskBuilder
                {
                    Criteria = criteria
                }.Build().In(Db);
                criteria.DataEntryTasks.Add(dataEntryTask);

                var input = new WorkflowEntryControlSaveModel();
                var f = new Fixture(Db);
                f.Subject.SaveEntryDetails(criteria.Id, dataEntryTask.Id, input);

                f.PermissionHelper.Received(1).EnsureEditPermission(criteria.Id);
                f.WorkflowEntryDetailService.Received(1).UpdateEntryDetail(dataEntryTask, input);
            }

            [Fact]
            public void ShouldValidateEntryBeforeSave()
            {
                var criteria = new CriteriaBuilder().Build().In(Db);
                var dataEntryTask = new DataEntryTaskBuilder
                {
                    Criteria = criteria
                }.Build().In(Db);
                criteria.DataEntryTasks.Add(dataEntryTask);

                var input = new WorkflowEntryControlSaveModel();
                var f = new Fixture(Db);
                f.Subject.SaveEntryDetails(criteria.Id, dataEntryTask.Id, input);

                f.WorkflowEntryDetailService.Received(1).ValidateChange(dataEntryTask, input);
                f.WorkflowEntryDetailService.Received(1).UpdateEntryDetail(dataEntryTask, input);
            }
        }

        public class GetDescendantsWithInheritedEntryMethod : FactBase
        {
            [Fact]
            public void SeparatorEntriesAreConsidered()
            {
                var criteria = new CriteriaBuilder().Build().In(Db);
                var dataEntryTask = new DataEntryTaskBuilder(criteria).AsSeparator().Build().In(Db);
                var f = new Fixture(Db).WithUniqueDescription();
                var newDescription = "-----------------";

                f.Subject.GetEntryDescendants(criteria.Id, dataEntryTask.Id, newDescription);

                f.PermissionHelper.Received(1).EnsureEditPermission(criteria.Id);
                f.Inheritance.Received(1).GetDescendantsWithAnyInheritedEntriesFrom(criteria.Id, Arg.Is<short[]>(x => x.Contains(dataEntryTask.Id)));
                f.DescriptionValidator.Received(1).IsDescriptionUnique(criteria.Id, dataEntryTask.Description, newDescription, true);
                f.DescriptionValidator.Received(1).IsDescriptionExisting(Arg.Any<int[]>(), newDescription, true);
            }

            [Fact]
            public void ShouldCalculateBreakingChangesIfDescriptionsDifferent()
            {
                var newDescription = "new Description";

                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var childCriteria1 = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var childCriteria2 = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);

                var dataEntryTask = new DataEntryTaskBuilder(criteria).Build().In(Db);

                var f = new Fixture(Db).WithUniqueDescription();

                f.Inheritance.GetDescendantsWithAnyInheritedEntriesFrom(criteria.Id, Arg.Any<short[]>()).Returns(new[] {childCriteria1.Id, childCriteria2.Id});
                f.DescriptionValidator.IsDescriptionExisting(Arg.Any<int[]>(), newDescription).Returns(new[] {childCriteria1.Id});

                var res = f.Subject.GetEntryDescendants(criteria.Id, dataEntryTask.Id, newDescription);

                f.PermissionHelper.Received(1).EnsureEditPermission(criteria.Id);
                f.Inheritance.Received(1).GetDescendantsWithAnyInheritedEntriesFrom(criteria.Id, Arg.Is<short[]>(x => x.Contains(dataEntryTask.Id)));
                f.DescriptionValidator.Received(1).IsDescriptionUnique(criteria.Id, dataEntryTask.Description, newDescription);
                f.DescriptionValidator.Received(1).IsDescriptionExisting(Arg.Any<int[]>(), newDescription);

                var descendants = res.Descendants as dynamic[];

                Assert.NotNull(descendants);
                Assert.NotEmpty(descendants);
                Assert.Single(descendants);
                Assert.Equal(childCriteria2.Id, descendants.Single().Id);

                var breakingCriterias = res.Breaking as dynamic[];
                Assert.NotNull(breakingCriterias);
                Assert.NotEmpty(breakingCriterias);
                Assert.Single(breakingCriterias);
                Assert.Equal(childCriteria1.Id, breakingCriterias.Single().Id);
            }

            [Fact]
            public void ShouldNotCalculateBreakingChangesIfDescriptionsSame()
            {
                var criteria = new CriteriaBuilder().Build().In(Db);
                var dataEntryTask = new DataEntryTaskBuilder(criteria).Build().In(Db);
                var f = new Fixture(Db);

                var res = f.Subject.GetEntryDescendants(criteria.Id, dataEntryTask.Id, dataEntryTask.Description);

                f.PermissionHelper.Received(1).EnsureEditPermission(criteria.Id);
                f.Inheritance.Received(1).GetDescendantsWithAnyInheritedEntriesFrom(criteria.Id, Arg.Is<short[]>(x => x.Contains(dataEntryTask.Id)));
                f.DescriptionValidator.DidNotReceive().IsDescriptionExisting(Arg.Any<int[]>(), Arg.Any<string>(), Arg.Any<bool>());
                Assert.NotNull(res);
                Assert.NotNull(res.Descendants);
                Assert.Empty(res.Breaking);
            }

            [Fact]
            public void ShouldReturnDescendents()
            {
                var criteria = new CriteriaBuilder().Build().In(Db);
                var childCriteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);

                var dataEntryTask = new DataEntryTaskBuilder(criteria).Build().In(Db);
                var f = new Fixture(Db)
                    .WithUniqueDescription();
                f.Inheritance.GetDescendantsWithAnyInheritedEntriesFrom(criteria.Id, Arg.Any<short[]>()).Returns(new[] {childCriteria.Id});

                var newDescription = "new Description";

                var res = f.Subject.GetEntryDescendants(criteria.Id, dataEntryTask.Id, newDescription);

                f.PermissionHelper.Received(1).EnsureEditPermission(criteria.Id);
                f.Inheritance.Received(1).GetDescendantsWithAnyInheritedEntriesFrom(criteria.Id, Arg.Is<short[]>(x => x.Contains(dataEntryTask.Id)));
                f.DescriptionValidator.Received(1).IsDescriptionUnique(criteria.Id, dataEntryTask.Description, newDescription);

                Assert.NotNull(res);
                Assert.NotEmpty(res.Descendants);
                Assert.Empty(res.Breaking);
            }
        }

        public class ResetAndBreakEntryInheritance : FactBase
        {
            [Fact]
            public void BreakInheritance()
            {
                var criteriaId = Tests.Fixture.Integer();
                var entryId = Tests.Fixture.Short();
                var f = new Fixture(Db);
                f.Subject.BreakEntryInheritance(criteriaId, entryId);

                f.PermissionHelper.ReceivedWithAnyArgs(1).EnsureEditPermission(criteriaId);
                f.WorkflowEntryControlService.ReceivedWithAnyArgs(1).BreakEntryControlInheritance(criteriaId, entryId);
            }

            [Fact]
            public void ResetInheritance()
            {
                var criteriaId = Tests.Fixture.Integer();
                var entryId = Tests.Fixture.Short();
                var f = new Fixture(Db);
                f.Subject.ResetEntryInheritance(criteriaId, entryId);

                f.PermissionHelper.ReceivedWithAnyArgs(1).EnsureEditPermission(criteriaId);
                f.WorkflowEntryControlService.ReceivedWithAnyArgs(1).ResetEntryControl(criteriaId, entryId, false);
            }
        }

        public class GetRolesMethod : FactBase
        {
            [Fact]
            public void ReturnsRolesForAnEntry()
            {
                var role1 = new Role(Tests.Fixture.Integer()) {Description = Tests.Fixture.String()};
                var rolesControl1 = new RolesControl(Tests.Fixture.Integer(), Tests.Fixture.Integer(), Tests.Fixture.Short()) {Role = role1, Inherited = Tests.Fixture.Boolean()}.In(Db);

                var role2 = new Role(Tests.Fixture.Integer()) {Description = Tests.Fixture.String()};
                new RolesControl(Tests.Fixture.Integer(), rolesControl1.CriteriaId, rolesControl1.DataEntryTaskId) {Role = role2}.In(Db);

                new RolesControl(Tests.Fixture.Integer(), Tests.Fixture.Integer(), Tests.Fixture.Short()).In(Db);

                var f = new Fixture(Db);
                var result = f.Subject.GetUserAccess(rolesControl1.CriteriaId, rolesControl1.DataEntryTaskId).ToArray();

                Assert.Equal(2, result.Length);
                Assert.Equal(role1.Id, result[0].Key);
                Assert.Equal(role1.RoleName, result[0].Value);
                Assert.Equal(rolesControl1.Inherited, result[0].IsInherited);

                Assert.Equal(role2.Id, result[1].Key);
                Assert.Equal(role2.RoleName, result[1].Value);
                Assert.False(result[1].IsInherited);
            }
        }

        class Fixture : IFixture<WorkflowEntryControlController>
        {
            public Fixture(InMemoryDbContext db)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                WorkflowEntryControlService = Substitute.For<IWorkflowEntryControlService>();
                WorkflowEntryStepsService = Substitute.For<IWorkflowEntryStepsService>();
                WorkflowEntryDetailService = Substitute.For<IWorkflowEntryDetailService>();
                PermissionHelper = Substitute.For<IWorkflowPermissionHelper>();
                DescriptionValidator = Substitute.For<IDescriptionValidator>();
                Inheritance = Substitute.For<IInheritance>();
                DbContext = db;
                PermissionHelper.CanEdit(Arg.Any<Criteria>(), out _).ReturnsForAnyArgs(true);
                Subject = new WorkflowEntryControlController(DbContext, PreferredCultureResolver, WorkflowEntryControlService, WorkflowEntryStepsService, WorkflowEntryDetailService, PermissionHelper, Inheritance, DescriptionValidator);
            }

            IPreferredCultureResolver PreferredCultureResolver { get; }
            IDbContext DbContext { get; }
            public IWorkflowEntryControlService WorkflowEntryControlService { get; }
            public IWorkflowEntryStepsService WorkflowEntryStepsService { get; }
            public IWorkflowEntryDetailService WorkflowEntryDetailService { get; }
            public IWorkflowPermissionHelper PermissionHelper { get; }
            public IDescriptionValidator DescriptionValidator { get; }
            public IInheritance Inheritance { get; }
            public WorkflowEntryControlController Subject { get; }

            public Fixture WithUniqueDescription()
            {
                DescriptionValidator.IsDescriptionUnique(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<bool>()).Returns(true);
                return this;
            }
        }
    }
}