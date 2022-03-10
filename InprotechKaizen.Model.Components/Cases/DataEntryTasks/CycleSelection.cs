using System;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Extensions;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks
{
    public interface ICycleSelection
    {
        bool IsRequired(DataEntryTask @for, Case @in);
        bool IsCyclicalFor(AvailableEvent availableEvent, DataEntryTask dataEntryTask);

        short DeriveControllingCycle(
            Case @case,
            DataEntryTask dataEntryTask,
            AvailableEvent availableEvent,
            bool useNextCycle);

        short GetMaxCycle(AvailableEvent availableEvent, DataEntryTask dataEntryTask);
    }

    public class CycleSelection : ICycleSelection
    {
        public bool IsRequired(DataEntryTask @for, Case @in)
        {
            if(@for == null) throw new ArgumentNullException("for");
            if(@in == null) throw new ArgumentNullException("in");

            if(@for.Criteria.Action.IsCyclic)
                return false;

            var firstEvent = @for.EventForCycleConsideration();
            return IsCyclicalFor(firstEvent, @for) && @in.CaseEvents.Any(ce => ce.EventNo == firstEvent.Event.Id);
        }

        public short DeriveControllingCycle(
            Case @case,
            DataEntryTask dataEntryTask,
            AvailableEvent availableEvent,
            bool useNextCycle)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));

            var caseEvents = @case.CaseEvents.Where(ce => ce.EventNo == availableEvent.Event.Id).OrderBy(ce => ce.Cycle).ToList();

            if (!useNextCycle)
            {
                var ceWithNoEventDate = caseEvents.FirstOrDefault(ce => ce.EventDate == null);
                if (ceWithNoEventDate != null)
                {
                    return ceWithNoEventDate.Cycle;
                }
            }

            var caseEvent = caseEvents.LastOrDefault();
            if(caseEvent == null) return 1;

            var currentCaseEventCycle = caseEvent.Cycle;
            var maxAllowed = GetMaxCycle(availableEvent, dataEntryTask);

            if(useNextCycle && currentCaseEventCycle < maxAllowed)
                return (short)(currentCaseEventCycle + 1);

            return maxAllowed > currentCaseEventCycle ? currentCaseEventCycle : maxAllowed;
        }

        public bool IsCyclicalFor(AvailableEvent availableEvent, DataEntryTask dataEntryTask)
        {
            return EffectiveAllowableCycles(availableEvent, dataEntryTask) > 1;
        }

        public short GetMaxCycle(AvailableEvent availableEvent, DataEntryTask dataEntryTask)
        {
            return EffectiveAllowableCycles(availableEvent, dataEntryTask);
        }

        static short EffectiveAllowableCycles(AvailableEvent availableEvent, DataEntryTask dataEntryTask)
        {
            if(dataEntryTask == null) throw new ArgumentNullException("dataEntryTask");

            if(!dataEntryTask.AvailableEvents.Contains(availableEvent))
                throw new InvalidOperationException("Specified availableEvent does not exist in dataEntryTask.");

            var validEvent =
                dataEntryTask.Criteria.ValidEvents.FirstOrDefault(ve => ve.EventId == availableEvent.Event.Id);
            var effectiveNumberOfCyclesAllowed = validEvent?.NumberOfCyclesAllowed ??
                                                 availableEvent.Event.NumberOfCyclesAllowed;

            return effectiveNumberOfCyclesAllowed.GetValueOrDefault(1);
        }
    }
}