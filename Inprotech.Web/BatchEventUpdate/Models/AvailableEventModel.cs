using System;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.BatchEventUpdate.Models
{
    public class AvailableEventModel
    {
        public AvailableEventModel(
            DataEntryTask dataEntryTask,
            AvailableEvent availableEvent,
            CaseEvent caseEvent,
            string eventDescription,
            bool isCyclic)
        {
            if(dataEntryTask == null) throw new ArgumentNullException("dataEntryTask");
            if(availableEvent == null) throw new ArgumentNullException("availableEvent");
            if(caseEvent == null) throw new ArgumentNullException("caseEvent");

            EventId = availableEvent.Event.Id;
            EventDescription = eventDescription;
            EventDateEntryAttribute = new EntryAttributeModel(availableEvent.EventAttribute);
            DueDateEntryAttribute = new EntryAttributeModel(availableEvent.DueAttribute);

            Cycle = caseEvent.Cycle;
            EventDate = caseEvent.EventDate;
            DueDate = caseEvent.EventDueDate;
            EventText = caseEvent.EffectiveEventText();
            if(caseEvent.IsOccurredFlag.HasValue)
                IsStopPolicing = caseEvent.IsOccurredFlag.GetValueOrDefault() == 1;

            IsCyclic = isCyclic;
        }

        public int EventId { get; set; }

        public string EventDescription { get; set; }

        public short Cycle { get; set; }

        public DateTime? EventDate { get; set; }

        public DateTime? DueDate { get; set; }

        public EntryAttributeModel EventDateEntryAttribute { get; set; }

        public EntryAttributeModel DueDateEntryAttribute { get; set; }

        public string EventText { get; set; }

        public bool IsCyclic { get; set; }

        public bool IsStopPolicing { get; set; }
    }
}