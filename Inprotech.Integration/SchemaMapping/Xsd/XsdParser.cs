using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml;
using System.Xml.Schema;
using Inprotech.Contracts;
using Inprotech.Integration.SchemaMapping.Data;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.SchemaMappings;

namespace Inprotech.Integration.SchemaMapping.Xsd
{
    public enum SchemaSetError
    {
        MissingDependencies,
        ValidationError,
        FilesRequired,
        IncompletePackage,
        None
    }

    internal interface IXsdParser
    {
        XsdParseResult Parse(int packageId, out string[] missingDependencies);
        XsdParseResult ParseAndCompile(int packageId);
        IEnumerable<RootNodeInfo> FindRootNodes(XmlSchemaSet schemaSet);
    }

    internal class XsdParseResult
    {
        public XmlSchemaSet SchemaSet { get; set; }
        public SchemaSetError Error { get; set; }
        public bool IsValid => Error == SchemaSetError.None;
    }

    internal class XsdParser : IXsdParser
    {
        const string DtdExtension = "dtd";
        readonly IDbContext _dbContext;
        readonly IDtdReader _dtdReader;
        readonly IBackgroundProcessLogger<XsdParser> _logger;
        readonly List<string> _validationErrors = new List<string>();

        public XsdParser(IDbContext dbContext, IDtdReader dtdReader, IBackgroundProcessLogger<XsdParser> logger)
        {
            _dbContext = dbContext;
            _dtdReader = dtdReader;
            _logger = logger;
        }

        public XsdParseResult Parse(int packageId, out string[] missingDependencies)
        {
            missingDependencies = new string[0];
            var required = new List<string>();

            var schemaFiles = _dbContext.Set<SchemaFile>().Where(_ => _.SchemaPackageId == packageId).ToList();
            if (schemaFiles.Count == 0)
            {
                return new XsdParseResult { Error = SchemaSetError.FilesRequired };
            }

            var loadedDependencies = new List<string>();
            var loadFilesSchemas = new Dictionary<string, XmlSchemaSet>();
            foreach (var file in schemaFiles)
            {
                var schemaSetTemp = new XmlSchemaSet
                {
                    XmlResolver = new CustomResolver(uri =>
                    {
                        var fname = GetFileName(uri);

                        var schemaFile = schemaFiles.SingleOrDefault(_ => _.Name == fname);
                        if (schemaFile == null)
                        {
                            required.Add(fname);
                            return null;
                        }
                        if (!loadedDependencies.Contains(fname))
                        {
                            loadedDependencies.Add(fname);
                        }
                        return new StringReader(schemaFile.Content);
                    })
                };

                if (loadedDependencies.Contains(file.Name))
                {
                    continue;
                }

                string fileContent;
                if (file.Name.EndsWith(DtdExtension, StringComparison.InvariantCultureIgnoreCase))
                {
                    var dtdResult = _dtdReader.Convert(file, schemaFiles);
                    fileContent = dtdResult.Xsd;
                    missingDependencies = dtdResult.MissingDependecies.ToArray();
                    required.AddRange(missingDependencies);
                    loadedDependencies.AddRange(dtdResult.LoadedDependecies);

                    if (missingDependencies.Any())
                    {
                        return new XsdParseResult { Error = SchemaSetError.MissingDependencies };
                    }
                }
                else
                {
                    fileContent = file.Content;
                }

                using (var reader = new XmlTextReader(new StringReader(fileContent)))
                {
                    var schema = XmlSchema.Read(reader, null);

                    schema.Id = XmlConvert.EncodeName(file.Name);

                    schemaSetTemp.Add(schema);
                    loadFilesSchemas.Add(file.Name, schemaSetTemp);
                }
            }

            var schemaSet = LoadUniqueSchemaSets(loadFilesSchemas, loadedDependencies);

            missingDependencies = required.Distinct().ToArray();
            if (!missingDependencies.Any())
            {
                schemaSet.Compile();
                if (!schemaSet.IsCompiled)
                {
                    missingDependencies = ReadDependencyNameFromSchema(schemaSet)
                        .Except(loadedDependencies)
                        .ToArray();

                    if (!missingDependencies.Any() && _validationErrors.Any())
                    {
                        CleanDtdNamespaceForErrorLogging(schemaFiles.Select(_ => _.Name));
                        _logger.Warning("Validation failed for schema", _validationErrors);
                    }

                }
            }

            return new XsdParseResult
            {
                SchemaSet = schemaSet,
                Error = missingDependencies.Any()
                    ? SchemaSetError.MissingDependencies
                    : (!schemaSet.IsCompiled ? SchemaSetError.ValidationError : SchemaSetError.None)
            };
        }

