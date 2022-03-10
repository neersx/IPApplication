using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using Inprotech.Contracts.DocItems;
using Inprotech.Integration.SchemaMapping.Data;
using Inprotech.Integration.SchemaMapping.Xsd.Data;

namespace Inprotech.Integration.SchemaMapping.XmlGen
{
    interface IXmlGenTreeTransformer
    {
        XmlGenNode Transform(IGlobalContext globalContext, XsdNode root, IMappingEntryLookup mappingEntryLookup);
    }

    class XmlGenTreeTransformer : IXmlGenTreeTransformer
    {
        readonly IDocItemRunner _docItemRunner;
        readonly IXmlValueFormatter _xmlValueFormatter;
        IMappingEntryLookup _mappingEntryLookup;
        IGlobalContext _globalContext;

        public XmlGenTreeTransformer(IDocItemRunner docItemRunner, IXmlValueFormatter xmlValueFormatter)
        {
            if (docItemRunner == null) throw new ArgumentNullException("docItemRunner");
            if (xmlValueFormatter == null) throw new ArgumentNullException("xmlValueFormatter");

            _docItemRunner = docItemRunner;
            _xmlValueFormatter = xmlValueFormatter;
        }

        public XmlGenNode Transform(IGlobalContext globalContext, XsdNode root, IMappingEntryLookup mappingEntryLookup)
        {
            _globalContext = globalContext;
            _mappingEntryLookup = mappingEntryLookup;

            var r = TransformInternal(null, root).SingleOrDefault(); //we might need to handle root node in a different way e.g. passing external parameters

            if (r == null)
                throw XmlGenExceptionHelper.NoXmlElementGenerated();

            return r;
        }

        IEnumerable<XmlGenNode> TransformInternal(XmlGenNode parent, XsdNode node)
        {
            var docItem = _mappingEntryLookup.GetDocItem(node.Id);

            if (docItem != null)
            {
                var dataSet = RunDocItem(docItem, node);
                var tables = dataSet.Tables;
                if (tables.Count > 1)
                {
                    //todo: show warning
                }

                var table = tables[0];
                var results = new List<XmlGenNode>();

                foreach (DataRow row in table.Rows)
                {
                    var current = BuildNode(parent, node, row);
                    results.Add(current);
                }
                return results;
            }
            return new[] { BuildNode(parent, node) };
        }

        XmlGenNode BuildNode(XmlGenNode parent, XsdNode xsdNode, DataRow row = null)
        {
            var current = new XmlGenNode(_mappingEntryLookup, _xmlValueFormatter, parent, xsdNode, row);

            foreach (var child in xsdNode.Children)
            {
                var r = TransformInternal(current, child);

                current.Children.AddRange(r);
            }

            return current;
        }

        DataSet RunDocItem(DocItem docItem, XsdNode node)
        {
            var parameters = docItem.BuildParameters(_globalContext);
            try
            {
                return _docItemRunner.Run(docItem.Id, parameters, item => docItem.Name = ((InprotechKaizen.Model.Documents.DocItem)item).Name);
            }
            catch (NullReferenceException)
            {
                throw XmlGenExceptionHelper.DocItemNotFound(docItem.Id, node.GetPath(false));
            }
            catch (Exception ex)
            {
                throw XmlGenExceptionHelper.DocItemExecutionFailed(docItem, ex);
            }
        }
    }
}