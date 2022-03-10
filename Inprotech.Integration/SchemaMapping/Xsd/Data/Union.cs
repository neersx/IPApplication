using System.Collections.Generic;
using System.Xml.Schema;

namespace Inprotech.Integration.SchemaMapping.Xsd.Data
{
    class Union : Type
    {
        public IEnumerable<string> UnionTypes { get; internal set; }        

        public Union(XmlSchemaType type) : base(type)
        {
            DataType = null;
        }
    }
}