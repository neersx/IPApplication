using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Schema;

namespace Inprotech.Integration.SchemaMapping.Xsd
{
    internal class XsdManager
    {
        readonly Dictionary<string, XmlSchemaType> _lookup;

        public XsdManager(XmlSchema schema, string rootNode)
        {
            if (!schema.IsCompiled)
            {
                throw new Exception("Schema is not compiled");
            }

            Schema = schema;
            //todo: use strong name
            _lookup = schema.Items.OfType<XmlSchemaType>().ToDictionary(_ => _.Name);

            RootElement = Schema.RootNodeElement(rootNode);
        }

        public XmlSchema Schema { get; }

        public XmlSchemaElement RootElement { get; }

        public XmlSchemaType EnsureSchemaType(XmlSchemaType schemaType)
        {
            //todo: use strong name
            if (schemaType.Name != null && _lookup.ContainsKey(schemaType.Name))
            {
                return schemaType;
            }

            if (schemaType.IsBuiltIn())
            {
                schemaType.Name = schemaType.TypeCode.ToString();
            }
            else if (schemaType.Name == null) //anonymous type
            {
                //todo: use strong name to avoid conflicts
                var name = $"_type{schemaType.LineNumber}_{schemaType.LinePosition}";

                schemaType.Name = name;
            }

            _lookup[schemaType.Name] = schemaType;

            return schemaType;
        }

        public IEnumerable<XmlSchemaType> GetAllTypes()
        {
            return _lookup.Values;
        }
    }
}