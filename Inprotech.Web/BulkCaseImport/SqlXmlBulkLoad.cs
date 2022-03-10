using System;
using System.IO;
using Inprotech.Infrastructure;
using SQLXMLBULKLOADLib;

namespace Inprotech.Web.BulkCaseImport
{
    public interface ISqlXmlBulkLoad
    {
        bool TryExecute(string xsdLocation, string xmlInput, out string error);
    }

    public class SqlXmlBulkLoad : ISqlXmlBulkLoad
    {
        readonly ISqlXmlConnectionStringBuilder _connectionStringBuilder;
        readonly IConnectionStrings _connectionStrings;

        public SqlXmlBulkLoad(ISqlXmlConnectionStringBuilder connectionStringBuilder, IConnectionStrings connectionStrings)
        {
            _connectionStringBuilder = connectionStringBuilder;
            _connectionStrings = connectionStrings;
        }

        public bool TryExecute(string xsdLocation, string xmlInput, out string error)
        {
            if (string.IsNullOrWhiteSpace(xsdLocation)) throw new ArgumentNullException(nameof(xsdLocation));
            if (string.IsNullOrWhiteSpace(xmlInput)) throw new ArgumentNullException(nameof(xmlInput));

            error = string.Empty;

            var xsd = Path.IsPathRooted(xsdLocation) ? xsdLocation : Path.GetFullPath(xsdLocation);

            var sqlBulkLoadErrorLogLocation = Path.Combine(Path.GetTempPath(), Path.GetTempFileName());

            var connectionString = _connectionStringBuilder.BuildFrom(_connectionStrings["Inprotech"]);

            var sqlBulkLoad = new SQLXMLBulkLoad4Class
            {
                ConnectionString = connectionString,
                ErrorLogFile = sqlBulkLoadErrorLogLocation,
                SchemaGen = true,
                ForceTableLock = false,
                KeepIdentity = false
            };

            sqlBulkLoad.Execute(xsd, xmlInput);

            if (File.Exists(sqlBulkLoadErrorLogLocation))
            {
                error = File.ReadAllText(sqlBulkLoadErrorLogLocation);
                File.Delete(sqlBulkLoadErrorLogLocation);
            }

            return string.IsNullOrWhiteSpace(error);
        }
    }
}