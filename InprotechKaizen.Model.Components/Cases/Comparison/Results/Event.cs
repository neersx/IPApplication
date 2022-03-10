using System;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Components.Cases.Comparison.Translations;
using Newtonsoft.Json;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Results
{
    [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Event")]
    public class Event : IEventDescriptionTranslatable
    {
        public int? Sequence { get; set; }

        public bool IsCyclic { get; set; }

        public int? EventNo { get; set; }

        public short? Cycle { get; set; }

        public string EventType { get; set; }

        [SuppressMessage("Microsoft.Design", "CA1006:DoNotNestGenericTypesInMemberSignatures")]
        public Value<DateTime?> EventDate { get; set; }

        public string CorrelationRef { get; set; }

        [JsonIgnore]
        public int? CriteriaId { get; set; }

        public void SetTranslatedDescription(string translated)
        {
            EventType = translated;
        }
    }

    public static class EventExt
    {
        public static bool IsBasedOnComparisonDocument(this Event @event)
        {
            if (@event == null) throw new ArgumentNullException(nameof(@event));

            Guid guid;
            return Guid.TryParse(@event.CorrelationRef, out guid);
        }
    }
}