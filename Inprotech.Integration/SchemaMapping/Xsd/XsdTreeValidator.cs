using System;
using System.Collections.Generic;
using Inprotech.Integration.SchemaMapping.Xsd.Data;

namespace Inprotech.Integration.SchemaMapping.Xsd
{
    class XsdTreeValidator
    {
        HashSet<string> _ids;
        public void Validate(XsdNode root)
        {
            _ids = new HashSet<string>();
            ValidateInternal(root);
        }

        void ValidateInternal(XsdNode node)
        {
            if (node == null)
                return;

            if(_ids.Contains(node.Id))
                throw new Exception("Duplicate id: path=" + node.GetPath());

            _ids.Add(node.Id);

            if (node.Children == null)
                return;

            foreach(var child in node.Children)
                ValidateInternal(child);
        }
    }
}
