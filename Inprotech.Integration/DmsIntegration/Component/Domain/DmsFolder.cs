using System;
using System.Collections.Generic;
using Inprotech.Integration.DmsIntegration.Component.iManage;

namespace Inprotech.Integration.DmsIntegration.Component.Domain
{
    public class DmsFolder
    {
        public DmsFolder()
        {
            ChildFolders = new List<DmsFolder>();
            Documents = new List<DmsDocument>();
        }

        public string ContainerId { get; set; }

        public int Id { get; set; }

        public string Database { get; set; }

        public string Name { get; set; }

        public string Source { get; set; }

        public string SubClass { get; set; }

        public string ParentId { get; set; }

        public bool CanHaveRelatedDocuments { get; set; } = true;

        public FolderType FolderType { get; set; }

        public List<DmsFolder> ChildFolders { get; set; }

        public List<DmsDocument> Documents { get; set; }

        public bool HasChildFolders { get; set; }

        public bool HasDocuments { get; set; }
        public string SiteDbId { get; set; }
        public Uri Iwl { get; set; }

        public DmsFolder AddChildFolder(DmsFolder childFolder)
        {
            ChildFolders.Add(childFolder);
            HasChildFolders = true;
            return childFolder;
        }
    }
}