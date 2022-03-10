using System;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public class ResolvedEvent
    {
        public ResolvedEvent(ValidEvent validEvent, Event @event)
        {
            if (@event == null) throw new ArgumentNullException(nameof(@event));

            Id = @event.Id;
            IsCyclic = validEvent?.IsCyclic ?? @event.IsCyclic;
            EventControlId = validEvent?.CriteriaId;
            EventDescription = validEvent != null ? validEvent.Description : @event.Description;
        }

        public bool IsCyclic { get; }

        public int Id { get; set; }

        public int? EventControlId { get; set; }

        public string EventDescription { get; set; }
    }
}