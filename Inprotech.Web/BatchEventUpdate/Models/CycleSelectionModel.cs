using System;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Extensions;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.BatchEventUpdate.Models
{
    public class CycleSelectionModel
    {
        public CycleSelectionModel(Case @case, DataEntryTask dataEntryTask)
        {
            if(@case == null) throw new ArgumentNullException("case");
            if(dataEntryTask == null) throw new ArgumentNullException("dataEntryTask");

            Id = @case.Id;
            CaseReference = @case.Irn;
            CurrentOfficialNumber = @case.CurrentOfficialNumber;

            var firstEvent = dataEntryTask.EventForCycleConsideration();
            var validEvent = dataEntryTask.Criteria.ValidEvents.FirstOrDefault(ve => ve.EventId == firstEvent.Event.Id);
            EventDescription = validEvent == null ? firstEvent.Event.Description : validEvent.Description;

            Events = @case
                .CaseEvents
                .Where(ce => ce.EventNo == firstEvent.Event.Id)
                .OrderBy(ce => ce.Cycle)
                .Select(ce => new CyclicEventDetailModel(ce)).ToArray();
        }

        public int Id { get; set; }
        public string CaseReference { get; set; }
        public string CurrentOfficialNumber { get; set; }
        public string EventDescription { get; set; }
        public CyclicEventDetailModel[] Events { get; set; }
    }
}