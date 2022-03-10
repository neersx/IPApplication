using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts.Messages.PtoAccess.DmsIntegration;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Persistence;

#pragma warning disable CS1998 // Async methods lacks 'await' operators and will run synchronously

namespace Inprotech.IntegrationServer.PtoAccess.DmsIntegration
{
    public interface IUpdateDocumentStatus
    {
        Task<bool> UpdateTo(int documentId, DocumentDownloadStatus status);

        Task UpdateAllTo(IEnumerable<int> documentIds, DocumentDownloadStatus status);
    }

    public class DocumentStatusUpdater : IUpdateDocumentStatus
    {
        readonly IRepository _repository;
        readonly ICalculateDownloadStatus _downloadStatusCalculator;
        readonly IDmsIntegrationPublisher _dmsIntegrationPublisher;

        public DocumentStatusUpdater(IRepository repository, ICalculateDownloadStatus downloadStatusCalculator,
            IDmsIntegrationPublisher dmsIntegrationPublisher)
        {
            _repository = repository;
            _downloadStatusCalculator = downloadStatusCalculator;
            _dmsIntegrationPublisher = dmsIntegrationPublisher;
        }

        public async Task<bool> UpdateTo(int documentId, DocumentDownloadStatus status)
        {
            try
            {
                using (var t = _repository.BeginTransaction())
                {
                    var document = _repository
                        .Set<Document>()
                        .SingleOrDefault(d => d.Id == documentId && d.Status != status);

                    if (document != null &&
                        _downloadStatusCalculator.CanChangeDmsStatus(document.Status, status))
                    {
                        document.Status = status;
                        _repository.SaveChanges();

                        t.Complete();
                        return true;
                    }

                    return false;
                }
            }
            catch (DBConcurrencyException exception)
            {
                _dmsIntegrationPublisher.Publish(
                    new DmsIntegrationFailedMessage(exception,
                        string.Format(DmsIntegrationMessages.Warning.UpdateConcurrencyViolationDetected, status),
                        documentId));

                return false;
            }
        }

        public async Task UpdateAllTo(IEnumerable<int> documentsIds, DocumentDownloadStatus status)
        {
            documentsIds.ToList()
                .ForEach(
                    async x =>
                        await UpdateTo(x, status)
                );
        }
    }
}