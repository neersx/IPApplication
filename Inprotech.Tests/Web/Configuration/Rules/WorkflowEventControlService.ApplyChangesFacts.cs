using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowEventControlServiceApplyChangesFacts : FactBase
    {
        public WorkflowEventControlServiceApplyChangesFacts()
        {
            var baseEvent = new Event(Fixture.Integer());
            _parent = new CriteriaBuilder().Build().In(Db);
            _parentEvent = new ValidEventBuilder().For(_parent, baseEvent).Build().In(Db);
        }

        readonly Criteria _parent;
        readonly ValidEvent _parentEvent;

        [Theory]
        [InlineData(1, 1, 0)]
        [InlineData(1, 0, 1)]
        [InlineData(1, 0, 0)]
        [InlineData(0, 1, 1)]
        public void DoesNotCallUpdateDueDatesResponsibilityOnCaseEvents(int changeDueDateResp, int shouldInheritName, int shouldInheritNameType)
        {
            var subject = new WorkflowEventControlServiceFixture(Db).Subject;
            var shouldInherit = new EventControlFieldsToUpdate {DueDateRespNameId = shouldInheritName == 1, DueDateRespNameTypeCode = shouldInheritNameType == 1};
            var saveModel = new WorkflowEventControlSaveModel {ChangeRespOnDueDates = changeDueDateResp == 1};
            subject.ApplyChanges(_parentEvent, saveModel, shouldInherit, null);
        }

        [Fact]
        public void CallsUpdateDueDatesResponsibilityOnCaseEvents()
        {
            var subject = new WorkflowEventControlServiceFixture(Db).Subject;
            var shouldInherit = new EventControlFieldsToUpdate {DueDateRespNameId = true, DueDateRespNameTypeCode = true};
            var saveModel = new WorkflowEventControlSaveModel {ChangeRespOnDueDates = true};
            subject.ApplyChanges(_parentEvent, saveModel, shouldInherit, null);

            subject.Received(1).UpdateDueDatesResponsibilityOnCaseEvents(_parent.Id, _parentEvent.EventId, saveModel);
        }

        [Fact]
        public void ResetsDatesLogicComparisonType()
        {
            var subject = new WorkflowEventControlServiceFixture(Db).Subject;
            var saveModel = new WorkflowEventControlSaveModel
            {
                ApplyToDescendants = false,
                DatesLogicComparisonType = DatesLogicComparisonType.All
            };

            var shouldInherit = new EventControlFieldsToUpdate();

            _parentEvent.DatesLogicComparisonType = DatesLogicComparisonType.All;
            _parentEvent.DueDateCalcs = new DueDateCalc[0];
            subject.ApplyChanges(_parentEvent, saveModel, shouldInherit, null);

            Assert.Equal(DatesLogicComparisonType.Any, _parentEvent.DatesLogicComparisonType);
        }
    }
}