using System;
using System.Threading.Tasks;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Documents;
using Inprotech.IntegrationServer.PtoAccess.Activities;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities
{
    public class DownloadDocument
    {
        readonly IPtoDocument _ptoDocument;
        readonly ITsdrDocumentClient _tsdrDocumentClient;

        public DownloadDocument(IPtoDocument ptoDocument,
            ITsdrDocumentClient tsdrDocumentClient)
        {
            _ptoDocument = ptoDocument;
            _tsdrDocumentClient = tsdrDocumentClient;
        }

        public async Task Download(DataDownload dataDownload, Document document)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));
            if (document == null) throw new ArgumentNullException(nameof(document));

            await _ptoDocument.Download(dataDownload, document, _tsdrDocumentClient.Download);
        }
    }
}