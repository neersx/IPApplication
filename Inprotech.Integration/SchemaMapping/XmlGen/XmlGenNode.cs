using System;
using System.Collections.Generic;
using System.Data;
using Inprotech.Integration.SchemaMapping.Data;
using Inprotech.Integration.SchemaMapping.Xsd.Data;
using Attribute = Inprotech.Integration.SchemaMapping.Xsd.Data.Attribute;

namespace Inprotech.Integration.SchemaMapping.XmlGen
{
    internal class XmlGenNode
    {
        readonly DocItemBinding _docItemBinding;
        readonly IXmlValueFormatter _xmlValueFormatter;

        public List<XmlGenNode> Children;

        public ILocalContext Context;

        public object FixedValue;

        public bool IsAttribute;

        public string Name;

        public string Namespace;

        public string SubType;

        public XmlGenNode()
        {
            Children = new List<XmlGenNode>();
            _xmlValueFormatter = new DefaultXmlValueFormatter();
        }

        public XmlGenNode(IMappingEntryLookup mappingEntryLookup, IXmlValueFormatter xmlValueFormatter,
                          XmlGenNode parent, XsdNode xsdNode, DataRow row) : this()
        {
            if (xmlValueFormatter == null) throw new ArgumentNullException(nameof(xmlValueFormatter));
            _xmlValueFormatter = xmlValueFormatter;

            XsdNode = xsdNode;
            if (!(xsdNode is Attribute || xsdNode is Element || xsdNode is Choice || XsdNode is Sequence))
            {
                throw new NotSupportedException("node type not supported. must be either element or attribute.");
            }

            Name = xsdNode.Name;
            Namespace = xsdNode.Namespace;
            IsAttribute = xsdNode is Attribute;
            FixedValue = mappingEntryLookup.GetFixedValue(xsdNode.Id);
            _docItemBinding = mappingEntryLookup.GetDocItemBinding(xsdNode.Id);
            Context = new LocalContext(parent?.Context, xsdNode.Id, row);
            SubType = mappingEntryLookup.GetMappingInfo(xsdNode.Id)?.SelectedUnionType;
        }

        public XsdNode XsdNode { get; }

        public object GetValue()
        {
            var value = Context.GetDocItemValue(_docItemBinding) ?? FixedValue;

            return _xmlValueFormatter.Format(XsdNode, value, SubType);
        }

        class DefaultXmlValueFormatter : IXmlValueFormatter
        {
            public object Format(XsdNode xsdNode, object value, string selectedUnionType)
            {
                return value;
            }
        }
    }
}