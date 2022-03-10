using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Compatibility;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Documents;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowEntryControlServiceFacts : FactBase
    {
        [Theory]
        [InlineData(1, 1, true, true)]
        [InlineData(0, 1, false, true)]
        [InlineData(1, 0, true, false)]
        [InlineData(0, 0, false, false)]
        public async Task ReturnsIfHasInheritedParentOrHasInheritedChild(int inheritedFromParent, int inheritedChild, bool expectedHasParent, bool expectedHasChild)
        {
            var c = new CriteriaBuilder {UserDefinedRule = 0, Country = new CountryBuilder {Type = "1"}.Build()}.ForEventsEntriesRule().Build().In(Db);
            var e = new DataEntryTask(c.Id, 1)
            {
                Description = "b",
                Inherited = inheritedFromParent
            }.In(Db);

            var childInherit = new Inherits(Tests.Fixture.Integer(), c.Id).In(Db);
            childInherit.Criteria = new CriteriaBuilder {Id = childInherit.CriteriaNo, UserDefinedRule = 0, Country = new CountryBuilder {Type = "1"}.Build()}.ForEventsEntriesRule().Build();
            childInherit.Criteria.DataEntryTasks.Add(new DataEntryTask(childInherit.CriteriaNo, e.Id) {Description = "b", Inherited = inheritedChild});

            if (inheritedFromParent == 1)
            {
                var p = new CriteriaBuilder {UserDefinedRule = 0, Country = new CountryBuilder {Type = "1"}.Build()}.ForEventsEntriesRule().Build().In(Db);
                var pe = new DataEntryTask(p.Id, 1)
                {
                    Description = "b",
                    Inherited = 0
                }.In(Db);
                var inherits = new Inherits(c.Id, p.Id).In(Db);
                inherits.Criteria = c;
                inherits.FromCriteria = p;
                p.DataEntryTasks.Add(pe);
            }

            var f = new Fixture(Db);

            var r = await f.Subject.GetEntryControl(c.Id, e.Id);

            Assert.Equal(expectedHasParent, r.HasParent);
            Assert.Equal(expectedHasChild, r.HasChildren);
        }

        public class ResetEntryControlMethod : FactBase
        {
            [Fact]
            public void ReEstablishesInheritanceBasedOnFuzzyMatch()
            {
                var parentCriteria = new CriteriaBuilder().Build().In(Db);
                var parentEntry = new DataEntryTaskBuilder(parentCriteria, 1)
                {
                    Description = "Entry 1"
                }.Build().In(Db);
                parentCriteria.DataEntryTasks.Add(parentEntry);

                var resetCriteria = new CriteriaBuilder {ParentCriteriaId = parentCriteria.Id}.Build().In(Db);
                var resetEntry = new DataEntryTaskBuilder(resetCriteria, 1)
                {
                    Description = "Entry 1",
                    Inherited = 0
                }.Build().In(Db);
                resetCriteria.DataEntryTasks.Add(resetEntry);

                var f = new Fixture(Db);
                f.Inheritance.GetParentEntryWithFuzzyMatch(resetEntry).Returns(parentEntry);

                f.Subject.ResetEntryControl(resetCriteria.Id, resetEntry.Id, false);

                foreach (var section in f.SectionMaintenances) section.Received(1).Reset(resetEntry, parentEntry, Arg.Any<WorkflowEntryControlSaveModel>());

                f.Inheritance.Received(1).GetParentEntryWithFuzzyMatch(resetEntry);

                Assert.True(resetEntry.IsInherited);
                Assert.Equal(parentEntry.CriteriaId, resetEntry.ParentCriteriaId);
                Assert.Equal(parentEntry.Id, resetEntry.ParentEntryId);
            }

            [Fact]
            public void ResetsEachSectionAndUpdatesEntry()
            {
                var criteria = new CriteriaBuilder().Build().In(Db);
                var criteriaChild1 = new CriteriaBuilder {ParentCriteriaId = criteria.Id}.Build().In(Db);

                var parentEntry = new DataEntryTaskBuilder(criteria, 1)
                {
                    Description = "Parent Entry"
                }.BuildWithAvailableEvents(Db, "event1", "event2").In(Db);
                criteria.DataEntryTasks = new List<DataEntryTask> {parentEntry};

                var childEntry = new DataEntryTaskBuilder(criteriaChild1, 1)
                {
                    Description = "Child Entry",
                    ParentCriteriaId = criteria.Id,
                    ParentEntryId = parentEntry.Id
                }.BuildWithAvailableEvents(Db, "event3").In(Db);
                criteriaChild1.DataEntryTasks = new List<DataEntryTask> {childEntry};

                var f = new Fixture(Db);
                var applyToDescendants = Tests.Fixture.Boolean();
                f.Subject.ResetEntryControl(criteriaChild1.Id, childEntry.Id, applyToDescendants);

                foreach (var section in f.SectionMaintenances) section.Received(1).Reset(childEntry, parentEntry, Arg.Any<WorkflowEntryControlSaveModel>());

                f.WorkflowEntryDetailService.Received(1).UpdateEntryDetail(childEntry, Arg.Is<WorkflowEntryControlSaveModel>(_ =>
                                                                                                                                 _.CriteriaId == criteriaChild1.Id && _.Id == childEntry.Id && _.ResetInheritance && _.ApplyToDescendants == applyToDescendants));
            }
        }

        public class BreakEntryInheritance : FactBase
        {
            [Fact]
            public void BreakInheritance()
            {
                var criteria = new CriteriaBuilder().Build().In(Db);
                var criteriaChild1 = new CriteriaBuilder {ParentCriteriaId = criteria.Id}.Build().In(Db);

                var parentEntry = new DataEntryTaskBuilder(criteria, 1)
                {
                    Description = "Parent Entry"
                }.BuildWithAvailableEvents(Db, "event1", "event2").In(Db);
                criteria.DataEntryTasks = new List<DataEntryTask> {parentEntry};
                parentEntry.DocumentRequirements.Add(new DocumentRequirementBuilder
                {
                    Criteria = criteria,
                    DataEntryTask = parentEntry,
                    Inherited = 0
                }.Build().In(Db));
                parentEntry.DocumentRequirements.Add(new DocumentRequirementBuilder
                {
                    Criteria = criteria,
                    DataEntryTask = parentEntry,
                    Inherited = 0
                }.Build().In(Db));
                parentEntry.WithStep(Db, "frmStep1");
                parentEntry.WithStep(Db, "frmStep2");

                var event1 = parentEntry.AvailableEvents.ElementAt(0);
                var event2 = parentEntry.AvailableEvents.ElementAt(1);
                var doc1 = parentEntry.DocumentRequirements.ElementAt(0);
                var doc2 = parentEntry.DocumentRequirements.ElementAt(1);
                var parentStep1 = parentEntry.TaskSteps.First().TopicControls.ElementAt(0);
                var parentStep2 = parentEntry.TaskSteps.First().TopicControls.ElementAt(1);

                var childEntry = new DataEntryTaskBuilder(criteriaChild1, 1)
                {
                    Description = "Child Entry",
                    ParentCriteriaId = criteria.Id,
                    ParentEntryId = parentEntry.Id
                }.BuildWithAvailableEvents(Db, "event3").In(Db);
                criteriaChild1.DataEntryTasks = new List<DataEntryTask> {childEntry};
                childEntry.AvailableEvents.Add(new AvailableEvent().InheritRuleFrom(event1));
                childEntry.AvailableEvents.Add(new AvailableEvent().InheritRuleFrom(event2));
                childEntry.DocumentRequirements.Add(new DocumentRequirement().InheritRuleFrom(doc1));
                childEntry.DocumentRequirements.Add(new DocumentRequirement().InheritRuleFrom(doc2));
                childEntry.AddWorkflowWizardStep(parentStep1.InheritRuleFrom());
                childEntry.AddWorkflowWizardStep(parentStep2.InheritRuleFrom());

                var f = new Fixture(Db);

                f.Subject.BreakEntryControlInheritance(criteriaChild1.Id, childEntry.Id);

                var updatedEntry = Db.Set<DataEntryTask>().Single(_ => _.Id == childEntry.Id && _.CriteriaId == childEntry.CriteriaId);

                Assert.False(updatedEntry.IsInherited);
                Assert.Null(updatedEntry.ParentCriteriaId);
                Assert.Null(updatedEntry.ParentEntryId);

                Assert.Equal(3, updatedEntry.AvailableEvents.Count);
                Assert.Equal(2, updatedEntry.DocumentRequirements.Count);
                Assert.Equal(2, updatedEntry.TaskSteps.SelectMany(_ => _.TopicControls).Count());

                Assert.Equal(0, updatedEntry.AvailableEvents.Count(_ => _.IsInherited));
                Assert.Equal(0, updatedEntry.DocumentRequirements.Count(_ => _.IsInherited));
                Assert.Equal(0, updatedEntry.TaskSteps.SelectMany(_ => _.TopicControls).Count(_ => _.IsInherited));
            }
        }

        class Fixture : IFixture<WorkflowEntryControlService>
        {
            public Fixture(InMemoryDbContext db)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                PermissionHelper = Substitute.For<IWorkflowPermissionHelper>();
                Inheritance = Substitute.For<IInheritance>();
                SectionMaintenances = new[] {Substitute.For<ISectionMaintenance>(), Substitute.For<ISectionMaintenance>()};
                InprotechVersionChecker = Substitute.For<IInprotechVersionChecker>();
                InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).ReturnsForAnyArgs(true);
                WorkflowEntryDetailService = Substitute.For<IWorkflowEntryDetailService>();
                TaskSecurity = Substitute.For<ITaskSecurityProvider>();

                Subject = new WorkflowEntryControlService(db, PreferredCultureResolver, PermissionHelper, Inheritance, SectionMaintenances, InprotechVersionChecker, WorkflowEntryDetailService, TaskSecurity);
            }

            public IInheritance Inheritance { get; }

            public ITaskSecurityProvider TaskSecurity { get; }

            public IPreferredCultureResolver PreferredCultureResolver { get; }

            public IWorkflowPermissionHelper PermissionHelper { get; }

            public IEnumerable<ISectionMaintenance> SectionMaintenances { get; }

            public IInprotechVersionChecker InprotechVersionChecker { get; }

            public IWorkflowEntryDetailService WorkflowEntryDetailService { get; }

            public WorkflowEntryControlService Subject { get; }
        }

        [Fact]
        public async Task ReturnsBasicInfo()
        {
            var country = new CountryBuilder {Type = "1"}.Build().In(Db);
            var caseType = new CaseTypeBuilder().Build().In(Db);
            var propertyType = new PropertyTypeBuilder().Build().In(Db);

            var c = new CriteriaBuilder
            {
                UserDefinedRule = 0,
                Country = country,
                CaseType = caseType,
                PropertyType = propertyType
            }.ForEventsEntriesRule().Build().In(Db);

            var fileLocation = new TableCodeBuilder().For(TableTypes.FileLocation).Build().In(Db);
            var officialNumberType = new NumberTypeBuilder().Build().In(Db);
            var displayEvent = new Event(123).In(Db);
            var hideEvent = new Event(456).In(Db);
            var dimEvent = new Event(789).In(Db);
            var entry = new DataEntryTask(c.Id, 1)
            {
                Description = "a",
                UserInstruction = "b",
                FileLocationId = fileLocation.Id,
                FileLocation = fileLocation,
                OfficialNumberTypeId = officialNumberType.NumberTypeCode,
                OfficialNumberType = officialNumberType,
                ShouldPoliceImmediate = Tests.Fixture.Boolean(),
                CaseStatusCodeId = 1,
                CaseStatus = new Status(1, "s1"),
                RenewalStatusId = 2,
                RenewalStatus = new Status(1, "s2"),
                DisplayEventNo = displayEvent.Id,
                DisplayEvent = displayEvent,
                HideEventNo = hideEvent.Id,
                HideEvent = hideEvent,
                DimEventNo = dimEvent.Id,
                DimEvent = dimEvent
            }.In(Db);

            var f = new Fixture(Db);

            bool editBlockedByDescendants;
            f.PermissionHelper.CanEdit(Arg.Any<Criteria>(), out editBlockedByDescendants).ReturnsForAnyArgs(true);
            f.Inheritance.GetInheritanceLevel(c.Id, entry).Returns(InheritanceLevel.None);

            var showUserAccess = Tests.Fixture.Boolean();
            f.InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).ReturnsForAnyArgs(showUserAccess);

            var r = await f.Subject.GetEntryControl(c.Id, entry.Id);

            Assert.Equal(c.Id, r.CriteriaId);
            Assert.True(r.IsProtected);
            Assert.Equal(entry.Description, r.Description);
            Assert.Equal(entry.UserInstruction, r.UserInstruction);
            Assert.Equal(entry.OfficialNumberTypeId, r.OfficialNumberType.Key);
            Assert.Equal(entry.FileLocationId, r.FileLocation.Key);
            Assert.Equal(entry.ShouldPoliceImmediate, r.PoliceImmediately);
            Assert.Equal(entry.CaseStatus.Id, r.ChangeCaseStatus.Key);
            Assert.Equal(entry.CaseStatus.Name, r.ChangeCaseStatus.Value);
            Assert.Equal(entry.RenewalStatus.Id, r.ChangeRenewalStatus.Key);
            Assert.Equal(entry.RenewalStatus.Name, r.ChangeRenewalStatus.Value);
            Assert.Equal(entry.DisplayEventNo, r.DisplayEvent.Key);
            Assert.Equal(entry.HideEventNo, r.HideEvent.Key);
            Assert.Equal(entry.DimEventNo, r.DimEvent.Key);
            Assert.Equal(country.Id, r.Characteristics.Jurisdiction.Key);
            Assert.Equal(country.Name, r.Characteristics.Jurisdiction.Value);
            Assert.Equal(propertyType.Code, r.Characteristics.PropertyType.Key);
            Assert.Equal(propertyType.Name, r.Characteristics.PropertyType.Value);
            Assert.Equal(caseType.Code, r.Characteristics.CaseType.Key);
            Assert.Equal(caseType.Name, r.Characteristics.CaseType.Value);
            Assert.True(r.CanEdit);
            Assert.False(r.HasParent);
            Assert.False(r.HasChildren);
            Assert.Equal("None", r.InheritanceLevel);
            Assert.False(r.HasParentEntry);
            Assert.Equal(r.ShowUserAccess, showUserAccess);
        }

        [Fact]
        public async Task ReturnsPermissionRestrictionInformation()
        {
            var c = new CriteriaBuilder {UserDefinedRule = 0, Country = new CountryBuilder {Type = "1"}.Build()}.ForEventsEntriesRule().Build().In(Db);
            var entry = new DataEntryTask(c.Id, 1).In(Db);

            var f = new Fixture(Db);

            bool isEditBlockedByDescendants;
            f.PermissionHelper.CanEdit(c, out isEditBlockedByDescendants)
             .ReturnsForAnyArgs(_ =>
             {
                 _[1] = true;
                 return false;
             });

            var r = await f.Subject.GetEntryControl(c.Id, entry.Id);

            Assert.False(r.CanEdit);
            Assert.True(r.EditBlockedByDescendants);
        }
    }
}