using System.Collections.Generic;
using Inprotech.Infrastructure.Formatting;
using Newtonsoft.Json;

namespace Inprotech.Integration.SchemaMapping.Xsd
{
    public class XsdMetadata
    {
        internal XsdMetadata(SchemaSetError schemaError, IEnumerable<string> missingDependencies = null)
        {
            SchemaError = schemaError;
            MissingDependencies = missingDependencies;
        }

        public bool IsMappable => SchemaError == SchemaSetError.None;

        [JsonConverter(typeof(CamelCaseStringEnumConverter))]
        public SchemaSetError SchemaError { get; }

        public IEnumerable<string> MissingDependencies { get; }
    }
}