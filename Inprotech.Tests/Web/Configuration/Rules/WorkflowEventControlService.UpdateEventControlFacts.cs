using System;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowEventControlServiceUpdateEventControlFacts : FactBase
    {
        public WorkflowEventControlServiceUpdateEventControlFacts()
        {
            var f = new WorkflowEventControlServiceFixture(Db);
            _workflowEventInheritanceService = f.WorkflowEventInheritanceService;
            _inheritance = f.Inheritance;
            _subject = Substitute.ForPartsOf<WorkflowEventControlService>(f.DbContext, f.PreferredCultureResolver, f.PermissionHelper, f.Inheritance, f.WorkflowEventInheritanceService, f.InprotechVersionChecker, f.Sections, f.TaskSecurity, f.CharacteristicsServiceIndex);
            _baseEvent = new Event(Fixture.Integer());
            _parent = new CriteriaBuilder().Build().In(Db);
            _parentEvent = new ValidEventBuilder().For(_parent, _baseEvent).Build().In(Db);
        }

        readonly Event _baseEvent;
        readonly Criteria _parent;
        readonly ValidEvent _parentEvent;

        readonly WorkflowEventControlService _subject;
        readonly IWorkflowEventInheritanceService _workflowEventInheritanceService;
        readonly IInheritance _inheritance;

        [Theory]
        [InlineData(1)]
        [InlineData(0)]
        public void RecursivelyNavigatesTreeInheritingEventsIfApplyingToDescendants(int applyToDescendants)
        {
            var child1 = new CriteriaBuilder().Build().In(Db);
            var child1Event = new ValidEventBuilder {Inherited = true}.For(child1, _baseEvent).Build().In(Db);
            child1.ValidEvents.Add(child1Event);
            var child2 = new CriteriaBuilder().Build().In(Db);
            var child2Event = new ValidEventBuilder {Inherited = true}.For(child2, _baseEvent).Build().In(Db);
            child2.ValidEvents.Add(child2Event);
            var children = new[] {child1, child2};
            _inheritance.GetChildren(_parent.Id).Returns(children);

            var saveModel = new WorkflowEventControlSaveModel {ApplyToDescendants = applyToDescendants == 1};
            var shouldInherit = new EventControlFieldsToUpdate {Description = true, NumberOfCyclesAllowed = true, Notes = false, PtaDelay = true};

            _subject.UpdateEventControl(_parentEvent, saveModel, shouldInherit);

            Func<EventControlFieldsToUpdate, bool> isCopyOfShouldInherit = _ => _.Description && _.NumberOfCyclesAllowed && !_.Notes && _.PtaDelay && _ != shouldInherit;
            _workflowEventInheritanceService.Received(applyToDescendants).SetInheritedFieldsToUpdate(child1Event, _parentEvent, Arg.Is<EventControlFieldsToUpdate>(_ => isCopyOfShouldInherit(_)), saveModel);
            _subject.Received(applyToDescendants).ApplyChanges(child1Event, saveModel, Arg.Is<EventControlFieldsToUpdate>(_ => isCopyOfShouldInherit(_)), Arg.Any<Criteria[]>());

            _workflowEventInheritanceService.Received(applyToDescendants).SetInheritedFieldsToUpdate(child2Event, _parentEvent, Arg.Is<EventControlFieldsToUpdate>(_ => isCopyOfShouldInherit(_)), saveModel);
            _subject.Received(applyToDescendants).ApplyChanges(child2Event, saveModel, Arg.Is<EventControlFieldsToUpdate>(_ => isCopyOfShouldInherit(_)), Arg.Any<Criteria[]>());

            _subject.Received(1).ApplyChanges(_parentEvent, saveModel, shouldInherit, children);

            _subject.Received(1).SetUpdatedValuesForEvent(_parentEvent, saveModel, shouldInherit);
        }

        [Fact]
        public void SkipsIfChildEventNotInherited()
        {
            var child1 = new CriteriaBuilder().Build().In(Db);
            var child1Event = new ValidEventBuilder {Inherited = false}.For(child1, _baseEvent).Build().In(Db);
            child1.ValidEvents.Add(child1Event);
            var child2 = new CriteriaBuilder().Build().In(Db);
            var child2Event = new ValidEventBuilder {Inherited = true}.For(child2, _baseEvent).Build().In(Db);
            child2.ValidEvents.Add(child2Event);
            var child3 = new CriteriaBuilder().Build().In(Db);
            var child3Event = new ValidEventBuilder {Inherited = true}.For(child3, new Event(Fixture.Integer())).Build().In(Db);
            child3.ValidEvents.Add(child3Event);

            _inheritance.GetChildren(_parent.Id).Returns(new[] {child1, child2, child3});

            var saveModel = new WorkflowEventControlSaveModel {ApplyToDescendants = true};
            _subject.UpdateEventControl(_parentEvent, saveModel, new EventControlFieldsToUpdate());

            _workflowEventInheritanceService.DidNotReceive().SetInheritedFieldsToUpdate(child1Event, _parentEvent, Arg.Any<EventControlFieldsToUpdate>(), saveModel);
            _workflowEventInheritanceService.Received(1).SetInheritedFieldsToUpdate(child2Event, _parentEvent, Arg.Any<EventControlFieldsToUpdate>(), saveModel);
            _workflowEventInheritanceService.DidNotReceive().SetInheritedFieldsToUpdate(child3Event, _parentEvent, Arg.Any<EventControlFieldsToUpdate>(), saveModel);
        }
    }
}