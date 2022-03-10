using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Threading.Tasks;
using System.Xml.Linq;
using System.Xml.Schema;
using Inprotech.Integration.SchemaMapping.Data;
using Inprotech.Integration.SchemaMapping.Xsd;
using Inprotech.Integration.SchemaMapping.Xsd.Data;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.SchemaMapping.XmlGen
{
    public interface IXmlGenService
    {
        Task<XDocument> Generate(int mappingId, IDictionary<string, object> parameters = null);
    }

    internal class XmlGenService : IXmlGenService
    {
        readonly IDbContext _dbContext;
        readonly Func<IDictionary<string, object>, IGlobalContext> _globalContext;
        readonly Func<string, IMappingEntryLookup> _mappingEntryLookup;
        readonly IXmlNameSpaceCleaner _nameSpaceCleaner;
        readonly IXDocumentTransformer _xDocumentTransformer;
        readonly IXmlGenTreeTransformer _xmlGenTreeTransformer;
        readonly IXmlValidator _xmlValidator;
        readonly IXsdParser _xsdParser;
        readonly IXsdTreeBuilder _xsdTreeBuilder;

        public XmlGenService(IDbContext dbContext, IXsdTreeBuilder xsdTreeBuilder, Func<string, IMappingEntryLookup> mappingEntryLookup, IXmlGenTreeTransformer xmlGenTreeTransformer, IXDocumentTransformer xDocumentTransformer, IXmlValidator xmlValidator, Func<IDictionary<string, object>, IGlobalContext> globalContext,
                             IXsdParser xsdParser, IXmlNameSpaceCleaner nameSpaceCleaner)
        {
            _dbContext = dbContext;
            _xsdTreeBuilder = xsdTreeBuilder;
            _mappingEntryLookup = mappingEntryLookup;
            _xmlGenTreeTransformer = xmlGenTreeTransformer;
            _xDocumentTransformer = xDocumentTransformer;
            _xmlValidator = xmlValidator;
            _globalContext = globalContext;
            _xsdParser = xsdParser;
            _nameSpaceCleaner = nameSpaceCleaner;
        }

        public async Task<XDocument> Generate(int mappingId, IDictionary<string, object> parameters = null)
        {
            var globalContext = _globalContext(parameters);
            var schemaMapping = await GetMapping(mappingId);
            var mappingInfoLookup = _mappingEntryLookup(schemaMapping.Content);

            var xsdParseResult = ParseSchema(schemaMapping.SchemaPackageId);
            var xsdRoot = BuildXsdTree(xsdParseResult.SchemaSet.RootNodeSchema(schemaMapping.RootNode), schemaMapping.RootNode);
            var xmlGenRoot = _xmlGenTreeTransformer.Transform(globalContext, xsdRoot, mappingInfoLookup);
            var xdoc = _xDocumentTransformer.Transform(xmlGenRoot);
            xdoc = BuildDocTypeNode(xdoc, schemaMapping.RootNode);

            ValidateXml(xsdParseResult.SchemaSet, xdoc);

            return _nameSpaceCleaner.Clean(xdoc);
        }

        async Task<InprotechKaizen.Model.SchemaMappings.SchemaMapping> GetMapping(int mappingId)
        {
            var schemaMapping = await _dbContext.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>().SingleOrDefaultAsync(_ => _.Id == mappingId);
            if (schemaMapping == null)
            {
                throw XmlGenExceptionHelper.MappingNotFound(mappingId);
            }

            return schemaMapping;
        }

        XsdParseResult ParseSchema(int schemaPackageId)
        {
            try
            {
                //return _xsdService.GetTreeAndSchema(schemaPackageId,rootNode, out schemaSet);
                return _xsdParser.ParseAndCompile(schemaPackageId);
            }
            catch (MissingSchemaDependencyException ex)
            {
                throw XmlGenExceptionHelper.MissingDependencies(ex.MissingDependencies);
            }
            catch (Exception ex)
            {
                throw XmlGenExceptionHelper.ParseXsdFailed(ex);
            }
        }

        XsdNode BuildXsdTree(XmlSchema schema, string rootNode)
        {
            XsdNode xsdRoot;

            try
            {
                xsdRoot = _xsdTreeBuilder.Build(schema, rootNode).Structure;
            }
            catch (Exception ex)
            {
                throw XmlGenExceptionHelper.BuildXsdTreeFailed(ex);
            }

            return xsdRoot;
        }

        XDocument BuildDocTypeNode(XDocument xdoc, string rootNode)
        {
            if (!string.IsNullOrEmpty(rootNode))
            {
                var nodeInfo = new RootNodeInfo().ParseJson(rootNode);
                if (nodeInfo.IsDtdFile && !string.IsNullOrEmpty(nodeInfo.FileRef))
                {
                    xdoc.AddFirst(new XDocumentType(nodeInfo.QualifiedName.Name, null, nodeInfo.FileRef, null));
                }
            }
            return xdoc;
        }

        void ValidateXml(XmlSchemaSet schemaSet, XDocument xdoc)
        {
            string errors;
            if (!_xmlValidator.Validate(schemaSet, xdoc, out errors))
            {
                throw XmlGenExceptionHelper.XmlValidationFailed(xdoc.ToString(), errors);
            }
        }
    }
}