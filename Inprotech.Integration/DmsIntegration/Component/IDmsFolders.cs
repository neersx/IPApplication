using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Integration.DmsIntegration.Component.iManage;

namespace Inprotech.Integration.DmsIntegration.Component
{
    public interface IDmsFolders
    {
        Task<IEnumerable<DmsFolder>> FetchTopFolders(int id, IManageTestSettings testSettings = null);

        Task<IEnumerable<DmsFolder>> FetchSubFolders(string searchStringOrPath, FolderType folderType = FolderType.NotSet, bool fetchChild = false);
    }

    public interface ICaseDmsFolders : IDmsFolders { }

    public interface INameDmsFolders : IDmsFolders { }
}