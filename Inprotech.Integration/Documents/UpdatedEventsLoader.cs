using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration.AutomaticDocketing;
using InprotechKaizen.Model.Components.Cases.Events;

namespace Inprotech.Integration.Documents
{
    public interface IUpdatedEventsLoader
    {
        Dictionary<Document, UpdatedEvent> Load(int? caseId, IEnumerable<Document> documents);
    }

    public class UpdatedEventsLoader : IUpdatedEventsLoader
    {
        readonly IValidEventsResolver _validEventsResolver;

        public UpdatedEventsLoader(IValidEventsResolver validEventsResolver)
        {
            if (validEventsResolver == null) throw new ArgumentNullException("validEventsResolver");
            _validEventsResolver = validEventsResolver;
        }

        public Dictionary<Document, UpdatedEvent> Load(int? caseId, IEnumerable<Document> documents)
        {
            if (documents == null) throw new ArgumentNullException("documents");

            var docs = documents.ToArray();
            var result = docs.ToDictionary(k => k, v => new UpdatedEvent());

            if (!caseId.HasValue ||
                !docs.WithDocumentEvents().Any(_ => _.DocumentEvent.CorrelationEventId.HasValue))
                return result;

            var eventIds = docs
                .WithDocumentEvents()
                .Where(_ => _.DocumentEvent.CorrelationId == caseId)
                .Where(_ => _.DocumentEvent.CorrelationEventId.HasValue)
                .Select(_ => _.DocumentEvent.CorrelationEventId)
                .Distinct()
                .ToArray();

            var extended = _validEventsResolver.Resolve(caseId.Value, eventIds.Cast<int>())
                .ToDictionary(k => k.EventId, v => v);

            foreach (var r in result)
            {
                if (r.Key.DocumentEvent == null ||
                    !r.Key.DocumentEvent.CorrelationEventId.HasValue ||
                    r.Key.DocumentEvent.CorrelationId != caseId)
                    continue;

                var de = r.Key.DocumentEvent;

                var e = extended[de.CorrelationEventId.GetValueOrDefault()];

                r.Value.Description = e.Description;
                r.Value.IsCyclic = e.IsCyclic;
                r.Value.Cycle = de.CorrelationCycle.GetValueOrDefault();
            }

            return result;
        }
    }

    public class UpdatedEvent
    {
        public string Description { get; set; }

        public bool IsCyclic { get; set; }

        public int Cycle { get; set; }
    }
}