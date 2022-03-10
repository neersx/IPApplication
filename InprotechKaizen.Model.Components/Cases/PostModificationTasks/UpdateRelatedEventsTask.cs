using System;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Cases.PostModificationTasks
{
    public class UpdateRelatedEventsTask : IPostCaseDetailModificationTask
    {
        readonly IChangeTracker _changeTracker;

        public UpdateRelatedEventsTask(IChangeTracker changeTracker)
        {
            _changeTracker = changeTracker;
        }

        public PostCaseDetailModificationTaskResult Run(
            Case @case,
            DataEntryTask dataEntryTask,
            AvailableEventToConsider[] eventsToConsider)
        {
            if(@case == null) throw new ArgumentNullException("case");
            if(dataEntryTask == null) throw new ArgumentNullException("dataEntryTask");
            if(eventsToConsider == null) throw new ArgumentNullException("eventsToConsider");

            var returnResult = new PostCaseDetailModificationTaskResult();

            foreach(var availableEvent in dataEntryTask.AvailableEvents)
            {
                if(availableEvent.AlsoUpdateEvent == null) continue;

                var eventToConsider = eventsToConsider.Single(me => me.EventId == availableEvent.Event.Id);
                var caseEvent = @case.CaseEvents.FirstOrDefault(
                                                                ce =>
                                                                ce.EventNo == eventToConsider.EventId &&
                                                                ce.Cycle == eventToConsider.Cycle);

                if(caseEvent == null) continue;

                var validAlsoUpdateEvent =
                    dataEntryTask.Criteria.ValidEvents.FirstOrDefault(
                                                                      ve =>
                                                                      ve.EventId == availableEvent.AlsoUpdateEvent.Id);

                var maxAllowedAlsoUpdateEventCycle = validAlsoUpdateEvent != null
                                                         ? validAlsoUpdateEvent.NumberOfCyclesAllowed.GetValueOrDefault(
                                                                                                                        1)
                                                         : availableEvent.AlsoUpdateEvent.NumberOfCyclesAllowed
                                                                         .GetValueOrDefault(1);

                var alsoUpdateEventCycleToUse = caseEvent.Cycle >= maxAllowedAlsoUpdateEventCycle
                                                    ? maxAllowedAlsoUpdateEventCycle
                                                    : caseEvent.Cycle;

                var alsoUpdateCaseEvent = @case.CaseEvents.FirstOrDefault(
                                                                          ce =>
                                                                          ce.EventNo ==
                                                                          availableEvent.AlsoUpdateEvent.Id &&
                                                                          ce.Cycle == alsoUpdateEventCycleToUse);

                if(alsoUpdateCaseEvent == null)
                {
                    alsoUpdateCaseEvent = new CaseEvent(
                        @case.Id,
                        availableEvent.AlsoUpdateEvent.Id,
                        alsoUpdateEventCycleToUse);
                    @case.CaseEvents.Add(alsoUpdateCaseEvent);
                }

                alsoUpdateCaseEvent.EventDate = caseEvent.EventDate;
                alsoUpdateCaseEvent.EventDueDate = caseEvent.EventDueDate;
                alsoUpdateCaseEvent.IsDateDueSaved = caseEvent.IsDateDueSaved;
                alsoUpdateCaseEvent.IsOccurredFlag = caseEvent.IsOccurredFlag;
                alsoUpdateCaseEvent.CreatedByCriteriaKey = caseEvent.CreatedByCriteriaKey;
                alsoUpdateCaseEvent.CreatedByActionKey = caseEvent.CreatedByActionKey;

                if(_changeTracker.HasChanged(alsoUpdateCaseEvent))
                    returnResult.PolicingRequests.Add(new PoliceCaseEvent(alsoUpdateCaseEvent, dataEntryTask));
            }

            return returnResult;
        }
    }
}