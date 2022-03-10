using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Documents;

namespace Inprotech.IntegrationServer.PtoAccess.DmsIntegration
{

    public interface ILoadCaseAndSendDocumentToDms
    {
        Task SendToDms(int documentId);
    }

    public class CaseLoaderAndDocumentSender : ILoadCaseAndSendDocumentToDms
    {
        readonly IMoveDocumentToDmsFolder _sender;
        readonly ILoadCaseAndDocuments _loader;
        readonly IUpdateDocumentStatus _updateDocumentStatus;
        
        public CaseLoaderAndDocumentSender(
            IMoveDocumentToDmsFolder sender, 
            ILoadCaseAndDocuments loader, 
            IUpdateDocumentStatus updateDocumentStatus)
        {
            _sender = sender;
            _loader = loader;
            _updateDocumentStatus = updateDocumentStatus;
        }

        public Task SendToDms(int documentId)
        {
            _updateDocumentStatus.UpdateTo(documentId, DocumentDownloadStatus.ScheduledForSendingToDms);

            var caseAndDocuments = _loader.GetCaseAndDocumentsFor(documentId);

            return _sender.MoveToDms(caseAndDocuments.Case.Id, caseAndDocuments.Documents.Single().Id);
        }
    }
}