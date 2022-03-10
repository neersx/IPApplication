using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowEventControlServiceResetEventControlFacts : FactBase
    {
        [Fact]
        public void CallsResetOnEachSectionAndUpdates()
        {
            var f = new WorkflowEventControlServiceFixture(Db);
            var @event = new EventBuilder().Build();
            var parent = new CriteriaBuilder().Build();
            parent.ValidEvents.Add(new ValidEventBuilder().For(parent, @event).Build());
            var parentDdc = new DueDateCalcBuilder().For(parent.ValidEvents.First()).Build();
            parent.ValidEvents.First().DueDateCalcs.Add(parentDdc);

            var criteria = new CriteriaBuilder().Build();
            criteria.ValidEvents.Add(new ValidEventBuilder().For(criteria, @event).Build());
            criteria.ValidEvents.First().IsInherited = false;
            var inheritedDdc = new DueDateCalcBuilder().For(criteria.ValidEvents.First()).Build().CopyFrom(parentDdc);
            parent.ValidEvents.First().DueDateCalcs.Add(inheritedDdc);
            new InheritsBuilder(parent, criteria).Build().In(Db);

            f.WorkflowEventInheritanceService.GenerateEventControlFieldsToUpdate(Arg.Any<WorkflowEventControlSaveModel>()).ReturnsForAnyArgs(new EventControlFieldsToUpdate());
            var updateDueDateCalcNameResp = Fixture.Boolean();
            var result = f.Subject.ResetEventControl(criteria.Id, @event.Id, false, updateDueDateCalcNameResp);

            Assert.Equal("success", result);

            foreach (var s in f.Sections)
                s.Received(1).Reset(Arg.Any<WorkflowEventControlSaveModel>(), parent.ValidEvents.First(), criteria.ValidEvents.First());

            // GetChildren is called within UpdateEventControl
            f.Inheritance.Received(1).GetChildren(criteria.Id);
            f.DbContext.Received(1).SaveChanges();

            // Reset Inheritance flag was set to reset inheritance flag on non-inherited items
            // Reset Responsible name on due dates flag was set according to passed in value
            f.WorkflowEventInheritanceService.Received(1).GenerateEventControlFieldsToUpdate(Arg.Is<WorkflowEventControlSaveModel>(_ => _.ResetInheritance && _.ChangeRespOnDueDates == updateDueDateCalcNameResp));

            Assert.True(criteria.ValidEvents.First().IsInherited);
        }

        [Fact]
        public void ReturnsIfUpdateCaseNameRespDecisionRequired()
        {
            var f = new WorkflowEventControlServiceFixture(Db);
            var @event = new EventBuilder().Build();
            var parent = new CriteriaBuilder().Build();
            parent.ValidEvents.Add(new ValidEventBuilder().For(parent, @event).Build());

            var criteria = new CriteriaBuilder().Build();
            criteria.ValidEvents.Add(new ValidEventBuilder().For(criteria, @event).Build());
            new InheritsBuilder(parent, criteria).Build().In(Db);
            parent.ValidEvents.First().DueDateRespNameTypeCode = "A";

            f.Subject.GetDueDatesForEventControl(criteria.Id, @event.Id).Returns(new[] {new CaseEventBuilder().Build()}.AsQueryable());
            var result = f.Subject.ResetEventControl(criteria.Id, @event.Id, false);

            Assert.Equal("updateNameRespOnCases", result);
        }

        [Fact]
        public void SetsDueDateRespTypeAccordingToParentData()
        {
            var f = new WorkflowEventControlServiceFixture(Db);
            var @event = new EventBuilder().Build();
            var parent = new CriteriaBuilder().Build();
            parent.ValidEvents.Add(new ValidEventBuilder().For(parent, @event).Build());

            var criteria = new CriteriaBuilder().Build();
            criteria.ValidEvents.Add(new ValidEventBuilder().For(criteria, @event).Build());
            criteria.ValidEvents.First().IsInherited = false;
            new InheritsBuilder(parent, criteria).Build().In(Db);

            f.WorkflowEventInheritanceService.GenerateEventControlFieldsToUpdate(Arg.Any<WorkflowEventControlSaveModel>()).ReturnsForAnyArgs(new EventControlFieldsToUpdate());

            f.Subject.ResetEventControl(criteria.Id, @event.Id, false, true);
            f.WorkflowEventInheritanceService.Received(1).GenerateEventControlFieldsToUpdate(Arg.Is<WorkflowEventControlSaveModel>(_ => _.ChangeRespOnDueDates && _.DueDateRespType == DueDateRespTypes.NotApplicable));

            parent.ValidEvents.First().DueDateRespNameTypeCode = "A";
            f.WorkflowEventInheritanceService.ClearReceivedCalls();
            f.Subject.ResetEventControl(criteria.Id, @event.Id, false, true);
            f.WorkflowEventInheritanceService.Received(1).GenerateEventControlFieldsToUpdate(Arg.Is<WorkflowEventControlSaveModel>(_ => _.ChangeRespOnDueDates && _.DueDateRespType == DueDateRespTypes.NameType));

            parent.ValidEvents.First().DueDateRespNameTypeCode = null;
            parent.ValidEvents.First().DueDateRespNameId = Fixture.Integer();
            f.WorkflowEventInheritanceService.ClearReceivedCalls();
            f.Subject.ResetEventControl(criteria.Id, @event.Id, false, true);
            f.WorkflowEventInheritanceService.Received(1).GenerateEventControlFieldsToUpdate(Arg.Is<WorkflowEventControlSaveModel>(_ => _.ChangeRespOnDueDates && _.DueDateRespType == DueDateRespTypes.Name));
        }
    }
}