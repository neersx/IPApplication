using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Inprotech.Integration.Documents;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Persistence;
using Models = InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace Inprotech.Integration.AutomaticDocketing
{
    public interface IRelevantEvents
    {
        IEnumerable<Event> Resolve(string sourceSystem, int correlationId, Document[] docs);
    }

    public class RelevantEvents : IRelevantEvents
    {
        readonly IDbContext _dbContext;
        readonly IDocumentMappings _documentMappings;
        readonly IEventsComparer _eventsComparer;

        public RelevantEvents(IDbContext dbContext, IDocumentMappings documentMappings, IEventsComparer eventsComparer)
        {
            _dbContext = dbContext;
            _documentMappings = documentMappings;
            _eventsComparer = eventsComparer;
        }

        public IEnumerable<Event> Resolve(string sourceSystem, int correlationId, Document[] docs)
        {
            if (docs == null) throw new ArgumentNullException(nameof(docs));
            if (string.IsNullOrWhiteSpace(sourceSystem)) throw new ArgumentNullException(nameof(sourceSystem));

            var comparisonScenarios = docs
                .Select(_ => new ComparisonScenario<Models.Event>(
                                                                  new Models.Event
                                                                  {
                                                                      CorrelationRef = _.CorrelationRef(),
                                                                      EventDescription = _.DocumentDescription,
                                                                      EventCode = _.FileWrapperDocumentCode,
                                                                      EventDate = _.MailRoomDate
                                                                  }, ComparisonType.Documents));

            var mappedScenarios = _documentMappings.Resolve(comparisonScenarios, sourceSystem).ToArray();
            if (!mappedScenarios.Any(_ => _.Mapped.Id.HasValue))
                return Enumerable.Empty<Event>();

            var cr = new ComparisonResult(sourceSystem);

            var inprotechCase = _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                .Include(c => c.CaseEvents)
                .Include(c => c.OfficialNumbers)
                .Include(c => c.OfficialNumbers.Select(_ => _.NumberType))
                .Include(c => c.OfficialNumbers.Select(_ => _.NumberType.RelatedEvent))
                .Include(c => c.OpenActions)
                .Include(c => c.OpenActions.Select(_ => _.Criteria))
                .Single(c => c.Id == correlationId);

            _eventsComparer.Compare(inprotechCase, mappedScenarios, cr);

            return cr.Events;
        }
    }
}