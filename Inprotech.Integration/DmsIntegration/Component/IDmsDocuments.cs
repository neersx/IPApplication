using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Integration.DmsIntegration.Component.iManage;

namespace Inprotech.Integration.DmsIntegration.Component
{
    public interface IDmsDocuments
    {
        Task<DmsDocumentCollection> Fetch(string searchStringOrPath, FolderType folderType, CommonQueryParameters qp);
        Task<DmsDocument> FetchDocumentDetails(string searchStringOrPath);
        Task<DownloadDocumentResponse> Download(string searchStringOrPath);
    }
}