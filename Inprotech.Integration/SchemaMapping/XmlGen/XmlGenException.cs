using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Runtime.Serialization;
using System.Security.Permissions;
using Inprotech.Integration.SchemaMapping.Data;

namespace Inprotech.Integration.SchemaMapping.XmlGen
{
    [Serializable]
    public class XmlGenException : Exception
    {
        public XmlGenException()
        {
        }

        public XmlGenException(string error) : base(error)
        {
        }

        public XmlGenException(string error, Exception innerException) : base(error, innerException)
        {
        }

        [SecurityPermission(SecurityAction.Demand, SerializationFormatter = true)]
        protected XmlGenException(SerializationInfo info, StreamingContext context)
            : base(info, context)
        {
        }
    }

    [Serializable]
    public class XmlGenValidationException : XmlGenException
    {
        public XmlGenValidationException(string xml, string errors) : base(errors)
        {
            OutputXml = xml;
        }

        [SecurityPermission(SecurityAction.Demand, SerializationFormatter = true)]
        protected XmlGenValidationException(SerializationInfo info, StreamingContext context)
            : base(info, context)
        {
            OutputXml = (string) info.GetValue("OutputXml", typeof(string));
        }

        public string OutputXml { get; }

        [SecurityPermission(SecurityAction.Demand, SerializationFormatter = true)]
        public override void GetObjectData(SerializationInfo info, StreamingContext context)
        {
            info.AddValue("OutputXml", OutputXml, typeof(string));
            base.GetObjectData(info, context);
        }
    }

    internal static class XmlGenExceptionHelper
    {
        public static XmlGenException MappingNotFound(int mappingId)
        {
            return new XmlGenException($"Schema mapping not found: mappingid={mappingId}");
        }

        public static XmlGenException ReadSchemaFileFailed(string fileName, Exception innerException)
        {
            return new XmlGenException($"Failed to read schema file: {fileName}", innerException);
        }

        public static XmlGenException ParseXsdFailed(Exception innerException)
        {
            return new XmlGenException("Falied to parse schema", innerException);
        }

        public static XmlGenException BuildXsdTreeFailed(Exception innerException)
        {
            return new XmlGenException("Falied to build xsd tree view", innerException);
        }

        public static XmlGenException MissingDependencies(IEnumerable<string> required)
        {
            return new XmlGenException($"Missing schema dependencies: \n{string.Join("\n", required)}");
        }

        public static XmlGenException NoXmlElementGenerated()
        {
            return new XmlGenException("No xml element has been generated. This might be caused by no docitem values returned during the generation process.");
        }

        public static XmlGenException DocItemNotFound(int docItemId, string nodePath)
        {
            return new XmlGenException($"Data item not found: data item id={docItemId}, node={nodePath}");
        }

        public static XmlGenException DocItemExecutionFailed(DocItem docItem, Exception innerException)
        {
            return new XmlGenException($"Failed to execute docitem: docitemname={docItem.Name} (id: {docItem.Id})\nParameters: {BuildParametersString(docItem.CachedParameters)}", innerException);
        }

        public static XmlGenException DocItemBoundNodeNotFound(DocItemBinding binding)
        {
            return new XmlGenException($"The data item not found in the node: nodeid={binding.NodeId}, data item id={binding.DocItemId}, columnid={binding.ColumnId}");
        }

        public static XmlGenException ReadDocItemColumnFailed(DocItemBinding binding, DataRow actualValue, Exception innerException)
        {
            var dataRowStr = BuildDataRowString(actualValue);
            return
                new XmlGenException(
                                    $"Failed to get docitem column: nodeid={binding.NodeId}, docitemid={binding.DocItemId}, columnid={binding.ColumnId}\nActual data row: {dataRowStr}", innerException);
        }

        public static XmlGenValidationException XmlValidationFailed(string xml, string errors)
        {
            return new XmlGenValidationException(xml, $"Xml validation failed: {errors}");
        }

        public static XmlGenException GlobalParameterNotFound(string name)
        {
            return new XmlGenException($"Unable to find global parameter: {name}");
        }

        public static XmlGenException ParameterTypeNotSupported(string type)
        {
            return new XmlGenException($"Unsupported parameter type: {type}");
        }

        static string BuildParametersString(IDictionary<string, object> parameters)
        {
            return parameters == null ? "null" : string.Join(", ", parameters.Select(_ => $"{_.Key}={_.Value}"));
        }

        static string BuildDataRowString(DataRow row)
        {
            if (row == null)
            {
                return "null";
            }

            var list = new List<string>();

            for (var i = 0; i < row.Table.Columns.Count; i++)
                list.Add($"{i}={row[i]}");

            return string.Join(", ", list);
        }
    }
}