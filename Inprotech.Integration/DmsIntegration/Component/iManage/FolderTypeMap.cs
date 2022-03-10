using System;
using System.Collections.Generic;

namespace Inprotech.Integration.DmsIntegration.Component.iManage
{
    public static class FolderTypeMap
    {
        static readonly Dictionary<string, FolderType> MapDict =
            new Dictionary<string, FolderType>
            {
                {"tab", FolderType.Tab},
                {"search", FolderType.SearchFolder},
                {"regular", FolderType.Folder},
                {"workspace",FolderType.Workspace},
                {"searchFolder",FolderType.SearchFolder},
                {"folder",FolderType.Folder}
            };

        public static FolderType Map(string input, string email)
        {
            if (!string.IsNullOrEmpty(email)) return FolderType.EmailFolder;
            return MapDict.TryGetValue(input ?? string.Empty, out FolderType folderType)
                ? folderType
                : FolderType.NotSet;
        }
    }
}