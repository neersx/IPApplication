using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.AutomaticDocketing;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Persistence;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;

namespace Inprotech.IntegrationServer.PtoAccess.WorkflowIntegration
{
    public class DocumentEvents
    {
        readonly IRepository _repository;
        readonly IDocumentLoader _documentLoader;
        readonly IDocumentEvents _documentEvents;
        readonly ICorrelationIdUpdator _correlationIdUpdator;
        readonly IComparisonDocumentsProvider _comparisonDocumentsProvider;

        public DocumentEvents(IRepository repository,
            IDocumentLoader documentLoader,
            IDocumentEvents documentEvents,
            ICorrelationIdUpdator correlationIdUpdator,
            IComparisonDocumentsProvider comparisonDocumentsProvider)
        {
            _repository = repository;
            _documentLoader = documentLoader;
            _documentEvents = documentEvents;
            _correlationIdUpdator = correlationIdUpdator;
            _comparisonDocumentsProvider = comparisonDocumentsProvider;
        }

        public Task UpdateFromPto(DataDownload dataDownload)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            var documents = _documentLoader
                .GetDocumentsFrom(dataDownload.DataSourceType, dataDownload.Case.CaseKey)
                .OrderByDescending(_ => _.MailRoomDate)
                .ToArray();

            if (documents.HasPendingEventToProcess())
            {
                _documentEvents.UpdateAutomatically(
                    ExternalSystems.SystemCode(dataDownload.DataSourceType),
                    dataDownload.Case.CaseKey, documents);
            }

            return Task.FromResult<object>(null);
        }

        public async Task UpdateFromPrivatePair(ApplicationDownload applicationDownload)
        {
            if (applicationDownload == null) throw new ArgumentNullException(nameof(applicationDownload));

            var correlationId = GetPrivatePairCorrelationId(applicationDownload.Number);
            if (correlationId == null)
                return;

            var persisted = _documentLoader
                .GetDocumentsFrom(DataSourceType.UsptoPrivatePair, correlationId.Value)
                .OrderByDescending(_ => _.MailRoomDate)
                .ToArray();

            var docsForComparison = (await _comparisonDocumentsProvider.For(applicationDownload, persisted)).ToArray();

            if (!docsForComparison.HasPendingEventToProcess())
                return;

            _documentEvents.UpdateAutomatically(
                ExternalSystems.SystemCode(DataSourceType.UsptoPrivatePair),
                correlationId.Value, docsForComparison);
        }

        int? GetPrivatePairCorrelationId(string number)
        {
            var @case = _repository.Set<Case>()
                .FirstOrDefault(_ => _.Source == DataSourceType.UsptoPrivatePair && number == _.ApplicationNumber);

            if (@case == null)
                return null;

            _correlationIdUpdator.UpdateIfRequired(@case);

            return @case.CorrelationId;
        }
    }
}