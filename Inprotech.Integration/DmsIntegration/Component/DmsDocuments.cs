using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Integration.DmsIntegration.Component.iManage;

namespace Inprotech.Integration.DmsIntegration.Component
{
    public class DmsDocuments : IDmsDocuments
    {
        readonly IConfiguredDms _configuredDms;

        public DmsDocuments(IConfiguredDms configuredDms)
        {
            _configuredDms = configuredDms;
        }

        public async Task<DmsDocumentCollection> Fetch(string searchStringOrPath, FolderType folderType, CommonQueryParameters qp)
        {
            if (string.IsNullOrWhiteSpace(searchStringOrPath)) throw new ArgumentNullException(nameof(searchStringOrPath));

            var dms = _configuredDms.GetService();

            return await dms.GetDocuments(searchStringOrPath, folderType, qp);
        }

        public async Task<DmsDocument> FetchDocumentDetails(string searchStringOrPath)
        {
            if (string.IsNullOrWhiteSpace(searchStringOrPath)) throw new ArgumentNullException(nameof(searchStringOrPath));

            var dms = _configuredDms.GetService();

            return await dms.GetDocumentDetails(searchStringOrPath);
        }

        public async Task<DownloadDocumentResponse> Download(string searchStringOrPath)
        {
            if (searchStringOrPath == null) throw new ArgumentNullException(nameof(searchStringOrPath));

            var dms = _configuredDms.GetService();

            return await dms.Download(searchStringOrPath);
        }
    }
}