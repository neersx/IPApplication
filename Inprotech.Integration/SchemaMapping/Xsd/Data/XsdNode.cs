using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Schema;
using Inprotech.Infrastructure.Security;
using Newtonsoft.Json;

namespace Inprotech.Integration.SchemaMapping.Xsd.Data
{
    public abstract class XsdNode
    {
        readonly XmlSchemaObject _schemaObj;

        protected XsdNode(XmlSchemaObject schemaObj)
        {
            if (schemaObj == null) throw new ArgumentNullException("schemaObj");
            _schemaObj = schemaObj;
            Children = Enumerable.Empty<XsdNode>();
        }

        public string Id
        {
            get
            {
                var path = GetPath() + NormalizeDuplicatePaths();
                return Hash.Md5(path);
            }
        }

        public string ParentId => Parent?.Id;

        [JsonIgnore]
        public XsdNode Parent { get; internal set; }

        public abstract string NodeType { get; }

        public abstract string Name { get; }

        public abstract string Namespace { get; }

        public int Line => _schemaObj.LineNumber;

        public int Column => _schemaObj.LinePosition;

        public IEnumerable<XsdNode> Children { get; internal set; }

        internal string GetPath(bool withNameSpace = true)
        {
            var n = !withNameSpace || string.IsNullOrEmpty(Namespace) ? Name : "{" + Namespace + "}" + Name;

            if (Parent == null)
            {
                return n;
            }

            return Parent.GetPath(withNameSpace) + "/" + n;
        }

        string NormalizeDuplicatePaths()
        {
            if (Parent?.Children.Count(_ => _.Name == Name && _.NodeType == NodeType) > 1)
                return $"_{Line}";
            return string.Empty;
        }
    }
}