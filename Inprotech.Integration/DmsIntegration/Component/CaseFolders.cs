using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Integration.DmsIntegration.Component.iManage;

namespace Inprotech.Integration.DmsIntegration.Component
{
    public class CaseFolders : ICaseDmsFolders
    {
        readonly IConfiguredDms _configuredDms;
        readonly ICaseFolderCriteriaResolver _caseFolderCriteriaResolver;

        public CaseFolders(IConfiguredDms configuredDms, ICaseFolderCriteriaResolver caseFolderCriteriaResolver)
        {
            _configuredDms = configuredDms;
            _caseFolderCriteriaResolver = caseFolderCriteriaResolver;
        }

        public async Task<IEnumerable<DmsFolder>> FetchTopFolders(int caseKey, IManageTestSettings testSettings = null)
        {
            var dms = _configuredDms.GetService();

            var searchCriteria = await _caseFolderCriteriaResolver.Resolve(caseKey, testSettings?.Settings);

            if (string.IsNullOrWhiteSpace(searchCriteria.CaseReference))
                return Enumerable.Empty<DmsFolder>();

            var folders = new List<DmsFolder>();

            foreach (var folder in await dms.GetCaseFolders(searchCriteria.CaseReference, testSettings))
                folders.Add(folder);

            foreach (var nameEntity in searchCriteria.CaseNameEntities)
            {
                foreach (var folder in await dms.GetNameFolders(nameEntity.NameCode, nameEntity.NameType, testSettings))
                    folders.Add(folder);
            }

            return folders.DistinctBy(folder => folder.ContainerId);
        }

        public async Task<IEnumerable<DmsFolder>> FetchSubFolders(string searchStringOrPath, FolderType folderType, bool fetchChild)
        {
            if (searchStringOrPath == null) throw new ArgumentNullException(nameof(searchStringOrPath));

            var dms = _configuredDms.GetService();

            return await dms.GetSubFolders(searchStringOrPath, folderType, fetchChild);
        }
    }
}