using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Integration.DmsIntegration.Component.Domain
{
    public class DmsSettings
    {
        public DmsSettings()
        {
            NameTypesRequired = Enumerable.Empty<string>();
        }
        public virtual IEnumerable<string> NameTypesRequired { get; }
    }
}