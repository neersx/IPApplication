using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Inprotech.Web.Configuration.KeepOnTopNotes
{
    public class KeepOnTopSearchOptions
    {
        public KeepOnTopSearchOptions()
        {
            Modules = Enumerable.Empty<string>();
            Statuses = Enumerable.Empty<string>();
            Roles = Enumerable.Empty<string>();
        }

        public IEnumerable<string> Modules { get; set; }
        public string Type { get; set; }
        public IEnumerable<string> Statuses { get; set; }
        public IEnumerable<string> Roles { get; set; }
    }
}
