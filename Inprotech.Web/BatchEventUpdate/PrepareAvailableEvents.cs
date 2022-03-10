using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Web.BatchEventUpdate.Models;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.BatchEventUpdate
{
    public interface IPrepareAvailableEvents
    {
        IEnumerable<AvailableEventModel> For(Case @case, DataEntryTask dataEntryTask, short controllingCycle);
    }

    public class PrepareAvailableEvents : IPrepareAvailableEvents
    {
        readonly ICycleSelection _cycleSelection;
        readonly IGetOrCreateCaseEvent _getOrCreateCaseEvent;

        public PrepareAvailableEvents(IGetOrCreateCaseEvent getOrCreateCaseEvent, ICycleSelection cycleSelection)
        {
            if(getOrCreateCaseEvent == null) throw new ArgumentNullException("getOrCreateCaseEvent");
            if(cycleSelection == null) throw new ArgumentNullException("cycleSelection");

            _getOrCreateCaseEvent = getOrCreateCaseEvent;
            _cycleSelection = cycleSelection;
        }

        public IEnumerable<AvailableEventModel> For(Case @case, DataEntryTask dataEntryTask, short controllingCycle)
        {
            var validEventsMap = dataEntryTask.Criteria.ValidEvents.ToDictionary(ec => ec.EventId, ec => ec);

            var orderedAvailableEvents = dataEntryTask.AvailableEvents.OrderBy(ae => ae.DisplaySequence);

            return orderedAvailableEvents.Select(
                                                 ae =>
                                                 new AvailableEventModel(
                                                     dataEntryTask,
                                                     ae,
                                                     _getOrCreateCaseEvent.For(
                                                                               @case,
                                                                               dataEntryTask,
                                                                               ae,
                                                                               controllingCycle),
                                                     validEventsMap.ContainsKey(ae.Event.Id)
                                                         ? validEventsMap[ae.Event.Id].Description
                                                         : ae.Event.Description,
                                                     _cycleSelection.IsCyclicalFor(ae, dataEntryTask))
                );
        }
    }
}