using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.BatchEventUpdate;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate
{
    public class PrepareAvailableEventFacts
    {
        public class ForMethod : FactBase
        {
            public ForMethod()
            {
                _existingCase = new CaseBuilder().Build().In(Db);

                _existingDataEntryTask =
                    new DataEntryTaskBuilder
                    {
                        Criteria = new CriteriaBuilder().Build().In(Db)
                    }.Build().In(Db);

                _anAvailableEvent = AvailableEventBuilder
                                    .For(_existingDataEntryTask)
                                    .With(EventBuilder.ForCyclicEvent().Build().In(Db)).Build().In(Db);

                _existingDataEntryTask.AvailableEvents.Add(_anAvailableEvent);

                _getOrCreateCaseEvent = Substitute.For<IGetOrCreateCaseEvent>();

                _getOrCreateCaseEvent.For(null, null, null, 0)
                                     .ReturnsForAnyArgs(
                                                        c =>
                                                            new CaseEvent(
                                                                          ((Case) c.Args()[0]).Id,
                                                                          ((AvailableEvent) c.Args()[2]).Event.Id,
                                                                          (short) c.Args()[3]));

                _cycleSelection = Substitute.For<ICycleSelection>();
            }

            readonly AvailableEvent _anAvailableEvent;
            readonly ICycleSelection _cycleSelection;
            readonly Case _existingCase;
            readonly DataEntryTask _existingDataEntryTask;
            readonly IGetOrCreateCaseEvent _getOrCreateCaseEvent;

            [Fact]
            public void ReturnsAvailableEvents()
            {
                var result = new PrepareAvailableEvents(_getOrCreateCaseEvent, _cycleSelection)
                             .For(_existingCase, _existingDataEntryTask, 1).ToArray();

                Assert.Equal(1, result.Single().Cycle);
                Assert.Equal(_anAvailableEvent.Event.Id, result.Single().EventId);
            }

            [Fact]
            public void ReturnsEventsInDisplayOrder()
            {
                var otherAe = AvailableEventBuilder
                              .For(_existingDataEntryTask)
                              .With(EventBuilder.ForCyclicEvent().Build().In(Db))
                              .Build();

                otherAe.DisplaySequence = 1;
                _anAvailableEvent.DisplaySequence = 2;

                _existingDataEntryTask.AvailableEvents.Add(otherAe);

                var result = new PrepareAvailableEvents(_getOrCreateCaseEvent, _cycleSelection)
                             .For(_existingCase, _existingDataEntryTask, 1).ToArray();

                Assert.Equal(otherAe.Event.Id, result.First().EventId);
                Assert.Equal(_anAvailableEvent.Event.Id, result.Last().EventId);
            }

            [Fact]
            public void SetsIsCyclicValueCorrectly()
            {
                _cycleSelection.IsCyclicalFor(null, null).ReturnsForAnyArgs(true);

                var result = new PrepareAvailableEvents(_getOrCreateCaseEvent, _cycleSelection)
                    .For(_existingCase, _existingDataEntryTask, 1);

                Assert.True(result.Single().IsCyclic);
            }

            [Fact]
            public void UsesValidEventDescriptionRatherThanItsDefault()
            {
                var controllingCycle = Fixture.Short();

                const string criteriaSpecificEventDescription = "a";
                _anAvailableEvent.Event.Description = "b";

                _existingDataEntryTask.Criteria.ValidEvents.Add(
                                                                new ValidEvent(
                                                                               _existingDataEntryTask.Criteria,
                                                                               _anAvailableEvent.Event,
                                                                               criteriaSpecificEventDescription
                                                                              ));

                var result = new PrepareAvailableEvents(_getOrCreateCaseEvent, _cycleSelection)
                             .For(_existingCase, _existingDataEntryTask, controllingCycle).ToArray();

                Assert.Same(criteriaSpecificEventDescription, result.Single().EventDescription);
            }
        }
    }
}