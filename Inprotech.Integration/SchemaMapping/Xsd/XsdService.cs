using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration.SchemaMapping.Data;
using Inprotech.Integration.SchemaMapping.Xsd.Data;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.SchemaMappings;

namespace Inprotech.Integration.SchemaMapping.Xsd
{
    public interface IXsdService
    {
        XsdTree Parse(int packageId, string rootNode);
        XsdMetadata Inspect(int packageId);
        IEnumerable<RootNodeInfo> GetPossibleRootNodes(int packageId);
    }

    class XsdService : IXsdService
    {
        readonly IXsdParser _xsdParser;
        readonly IXsdTreeBuilder _xsdTreeBuilder;
        readonly IDbContext _dbContext;

        public XsdService(IXsdParser xsdParser, IXsdTreeBuilder xsdTreeBuilder, IDbContext dbContext)
        {
            _xsdParser = xsdParser;
            _xsdTreeBuilder = xsdTreeBuilder;
            _dbContext = dbContext;
        }

        public XsdTree Parse(int packageId, string rootNode)
        {
            var result = _xsdParser.ParseAndCompile(packageId);
            
            return _xsdTreeBuilder.Build(result.SchemaSet.RootNodeSchema(rootNode), rootNode);
        }

        public XsdMetadata Inspect(int packageId)
        {
            string[] missingDependencies;
            var result = _xsdParser.Parse(packageId, out missingDependencies);

            if (result.IsValid && !GetPossibleRootNodes(result).Any())
                result.Error = SchemaSetError.IncompletePackage;

            ChangePackageValidity(packageId, result.IsValid);

            return new XsdMetadata(result.Error, missingDependencies);
        }

        public IEnumerable<RootNodeInfo> GetPossibleRootNodes(int packageId)
        {
            string[] missingDependencies;
            var parseResult = _xsdParser.Parse(packageId, out missingDependencies);
            if (missingDependencies.Any())
                return Enumerable.Empty<RootNodeInfo>();

            return GetPossibleRootNodes(parseResult);
        }

        IEnumerable<RootNodeInfo> GetPossibleRootNodes(XsdParseResult parseResult)
        {
            if (parseResult.IsValid && parseResult.SchemaSet != null)
            {
                return _xsdParser.FindRootNodes(parseResult.SchemaSet);
            }

            return Enumerable.Empty<RootNodeInfo>();
        }

        void ChangePackageValidity(int packageId, bool validity)
        {
            var schemaPackage = _dbContext.Set<SchemaPackage>().SingleOrDefault(_ => _.Id == packageId);
            if (schemaPackage == null || schemaPackage.IsValid == validity)
                return;
            schemaPackage.IsValid = validity;
            _dbContext.SaveChanges();
        }
    }
}