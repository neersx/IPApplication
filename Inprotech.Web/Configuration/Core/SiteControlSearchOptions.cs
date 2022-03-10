using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Web.Configuration.Core
{
    public class SiteControlSearchOptions
    {
        public SiteControlSearchOptions()
        {
            ComponentIds = Enumerable.Empty<int>();
            TagIds = Enumerable.Empty<int>();
        }

        public bool IsByName { get; set; }
        public bool IsByDescription { get; set; }
        public bool IsByValue { get; set; }
        public string Text { get; set; }
        public IEnumerable<int> ComponentIds { get; set; }
        public int? VersionId { get; set; }
        public IEnumerable<int> TagIds { get; set; }
    }
}
