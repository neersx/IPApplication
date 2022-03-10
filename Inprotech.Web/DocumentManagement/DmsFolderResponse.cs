using System.Collections.Generic;
using Inprotech.Integration.DmsIntegration.Component.Domain;

namespace Inprotech.Web.DocumentManagement
{
    public class DmsFolderResponse
    {
        public IEnumerable<DmsFolder> Folders { get; set; }
        public IEnumerable<string> Errors { get; set; }

        public bool IsAuthRequired { get; set; }
    }
}