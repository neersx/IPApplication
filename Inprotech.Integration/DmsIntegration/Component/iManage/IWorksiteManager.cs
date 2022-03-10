using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.DmsIntegration.Component.Domain;

namespace Inprotech.Integration.DmsIntegration.Component.iManage
{
    public interface IWorkSiteManager : IDisposable
    {
        void SetSettings(IManageSettings settings);
        Task<bool> Connect(IManageSettings.SiteDatabaseSettings settings, string username, string password, bool force = false);
        Task Disconnect();
        Task<IEnumerable<DmsFolder>> GetTopFolders(SearchType searchType, string searchString, string nameType);
        Task<IEnumerable<DmsFolder>> GetSubFolders(string containerId, FolderType folderType, bool fetchChild);
        Task<DmsDocumentCollection> GetDocuments(string containerId, FolderType folderType, CommonQueryParameters qp = null);
        Task<IEnumerable<DmsDocument>> GetRelatedDocuments(string containerId);
        Task<DownloadDocumentResponse> DownloadDocument(string containerId);
        Task<DmsDocument> GetDocumentById(string containerId);

    }
}
