using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Integration.DmsIntegration.Component.iManage;

namespace Inprotech.Integration.DmsIntegration.Component
{
    public class NameFolders : INameDmsFolders
    {
        readonly IConfiguredDms _configuredDms;
        readonly IDmsSettingsProvider _settingsProvider;
        readonly INameFolderCriteriaResolver _nameFolderCriteriaResolver;

        public NameFolders(IConfiguredDms configuredDms, IDmsSettingsProvider settingsProvider, INameFolderCriteriaResolver nameFolderCriteriaResolver)
        {
            _configuredDms = configuredDms;
            _settingsProvider = settingsProvider;
            _nameFolderCriteriaResolver = nameFolderCriteriaResolver;
        }

        public async Task<IEnumerable<DmsFolder>> FetchTopFolders(int nameKey, IManageTestSettings testSettings = null)
        {
            var searchCriteria = await _nameFolderCriteriaResolver.Resolve(nameKey, testSettings?.Settings);

            var settings = testSettings != null ? testSettings.Settings : await _settingsProvider.Provide();

            var dms = _configuredDms.GetService();

            var folders = new List<DmsFolder>();

            foreach (var nameType in settings.NameTypesRequired)
            {
                foreach (var folder in await dms.GetNameFolders(searchCriteria.NameEntity.NameCode, nameType, testSettings))
                    folders.Add(folder);
            }

            return folders;
        }

        public async Task<IEnumerable<DmsFolder>> FetchSubFolders(string searchStringOrPath, FolderType folderType = FolderType.NotSet, bool fetchChild = false)
        {
            if (searchStringOrPath == null) throw new ArgumentNullException(nameof(searchStringOrPath));

            var dms = _configuredDms.GetService();

            return await dms.GetSubFolders(searchStringOrPath, folderType, fetchChild);
        }
    }
}
