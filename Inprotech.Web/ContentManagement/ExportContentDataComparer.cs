using System.Collections.Generic;
using InprotechKaizen.Model.Components.ContentManagement.Export;

namespace Inprotech.Web.ContentManagement
{
    public class ExportContentDataComparer : IEqualityComparer<ExportContentData>
    {
        public bool Equals(ExportContentData x, ExportContentData y)
            => y != null && x != null && (x.ContentId == y.ContentId && x.Status == y.Status);

        public int GetHashCode(ExportContentData obj)
            => obj.ContentId.GetHashCode();
    }
}
