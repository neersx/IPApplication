using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts.Messages.PtoAccess.DmsIntegration;
using Inprotech.Integration.Documents;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;

namespace Inprotech.IntegrationServer.PtoAccess.DmsIntegration
{
    public interface IMoveDocumentToDmsFolder
    {
        Task MoveToDms(int caseId, int docId);
    }

    public class MoveDocumentToDmsFolder : IMoveDocumentToDmsFolder
    {
        readonly ILoadCaseAndDocuments _loader;
        readonly IUpdateDocumentStatus _updateDocumentStatus;
        readonly IDocumentForDms _documentForDms;
        readonly IDmsIntegrationPublisher _publisher;
        readonly ICorrelationIdUpdator _correlationIdUpdator;

        public MoveDocumentToDmsFolder(
            ILoadCaseAndDocuments loader,
            IUpdateDocumentStatus updateDocumentStatus,
            IDocumentForDms documentForDms,
            IDmsIntegrationPublisher publisher,
            ICorrelationIdUpdator correlationIdUpdator)
        {
            _loader = loader;
            _updateDocumentStatus = updateDocumentStatus;
            _documentForDms = documentForDms;
            _publisher = publisher;
            _correlationIdUpdator = correlationIdUpdator;
        }

        public async Task MoveToDms(int caseId, int docId)
        {
            var group = Guid.NewGuid();
            var caseAndDoc = _loader.GetCaseAndDocumentsFor(caseId, docId);
            var @case = caseAndDoc.Case;
            var document = caseAndDoc.Documents.Single();

            _publisher.Publish(new DmsIntegrationMessage(group, DmsIntegrationMessages.PrepareToSendToDms, caseId, docId));

            _correlationIdUpdator.CheckIfValid(@case);

            if (!@case.CorrelationId.HasValue)
            {
                _publisher.Publish(new DmsIntegrationMessage(group,
                    DmsIntegrationMessages.Warning.CaseHasNoCorrelationId, caseId, docId));
                return;
            }

            var canSendToDms = await _updateDocumentStatus.UpdateTo(document.Id, DocumentDownloadStatus.SendingToDms);
            if (!canSendToDms)
            {
                _publisher.Publish(new DmsIntegrationMessage(group,
                    string.Format(DmsIntegrationMessages.SendingToDms, document.Status), caseId, docId));
                return;
            }

            await _documentForDms.MoveDocumentWithItsMetadata(document, @case.CorrelationId.Value);

            await _updateDocumentStatus.UpdateTo(document.Id, DocumentDownloadStatus.SentToDms);

            _publisher.Publish(new DmsIntegrationMessage(group, DmsIntegrationMessages.ItemSentToDms, caseId, docId));
        }
    }
}