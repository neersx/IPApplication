using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowInheritanceServiceFacts : FactBase
    {
        public class BreakInheritanceFacts : FactBase
        {
            public class BreakEntryInheritanceMethod : FactBase
            {
                public BreakEntryInheritanceMethod()
                {
                    _serviceFixture = new WorkflowInheritanceServiceFixture(Db);

                    _criteria = new CriteriaBuilder {ParentCriteriaId = Fixture.Integer()}.Build().In(Db);
                }

                readonly Criteria _criteria;
                readonly WorkflowInheritanceServiceFixture _serviceFixture;

                [Fact]
                public void SetInheritedFlagFalseForDetails()
                {
                    _criteria.DataEntryTasks = new[]
                    {
                        DataEntryTaskBuilder.ForCriteria(_criteria).WithParentInheritance().BuildWithAvailableEvents(Db, 2),
                        DataEntryTaskBuilder.ForCriteria(_criteria).WithParentInheritance().BuildWithAvailableEvents(Db, 2)
                    }.In(Db);

                    _serviceFixture.Subject.BreakEntriesInheritance(_criteria.Id);

                    var availableEvents = _serviceFixture.DbContext.Set<AvailableEvent>().Where(_ => _.CriteriaId == _criteria.Id);
                    Assert.Equal(4, availableEvents.Count());
                    Assert.True(availableEvents.All(_ => !_.IsInherited));
                }

                [Fact]
                public void SetInheritedFlagFalseForDocuments()
                {
                    _criteria.DataEntryTasks = new[]
                    {
                        DataEntryTaskBuilder.ForCriteria(_criteria).WithParentInheritance().BuildWithDocuments(Db, 2),
                        DataEntryTaskBuilder.ForCriteria(_criteria).WithParentInheritance().BuildWithDocuments(Db, 2)
                    }.In(Db);

                    _serviceFixture.Subject.BreakEntriesInheritance(_criteria.Id);

                    var documents = _serviceFixture.DbContext.Set<DocumentRequirement>().Where(_ => _.CriteriaId == _criteria.Id);
                    Assert.Equal(4, documents.Count());
                    Assert.True(documents.All(_ => _.Inherited == 0));
                }

                [Fact]
                public void SetInheritedFlagFalseForGroupsAllowed()
                {
                    _criteria.DataEntryTasks = new[]
                    {
                        DataEntryTaskBuilder.ForCriteria(_criteria).WithParentInheritance().BuildWithGroupControls(Db, 2),
                        DataEntryTaskBuilder.ForCriteria(_criteria).WithParentInheritance().BuildWithGroupControls(Db, 2)
                    }.In(Db);

                    _serviceFixture.Subject.BreakEntriesInheritance(_criteria.Id);

                    var groups = _serviceFixture.DbContext.Set<GroupControl>().Where(_ => _.CriteriaId == _criteria.Id);
                    Assert.Equal(4, groups.Count());
                    Assert.True(groups.All(_ => _.Inherited == 0));
                }

                [Fact]
                public void SetInheritedFlagFalseForSteps()
                {
                    _criteria.DataEntryTasks = new[]
                    {
                        DataEntryTaskBuilder.ForCriteria(_criteria).WithParentInheritance().BuildWithSteps(Db, 2),
                        DataEntryTaskBuilder.ForCriteria(_criteria).WithParentInheritance().BuildWithSteps(Db, 2)
                    }.In(Db);

                    _serviceFixture.Subject.BreakEntriesInheritance(_criteria.Id);

                    var steps = _serviceFixture.DbContext.Set<WindowControl>().Where(_ => _.CriteriaId == _criteria.Id).SelectMany(_ => _.TopicControls);
                    Assert.Equal(4, steps.Count());
                    Assert.True(steps.All(_ => !_.IsInherited));
                }

                [Fact]
                public void SetInheritedFlagFalseForUsersAllowed()
                {
                    _criteria.DataEntryTasks = new[]
                    {
                        DataEntryTaskBuilder.ForCriteria(_criteria).WithParentInheritance().BuildWithUserControls(Db, 2),
                        DataEntryTaskBuilder.ForCriteria(_criteria).WithParentInheritance().BuildWithUserControls(Db, 2)
                    }.In(Db);

                    _serviceFixture.Subject.BreakEntriesInheritance(_criteria.Id);

                    var users = _serviceFixture.DbContext.Set<UserControl>().Where(_ => _.CriteriaNo == _criteria.Id);
                    Assert.Equal(4, users.Count());
                    Assert.True(users.All(_ => _.IsInherited == false));
                }

                [Fact]
                public void SetsEntriesInheritedFlagFalseParentCriteriaAndParentEntryToNull()
                {
                    _criteria.DataEntryTasks = new[]
                    {
                        DataEntryTaskBuilder.ForCriteria(_criteria).WithParentInheritance().Build().In(Db),
                        DataEntryTaskBuilder.ForCriteria(_criteria).WithParentInheritance().Build().In(Db)
                    };

                    _serviceFixture.Subject.BreakEntriesInheritance(_criteria.Id);

                    var entries = _serviceFixture.DbContext.Set<DataEntryTask>().Where(_ => _.CriteriaId == _criteria.Id);
                    Assert.Equal(2, entries.Count());
                    Assert.True(entries.All(_ => _.Inherited == 0));
                    Assert.True(entries.All(_ => _.ParentCriteriaId == null));
                    Assert.True(entries.All(_ => _.ParentEntryId == null));
                }
            }

            [Fact]
            public void RemovesInheritanceFromCriteria()
            {
                var f = new WorkflowInheritanceServiceFixture(Db);
                var criteria = new CriteriaBuilder {ParentCriteriaId = 123}.Build().In(Db);
                new InheritsBuilder(criteria.Id, criteria.ParentCriteriaId.Value) {Criteria = criteria}.Build().In(Db);

                f.Subject.BreakInheritance(criteria.Id);

                Assert.False(f.DbContext.Set<Inherits>().Any(_ => _.CriteriaNo == criteria.Id));
                Assert.Null(criteria.ParentCriteriaId);

                f.WorkflowEventInheritanceService.Received(1).BreakEventsInheritance(criteria.Id);
            }
        }

        public class PushDownInheritanceTreeMethod : FactBase
        {
            [Fact]
            public void RecursivelyNavigatesTreeAndInheritsEventsAndEntries()
            {
                var f = new WorkflowInheritanceServiceFixture(Db);
                var subject = Substitute.ForPartsOf<WorkflowInheritanceService>(f.DbContext, f.PreferredCultureResolver, f.WorkflowEventInheritanceService, f.WorkflowEntryInheritanceService,
                                                                                f.WorkflowEventControlService, f.ValidEventService, f.WorkflowEntryControlService, f.EntryService, f.Inheritance);

                var criteria = new CriteriaBuilder().Build();
                var @event = new EventBuilder().Build();

                var childCriteria1 = new CriteriaBuilder().Build().In(Db);
                var childCriteria2 = new CriteriaBuilder().Build().In(Db);
                var grandChildCriteria = new CriteriaBuilder().Build().In(Db);

                new InheritsBuilder(criteria, childCriteria1).Build().In(Db);
                new InheritsBuilder(criteria, childCriteria2).Build().In(Db);
                new InheritsBuilder(childCriteria2, grandChildCriteria).Build().In(Db);

                criteria.ValidEvents = new[]
                {
                    new ValidEventBuilder().For(criteria, @event).Build(),
                    new ValidEventBuilder().For(criteria, null).Build()
                };
                criteria.DataEntryTasks = new[] {new DataEntryTaskBuilder().Build()};

                var child1InheritedEvents = new[] {new ValidEventBuilder().For(childCriteria1, @event).Build()};
                var child2InheritedEvents = new[] {new ValidEventBuilder().For(childCriteria2, @event).Build()};
                var child1InheritedEntries = new[] {new DataEntryTaskBuilder().Build()};
                var child2InheritedEntries = new[] {new DataEntryTaskBuilder().Build()};

                f.Inheritance.GetChildren(criteria.Id).Returns(new[] {childCriteria1, childCriteria2});
                f.Inheritance.GetChildren(childCriteria2.Id).Returns(new[] {grandChildCriteria});

                f.WorkflowEventInheritanceService.InheritNewEventRules(Arg.Is(childCriteria1), Arg.Any<IEnumerable<ValidEvent>>(), Arg.Any<bool>()).Returns(child1InheritedEvents);
                f.WorkflowEventInheritanceService.InheritNewEventRules(Arg.Is(childCriteria2), Arg.Any<IEnumerable<ValidEvent>>(), Arg.Any<bool>()).Returns(child2InheritedEvents);
                f.WorkflowEntryInheritanceService.InheritNewEntries(Arg.Is(childCriteria1), Arg.Any<IEnumerable<DataEntryTask>>(), Arg.Any<bool>()).Returns(child1InheritedEntries);
                f.WorkflowEntryInheritanceService.InheritNewEntries(Arg.Is(childCriteria2), Arg.Any<IEnumerable<DataEntryTask>>(), Arg.Any<bool>()).Returns(child2InheritedEntries);
                f.WorkflowEntryInheritanceService.InheritNewEntries(Arg.Is(grandChildCriteria), Arg.Any<IEnumerable<DataEntryTask>>(), Arg.Any<bool>()).Returns(new DataEntryTask[0]);

                var replaceCommonRules = Fixture.Boolean();
                subject.PushDownInheritanceTree(criteria.Id, criteria.ValidEvents, criteria.DataEntryTasks, replaceCommonRules);

                // child criteria get valid events inherited by main event
                f.WorkflowEventInheritanceService.Received(1).InheritNewEventRules(Arg.Is(childCriteria1), Arg.Is(criteria.ValidEvents), replaceCommonRules);
                f.WorkflowEventInheritanceService.Received(1).InheritNewEventRules(Arg.Is(childCriteria2), Arg.Is(criteria.ValidEvents), replaceCommonRules);
                f.WorkflowEntryInheritanceService.Received(1).InheritNewEntries(Arg.Is(childCriteria1), Arg.Is(criteria.DataEntryTasks), replaceCommonRules);
                f.WorkflowEntryInheritanceService.Received(1).InheritNewEntries(Arg.Is(childCriteria2), Arg.Is(criteria.DataEntryTasks), replaceCommonRules);

                // subsequent children get valid events inherited by child criteria
                f.WorkflowEventInheritanceService.Received(1).InheritNewEventRules(Arg.Is(grandChildCriteria), Arg.Is(child2InheritedEvents), replaceCommonRules);
                f.WorkflowEntryInheritanceService.Received(1).InheritNewEntries(Arg.Is(grandChildCriteria), Arg.Is(child2InheritedEntries), replaceCommonRules);
            }
        }

        public class ResetEventControlMethod : FactBase
        {
            public ResetEventControlMethod()
            {
                Parent = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                Criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new InheritsBuilder(Parent, Criteria).Build().In(Db);
            }

            Criteria Parent { get; }
            Criteria Criteria { get; }

            [Fact]
            public void AddsAndResetsEventsInParentNotInChild()
            {
                var f = new WorkflowInheritanceServiceFixture(Db);

                var @event = new EventBuilder().Build();
                var parentEvent = new ValidEventBuilder {DisplaySequence = 9}.For(Parent, @event).Build().In(Db);

                var event1 = new EventBuilder().Build();
                var parentEvent1 = new ValidEventBuilder {DisplaySequence = 1}.For(Parent, event1).Build().In(Db);
                Parent.ValidEvents.AddRange(new[] {parentEvent, parentEvent1});

                var applyToDescendants = Fixture.Boolean();

                f.Subject.ResetEventControl(Criteria, applyToDescendants, false, Parent);

                f.ValidEventService.Received(1).AddEvent(Criteria.Id, @event.Id, null, applyToDescendants);
                f.ValidEventService.Received(1).AddEvent(Criteria.Id, event1.Id, null, applyToDescendants);
                f.WorkflowEventControlService.Received(1).ResetEventControl(Criteria.Id, @event.Id, applyToDescendants, false);
                f.WorkflowEventControlService.Received(1).ResetEventControl(Criteria.Id, event1.Id, applyToDescendants, false);
            }

            [Fact]
            public void DeletesExtraEvents()
            {
                var f = new WorkflowInheritanceServiceFixture(Db);

                var @event = new EventBuilder().Build();
                var childEvent = new ValidEventBuilder().For(Criteria, @event).Build().In(Db);

                var event1 = new EventBuilder().Build();
                var childEvent1 = new ValidEventBuilder().For(Criteria, event1).Build().In(Db);
                Criteria.ValidEvents.AddRange(new[] {childEvent, childEvent1});

                var applyToDescendants = Fixture.Boolean();

                f.Subject.ResetEventControl(Criteria, applyToDescendants, true, Parent);

                f.ValidEventService.Received(1).DeleteEvents(Criteria.Id, Arg.Is<int[]>(_ => _.Contains(@event.Id) && _.Contains(event1.Id)), applyToDescendants);
                f.ValidEventService.Received(0).AddEvent(Arg.Any<int>(), Arg.Any<int>(), Arg.Any<int?>(), Arg.Any<bool>());
                f.WorkflowEventControlService.Received(0).ResetEventControl(Arg.Any<int>(), Arg.Any<int>(), Arg.Any<bool>(), Arg.Any<bool>());
            }

            [Fact]
            public void ResetsCommonEventsAndSetsDisplaySequence()
            {
                var f = new WorkflowInheritanceServiceFixture(Db);

                var @event = new EventBuilder().Build();
                var parentEvent = new ValidEventBuilder {DisplaySequence = 9}.For(Parent, @event).Build().In(Db);
                var childEvent = new ValidEventBuilder().For(Criteria, @event).Build().In(Db);

                var event1 = new EventBuilder().Build();
                var parentEvent1 = new ValidEventBuilder {DisplaySequence = 1}.For(Parent, event1).Build().In(Db);
                var childEvent1 = new ValidEventBuilder().For(Criteria, event1).Build().In(Db);
                Parent.ValidEvents.AddRange(new[] {parentEvent, parentEvent1});
                Criteria.ValidEvents.AddRange(new[] {childEvent, childEvent1});

                var applyToDescendants = Fixture.Boolean();
                var updateRespNameOnCases = Fixture.Boolean();

                f.Subject.ResetEventControl(Criteria, applyToDescendants, updateRespNameOnCases, Parent);

                f.WorkflowEventControlService.Received(1).ResetEventControl(Criteria.Id, @event.Id, applyToDescendants, updateRespNameOnCases);
                f.WorkflowEventControlService.Received(1).ResetEventControl(Criteria.Id, event1.Id, applyToDescendants, updateRespNameOnCases);
                f.ValidEventService.Received(0).AddEvent(Arg.Any<int>(), Arg.Any<int>(), Arg.Any<int?>(), Arg.Any<bool>());

                Assert.Equal((short) 9, Criteria.ValidEvents.Single(_ => _.EventId == @event.Id).DisplaySequence);
                Assert.Equal((short) 1, Criteria.ValidEvents.Single(_ => _.EventId == event1.Id).DisplaySequence);
            }
        }

        public class ResetEntriesControlMethod : FactBase
        {
            public ResetEntriesControlMethod()
            {
                Parent = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                Criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                new InheritsBuilder(Parent, Criteria).Build().In(Db);
            }

            Criteria Parent { get; }
            Criteria Criteria { get; }

            [Fact]
            public void AddsAndResetsEntriesInParentNotInChild()
            {
                var f = new WorkflowInheritanceServiceFixture(Db);

                var parentEntry = new DataEntryTaskBuilder {DisplaySequence = 9}.Build().In(Db);
                var parentEntry1 = new DataEntryTaskBuilder {DisplaySequence = 1}.Build().In(Db);
                Parent.DataEntryTasks.AddRange(new[] {parentEntry, parentEntry1});

                var applyToDescendants = Fixture.Boolean();

                f.Inheritance.HasSingleEntryMatch(null, null).ReturnsForAnyArgs(false);

                f.EntryService.AddEntry(Criteria.Id, parentEntry.Description, null, applyToDescendants, parentEntry.IsSeparator).Returns(new {Id = 1});
                f.EntryService.AddEntry(Criteria.Id, parentEntry1.Description, null, applyToDescendants, parentEntry1.IsSeparator).Returns(new {Id = 2});

                f.Subject.ResetEntries(Criteria, applyToDescendants, Parent);

                f.EntryService.Received(1).AddEntry(Criteria.Id, parentEntry.Description, null, applyToDescendants, parentEntry.IsSeparator);
                f.EntryService.Received(1).AddEntry(Criteria.Id, parentEntry1.Description, null, applyToDescendants, parentEntry.IsSeparator);
                f.WorkflowEntryControlService.Received(1).ResetEntryControl(Criteria.Id, 1, applyToDescendants);
                f.WorkflowEntryControlService.Received(1).ResetEntryControl(Criteria.Id, 2, applyToDescendants);
            }

            [Fact]
            public void DeletesExtraEntries()
            {
                var f = new WorkflowInheritanceServiceFixture(Db);

                var childEntry = new DataEntryTaskBuilder().Build().In(Db);
                var childEntry1 = new DataEntryTaskBuilder().Build().In(Db);
                Criteria.DataEntryTasks.AddRange(new[] {childEntry, childEntry1});

                var applyToDescendants = Fixture.Boolean();

                f.Inheritance.HasSingleEntryMatch(null, null).ReturnsForAnyArgs(false);

                f.Subject.ResetEntries(Criteria, applyToDescendants, Parent);

                f.EntryService.Received(1).DeleteEntries(Criteria.Id, Arg.Is<short[]>(_ => _.Contains(childEntry.Id) && _.Contains(childEntry1.Id)), applyToDescendants);
                f.EntryService.Received(0).AddEntry(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int?>(), Arg.Any<bool>(), Arg.Any<bool>());
                f.WorkflowEntryControlService.Received(0).ResetEntryControl(Arg.Any<int>(), Arg.Any<int>(), Arg.Any<bool>());
            }

            [Fact]
            public void ResetsCommonEntriesAndSetsDisplaySequence()
            {
                var f = new WorkflowInheritanceServiceFixture(Db);

                var parentEntry = new DataEntryTaskBuilder {DisplaySequence = 9}.Build().In(Db);
                var parentEntry1 = new DataEntryTaskBuilder {DisplaySequence = 1}.Build().In(Db);
                Parent.DataEntryTasks.AddRange(new[] {parentEntry, parentEntry1});

                var childEntry = new DataEntryTaskBuilder {Description = parentEntry.Description}.Build().In(Db);
                var childEntry1 = new DataEntryTaskBuilder {Description = parentEntry1.Description}.Build().In(Db);
                Criteria.DataEntryTasks.AddRange(new[] {childEntry, childEntry1});

                var applyToDescendants = Fixture.Boolean();

                f.Inheritance.HasSingleEntryMatch(null, null).ReturnsForAnyArgs(true);

                f.Subject.ResetEntries(Criteria, applyToDescendants, Parent);

                f.WorkflowEntryControlService.Received(1).ResetEntryControl(Criteria.Id, childEntry.Id, applyToDescendants);
                f.WorkflowEntryControlService.Received(1).ResetEntryControl(Criteria.Id, childEntry1.Id, applyToDescendants);
                f.EntryService.Received(0).AddEntry(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int?>(), Arg.Any<bool>());

                Assert.Equal((short) 9, childEntry.DisplaySequence);
                Assert.Equal((short) 1, childEntry1.DisplaySequence);
            }
        }
    }

    public class WorkflowInheritanceServiceFixture : IFixture<WorkflowInheritanceService>
    {
        public WorkflowInheritanceServiceFixture(InMemoryDbContext db)
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            DbContext = db;
            WorkflowPermissionHelper = Substitute.For<IWorkflowPermissionHelper>();
            WorkflowEventInheritanceService = Substitute.For<IWorkflowEventInheritanceService>();
            WorkflowEntryInheritanceService = Substitute.For<IWorkflowEntryInheritanceService>();

            WorkflowEventControlService = Substitute.For<IWorkflowEventControlService>();
            ValidEventService = Substitute.For<IValidEventService>();
            WorkflowEntryControlService = Substitute.For<IWorkflowEntryControlService>();
            EntryService = Substitute.For<IEntryService>();
            Inheritance = Substitute.For<IInheritance>();

            Subject = new WorkflowInheritanceService(DbContext, PreferredCultureResolver, WorkflowEventInheritanceService, WorkflowEntryInheritanceService,
                                                     WorkflowEventControlService, ValidEventService, WorkflowEntryControlService, EntryService, Inheritance);
        }

        public IDbContext DbContext { get; set; }
        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public IWorkflowPermissionHelper WorkflowPermissionHelper { get; set; }
        public IWorkflowEventInheritanceService WorkflowEventInheritanceService { get; set; }
        public IWorkflowEntryInheritanceService WorkflowEntryInheritanceService { get; set; }

        public IWorkflowEventControlService WorkflowEventControlService { get; set; }
        public IValidEventService ValidEventService { get; set; }
        public IWorkflowEntryControlService WorkflowEntryControlService { get; set; }
        public IEntryService EntryService { get; set; }
        public IInheritance Inheritance { get; set; }
        public WorkflowInheritanceService Subject { get; set; }
    }
}