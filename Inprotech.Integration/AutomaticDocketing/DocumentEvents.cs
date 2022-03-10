using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Persistence;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;

namespace Inprotech.Integration.AutomaticDocketing
{
    public interface IDocumentEvents
    {
        void UpdateAutomatically(string sourceSystem, int correlationId, IEnumerable<Document> documents);
    }

    public class DocumentEvents : IDocumentEvents
    {
        readonly IRepository _repository;
        readonly IRelevantEvents _relevantEvents;
        readonly Func<DateTime> _now;
        readonly IApplyUpdates _applyUpdates;

        public DocumentEvents(IRepository repository, IRelevantEvents relevantEvents, IApplyUpdates applyUpdates, Func<DateTime> now)
        {
            if (repository == null) throw new ArgumentNullException("repository");
            if (relevantEvents == null) throw new ArgumentNullException("relevantEvents");
            if (applyUpdates == null) throw new ArgumentNullException("applyUpdates");
            if (now == null) throw new ArgumentNullException("now");

            _repository = repository;
            _relevantEvents = relevantEvents;
            _applyUpdates = applyUpdates;
            _now = now;
        }

        public void UpdateAutomatically(string sourceSystem, int correlationId, IEnumerable<Document> documents)
        {
            if (string.IsNullOrWhiteSpace(sourceSystem)) throw new ArgumentNullException("sourceSystem");
            if (documents == null) throw new ArgumentNullException("documents");

            var docs = documents.ToArray();

            var now = _now();

            var relevantEvents = _relevantEvents.Resolve(sourceSystem, correlationId, docs).ToArray();

            foreach (var re in relevantEvents)
            {
                if (!re.EventNo.HasValue) continue;

                if (re.EventDate == null || !re.EventDate.Updateable.GetValueOrDefault()) continue;
                
                /* comparison documents are documents not downloaded but used for comparison only */
                if (re.IsBasedOnComparisonDocument()) continue;

                int correlatedId;
                if (!int.TryParse(re.CorrelationRef, out correlatedId)) continue;

                var doc = docs.Single(_ => _.Id == correlatedId);

                if (!doc.HasPendingEventToProcess()) continue;

                doc.DocumentEvent.Status = DocumentEventStatus.Processing;
                doc.DocumentEvent.CorrelationId = correlationId;
                doc.DocumentEvent.CorrelationEventId = re.EventNo;
                doc.DocumentEvent.UpdatedOn = now;
                re.EventDate.Updated = true;
            }

            var updatableEvents = relevantEvents.Where(_ => _.EventDate != null && _.EventDate.Updated).ToArray();

            var updatedEvents = _applyUpdates.From(updatableEvents, correlationId).ToArray();

            now = _now();

            foreach (var doc in docs.WithStatus(DocumentEventStatus.Pending, DocumentEventStatus.Processing))
            {
                if (doc.DocumentEvent.Status == DocumentEventStatus.Processing)
                {
                    var ue = updatedEvents.Single(_ => int.Parse(_.CorrelationRef) == doc.Id);
                    doc.DocumentEvent.CorrelationEventId = ue.EventNo;
                    doc.DocumentEvent.CorrelationCycle = ue.Cycle;
                }

                doc.DocumentEvent.CorrelationId = correlationId;
                doc.DocumentEvent.Status = DocumentEventStatus.Processed;
                doc.DocumentEvent.UpdatedOn = now;
            }

            _repository.SaveChanges();
        }
    }
}
 