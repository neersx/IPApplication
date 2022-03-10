using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.DataEntryTasks.Validation;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.BatchEventUpdate;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate
{
    public class UpdatableCaseModelBuilderFacts
    {
        public class BuildForDynamicCycle : FactBase
        {
            public BuildForDynamicCycle()
            {
                _existingCase = new CaseBuilder().Build().In(Db);

                var dataEntryTaskCriteria = new CriteriaBuilder().WithAction().Build().In(Db);

                _existingDataEntryTask = DataEntryTaskBuilder.ForCriteria(dataEntryTaskCriteria).Build().In(Db);

                _controllingAvailableEvent =
                    AvailableEventBuilder.For(_existingDataEntryTask)
                                         .With(EventBuilder.ForCyclicEvent().Build().In(Db))
                                         .Build()
                                         .In(Db);

                _existingDataEntryTask.AvailableEvents.Add(_controllingAvailableEvent);

                _checkResult = new BatchDataEntryTaskPrerequisiteCheckResultBuilder().Build();

                _cycleSelection = Substitute.For<ICycleSelection>();
                _prepareAvailableEvents = Substitute.For<IPrepareAvailableEvents>();
                _warnOnlyRestrictionsBuilder = Substitute.For<IWarnOnlyRestrictionsBuilder>();
            }

            readonly BatchDataEntryTaskPrerequisiteCheckResult _checkResult;
            readonly AvailableEvent _controllingAvailableEvent;
            readonly ICycleSelection _cycleSelection;
            readonly Case _existingCase;
            readonly DataEntryTask _existingDataEntryTask;
            readonly IPrepareAvailableEvents _prepareAvailableEvents;
            readonly IWarnOnlyRestrictionsBuilder _warnOnlyRestrictionsBuilder;

            [Fact]
            public void CapturesOfficialNumberForGivenDataEntryTask()
            {
                var numberType = new NumberTypeBuilder().ForNumberTypeIssuedByIpOffice().Build().In(Db);
                numberType.Name = "a";

                _existingDataEntryTask.SetOfficialNumberType(numberType);

                var currentNumber = new OfficialNumberBuilder
                {
                    CaseId = _existingCase.Id,
                    NumberType = numberType,
                    OfficialNo = "123"
                }.AsCurrent().Build().In(Db);

                _existingCase.OfficialNumbers.Add(currentNumber);

                var result = new UpdatableCaseModelBuilder(
                                                           _cycleSelection,
                                                           _prepareAvailableEvents,
                                                           _warnOnlyRestrictionsBuilder)
                    .BuildForDynamicCycle(_existingCase, _existingDataEntryTask, _checkResult, false);

                Assert.Equal("a", result.OfficialNumberDescription);
                Assert.Equal("123", result.OfficialNumber);
            }

            [Fact]
            public void ChecksCycleIsCyclicalForTheDataEntryTaskCorrectly()
            {
                new UpdatableCaseModelBuilder(_cycleSelection, _prepareAvailableEvents, _warnOnlyRestrictionsBuilder)
                    .BuildForDynamicCycle(_existingCase, _existingDataEntryTask, _checkResult, false);

                _cycleSelection.Received().IsCyclicalFor(_controllingAvailableEvent, _existingDataEntryTask);
            }

            [Fact]
            public void CreatesUpdatableCaseModel()
            {
                _existingCase.Irn = "a";
                _existingCase.Title = "b";
                _existingCase.CurrentOfficialNumber = "c";

                var result = new UpdatableCaseModelBuilder(
                                                           _cycleSelection,
                                                           _prepareAvailableEvents,
                                                           _warnOnlyRestrictionsBuilder)
                    .BuildForDynamicCycle(_existingCase, _existingDataEntryTask, _checkResult, false);

                Assert.Equal("a", result.CaseReference);
                Assert.Equal("b", result.Title);
                Assert.Equal("c", result.CurrentOfficialNumber);
                Assert.Null(result.OfficialNumberDescription);
                Assert.Null(result.OfficialNumber);
            }

            [Fact]
            public void DeterminesControllingCycleCorrectly()
            {
                _cycleSelection.IsCyclicalFor(null, null).ReturnsForAnyArgs(true);
                _cycleSelection.DeriveControllingCycle(null, null, null, false).ReturnsForAnyArgs((short) 30);

                var result = new UpdatableCaseModelBuilder(
                                                           _cycleSelection,
                                                           _prepareAvailableEvents,
                                                           _warnOnlyRestrictionsBuilder)
                    .BuildForDynamicCycle(_existingCase, _existingDataEntryTask, _checkResult, false);

                Assert.Equal(30, result.ControllingCycle);
            }

            [Fact]
            public void DeterminesControllingCycleFromGivenActionCycle()
            {
                _cycleSelection.IsCyclicalFor(null, null).ReturnsForAnyArgs(true);
                _cycleSelection.DeriveControllingCycle(null, null, null, false).ReturnsForAnyArgs((short) 30);
                var cyclicAction = new ActionBuilder {NumberOfCyclesAllowed = 10}.Build().In(Db);
                var dataEntryTaskCriteria = new CriteriaBuilder().WithAction(cyclicAction).Build().In(Db);

                var dataEntryTask = DataEntryTaskBuilder.ForCriteria(dataEntryTaskCriteria).Build().In(Db);

                var controllingAvailableEvent =
                    AvailableEventBuilder.For(dataEntryTask)
                                         .With(EventBuilder.ForCyclicEvent().Build().In(Db))
                                         .Build()
                                         .In(Db);

                dataEntryTask.AvailableEvents.Add(controllingAvailableEvent);
                var result = new UpdatableCaseModelBuilder(
                                                           _cycleSelection,
                                                           _prepareAvailableEvents,
                                                           _warnOnlyRestrictionsBuilder)
                    .BuildForDynamicCycle(_existingCase, dataEntryTask, _checkResult, false, 2);

                Assert.Equal(2, result.ControllingCycle);
            }

            [Fact]
            public void PreparesAvailableEventsWithCorrectArguments()
            {
                new UpdatableCaseModelBuilder(_cycleSelection, _prepareAvailableEvents, _warnOnlyRestrictionsBuilder)
                    .BuildForDynamicCycle(_existingCase, _existingDataEntryTask, _checkResult, false);

                _prepareAvailableEvents.Received().For(_existingCase, _existingDataEntryTask, Arg.Any<short>());
            }

            [Fact]
            public void ReturnsCaseStatusCorrectly()
            {
                var status = new StatusBuilder
                {
                    Name = "b"
                }.Build().In(Db);

                _existingCase.CaseStatus = status;

                var result = new UpdatableCaseModelBuilder(
                                                           _cycleSelection,
                                                           _prepareAvailableEvents,
                                                           _warnOnlyRestrictionsBuilder)
                    .BuildForDynamicCycle(_existingCase, _existingDataEntryTask, _checkResult, false);

                Assert.Equal(status.Name, result.CaseStatusDescription);
            }

            [Fact]
            public void ReturnsRestrictionsCorrectly()
            {
                new UpdatableCaseModelBuilder(_cycleSelection, _prepareAvailableEvents, _warnOnlyRestrictionsBuilder)
                    .BuildForDynamicCycle(_existingCase, _existingDataEntryTask, _checkResult, false);

                _warnOnlyRestrictionsBuilder.Received().Build(_existingCase, _checkResult);
            }
        }
    }
}