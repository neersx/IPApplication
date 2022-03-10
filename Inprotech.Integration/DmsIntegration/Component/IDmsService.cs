using System.Collections.Generic;
using System.Drawing;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Integration.DmsIntegration.Component.iManage;

namespace Inprotech.Integration.DmsIntegration.Component
{
    public interface IDmsService
    {
        Task<IEnumerable<DmsFolder>> GetCaseFolders(string searchString, IManageTestSettings testSettings = null);
        Task<IEnumerable<DmsFolder>> GetNameFolders(string searchString, string nameType, IManageTestSettings testSettings = null);
        Task<IEnumerable<DmsFolder>> GetSubFolders(string searchStringOrPath, FolderType folderType, bool fetchChild);
        Task<DmsDocumentCollection> GetDocuments(string searchStringOrPath, FolderType folderType, CommonQueryParameters qp = null);
        Task<DmsDocument> GetDocumentDetails(string searchStringOrPath);
        Task<DownloadDocumentResponse> Download(string searchStringOrPath);
    }
}