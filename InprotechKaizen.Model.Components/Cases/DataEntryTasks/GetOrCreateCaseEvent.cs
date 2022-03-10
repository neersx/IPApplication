using System;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks
{
    public interface IGetOrCreateCaseEvent
    {
        CaseEvent For(Case @case, DataEntryTask dataEntryTask, AvailableEvent availableEvent, short controllingCycle);
    }

    public class GetOrCreateCaseEvent : IGetOrCreateCaseEvent
    {
        readonly ICycleSelection _cycleSelection;

        public GetOrCreateCaseEvent(ICycleSelection cycleSelection)
        {
            if(cycleSelection == null) throw new ArgumentNullException("cycleSelection");
            _cycleSelection = cycleSelection;
        }

        public CaseEvent For(
            Case @case,
            DataEntryTask dataEntryTask,
            AvailableEvent availableEvent,
            short requestedCycle)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));
            if (dataEntryTask == null) throw new ArgumentNullException(nameof(dataEntryTask));

            if(requestedCycle < 0) throw new InvalidOperationException("requestedCycle should start from cycle 1");

            var maxAllowableCycle = _cycleSelection.GetMaxCycle(availableEvent, dataEntryTask);

            if(requestedCycle > maxAllowableCycle)
                requestedCycle = maxAllowableCycle;

            return
                @case.CaseEvents.SingleOrDefault(
                                                 ce =>
                                                 ce.EventNo == availableEvent.Event.Id && ce.Cycle == requestedCycle) ??
                new CaseEvent(@case.Id, availableEvent.Event.Id, requestedCycle)
                {
                    CreatedByCriteriaKey = dataEntryTask.CriteriaId,
                    CreatedByActionKey = dataEntryTask.Criteria.Action.Code
                };
        }
    }
}