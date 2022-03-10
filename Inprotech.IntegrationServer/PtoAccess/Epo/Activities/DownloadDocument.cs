using System;
using System.Threading.Tasks;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Documents;
using Inprotech.IntegrationServer.PtoAccess.Activities;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.Activities
{
    public class DownloadDocument
    {
        readonly IPtoDocument _ptoDocument;
        readonly IEpRegisterClient _epRegisterClient;

        public DownloadDocument(IPtoDocument ptoDocument,
            IEpRegisterClient epRegisterClient)
        {
            _ptoDocument = ptoDocument;
            _epRegisterClient = epRegisterClient;
        }

        public async Task Download(DataDownload dataDownload, Document document)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));
            if (document == null) throw new ArgumentNullException(nameof(document));
            
            await _ptoDocument.Download(dataDownload, document, _epRegisterClient.DownloadDocument);
        }
    }
}