        public XsdParseResult ParseAndCompile(int packageId)
        {
            string[] missingDependencies;
            var result = Parse(packageId, out missingDependencies);

            if (missingDependencies.Any())
            {
                throw new MissingSchemaDependencyException(missingDependencies);
            }
            if (result.Error == SchemaSetError.ValidationError)
            {
                throw new Exception("xsd Validation Error");
            }

            return result;
        }

        public IEnumerable<RootNodeInfo> FindRootNodes(XmlSchemaSet schemaSet)
        {
            var globalElements = schemaSet.Schemas()
                                          .OfType<XmlSchema>()
                                          .Where(_ => !string.IsNullOrEmpty(_.Id))
                                          .SelectMany(_ => _.Elements.Values.OfType<XmlSchemaElement>().Select(p => new RootNodeInfo { Node = p, FileName = XmlConvert.DecodeName(_.Id) }))
                                          .ToList();

            var globalComplexElements = globalElements.Where(_ => _.Node.ElementSchemaType is XmlSchemaComplexType).ToList();

            if (globalElements.Count == 1 || globalComplexElements.Count == 0)
            {
                return globalElements;
            }

            var nestedTypes = schemaSet.GlobalTypes.Values.OfType<XmlSchemaComplexType>()
                                       .Select(_ => _.ContentTypeParticle)
                                       .OfType<XmlSchemaGroupBase>()
                                       .SelectMany(_ => _.GetNestedTypes())
                                       .ToList();

            nestedTypes.AddRange(globalComplexElements.Select(_ => _.Node.ElementSchemaType)
                                                      .OfType<XmlSchemaComplexType>()
                                                      .Select(_ => _.ContentTypeParticle)
                                                      .OfType<XmlSchemaGroupBase>()
                                                      .SelectMany(_ => _.GetNestedTypes())
                                                      .ToList());

            return globalComplexElements.Where(_ => !nestedTypes.Select(nested => nested.QualifiedName)
                                                                .Contains(_.Node.QualifiedName));
        }

        XmlSchemaSet LoadUniqueSchemaSets(Dictionary<string, XmlSchemaSet> loadFilesSchemas, List<string> loadedDependencies)
        {
            var schemaSet = new XmlSchemaSet();
            foreach (var fileSchema in loadFilesSchemas)
            {
                if (!loadedDependencies.Contains(fileSchema.Key))
                {
                    schemaSet.Add(fileSchema.Value);
                }
            }
            schemaSet.ValidationEventHandler += SchemaSet_ValidationEventHandler;
            return schemaSet;
        }

        void SchemaSet_ValidationEventHandler(object sender, ValidationEventArgs e)
        {
            _validationErrors.Add(e.Message);
        }

        IEnumerable<string> ReadDependencyNameFromSchema(XmlSchemaSet schemaSet)
        {
            var missing = new List<string>();
            foreach (var schema in schemaSet.Schemas().OfType<XmlSchema>())
            {
                missing.AddRange(schema.Includes.OfType<XmlSchemaImport>().Select(include => include.SchemaLocation));
                missing.AddRange(schema.Includes.OfType<XmlSchemaInclude>().Select(include => include.SchemaLocation));
            }

            return missing;
        }

        string GetFileName(Uri uri)
        {
            if (uri.IsFile || !string.IsNullOrEmpty(Path.GetExtension(uri.AbsolutePath)))
            {
                return Path.GetFileName(uri.AbsolutePath);
            }

            return Path.GetFileName(uri.PathAndQuery);
        }

        void CleanDtdNamespaceForErrorLogging(IEnumerable<string> schemaFiles)
        {
            if (!schemaFiles.Any(_ => _.EndsWith(DtdExtension, StringComparison.InvariantCultureIgnoreCase)))
                return;

            var count = _validationErrors.Count;
            for (int i = 0; i < count; i++)
            {
                _validationErrors[i] = _validationErrors[i].Replace($"{Constants.TempNameSpace}:", string.Empty);
            }

        }

        class CustomResolver : XmlResolver
        {
            readonly Func<Uri, object> _resolveUri;

            public CustomResolver(Func<Uri, object> resolveUri)
            {
                _resolveUri = resolveUri;
            }

            public override object GetEntity(Uri absoluteUri, string role, Type ofObjectToReturn)
            {
                return _resolveUri(absoluteUri);
            }
        }
    }
}