using System.Collections.Generic;

namespace Inprotech.Integration.SchemaMapping.Xsd.Data
{
    public class XsdTree
    {
        public XsdNode Structure { get; internal set; }

        public IEnumerable<Type> Types { get; internal set; }
    }
}
