using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Web.BatchEventUpdate.Models;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.PostModificationTasks;

namespace Inprotech.Web.BatchEventUpdate.Miscellaneous
{
    public class AvailableEventModel
    {
        public AvailableEventModel()
        {
        }

        public AvailableEventModel(AvailableEvent availableEvent, CaseEvent caseEvent, string eventDescription)
        {
            if(availableEvent == null) throw new ArgumentNullException("availableEvent");
            if(caseEvent == null) throw new ArgumentNullException("caseEvent");

            EventDescription = eventDescription;
            EventId = availableEvent.Event.Id;
            Cycle = caseEvent.Cycle;

            EventDate = caseEvent.EventDate;
            DueDate = caseEvent.EventDueDate;
            if(caseEvent.IsOccurredFlag.HasValue)
            {
                IsStopPolicing = caseEvent.IsOccurredFlag.GetValueOrDefault() == 1;
            }
            EnteredDeadline = caseEvent.EnteredDeadline;
            PeriodTypeId = caseEvent.PeriodType;
            EventText = caseEvent.EventText ?? caseEvent.EventLongText;

            EventDateEntryAttribute = new EntryAttributeModel(availableEvent.EventAttribute);
            DueDateEntryAttribute = new EntryAttributeModel(availableEvent.DueAttribute);
            PeriodEntryAttribute = new EntryAttributeModel(availableEvent.PeriodAttribute);
            StopPolicingEntryAttribute = new EntryAttributeModel(availableEvent.PolicingAttribute);

            if(EventDateEntryAttribute.ShouldDefaultToSystemDate && !EventDate.HasValue)
            {
                EventDate = DateTime.Today;
            }

            if(DueDateEntryAttribute.ShouldDefaultToSystemDate && !DueDate.HasValue)
            {
                DueDate = DateTime.Today;
            }
        }

        public string EventText { get; set; }

        public string EventDescription { get; set; }

        public int EventId { get; set; }

        public short Cycle { get; set; }

        public DateTime? EventDate { get; set; }

        public DateTime? DueDate { get; set; }

        public EntryAttributeModel EventDateEntryAttribute { get; set; }

        public EntryAttributeModel DueDateEntryAttribute { get; set; }

        public EntryAttributeModel PeriodEntryAttribute { get; set; }

        public EntryAttributeModel StopPolicingEntryAttribute { get; set; }

        public bool? IsStopPolicing { get; set; }

        public int? EnteredDeadline { get; set; }

        public string PeriodTypeId { get; set; }
    }

    public static class AvailableEventModelEx
    {
        public static AvailableEventToConsider[] AsEventsToConsider(
            this IEnumerable<AvailableEventModel> availableEvents)
        {
            return availableEvents.Select(
                                          ae => new AvailableEventToConsider(ae.EventId, ae.Cycle)).ToArray();
        }

        public static bool HasChanged(this AvailableEventModel eventData, Case @case)
        {
            if(eventData == null) throw new ArgumentNullException("eventData");
            if(@case == null) throw new ArgumentNullException("case");

            var caseEvent =
                @case.CaseEvents.SingleOrDefault(ce => ce.EventNo == eventData.EventId && ce.Cycle == eventData.Cycle);
            if(caseEvent != null) return true;

            return !(eventData.EventDate == null &&
                     eventData.DueDate == null &&
                     string.IsNullOrWhiteSpace(eventData.EventText) &&
                     eventData.EnteredDeadline == null &&
                     string.IsNullOrEmpty(eventData.PeriodTypeId));
        }
    }
}