using System;
using System.Data.Common;
using System.Data.SqlClient;
using Inprotech.Infrastructure;

namespace Inprotech.Web.BulkCaseImport
{
    public interface ISqlXmlConnectionStringBuilder
    {
        string BuildFrom(string connectionString);
    }

    public class SqlXmlConnectionStringBuilder : ISqlXmlConnectionStringBuilder
    {
        readonly Func<string, IGroupedConfig> _groupedConfig;
        const string SqlBulkLoadProviderKey = "SqlBulkLoadProvider";
        const string DefaultProvider = "MSOLEDBSQL";

        public SqlXmlConnectionStringBuilder(Func<string, IGroupedConfig> groupedConfig)
        {
            _groupedConfig = groupedConfig;
        }

        public string BuildFrom(string connectionString)
        {
            var sql = new SqlConnectionStringBuilder { ConnectionString = connectionString };

            var values = _groupedConfig(KnownSettingGroupKeys.Ede);
            var provider = values.GetValueOrDefault<string>(SqlBulkLoadProviderKey);
            if (string.IsNullOrWhiteSpace(provider))
            {
                provider = DefaultProvider;
            }

            var builder = new DbConnectionStringBuilder
                          {
                              {"Provider", provider},
                              {"Data Source", sql.DataSource},
                              {"Database", sql.InitialCatalog},
                              {"Application Name", sql.ApplicationName}
                          };

            if (sql.IntegratedSecurity)
            {
                builder["Integrated Security"] = "SSPI";
            }
            else
            {
                builder["User Id"] = sql.UserID;
                builder["Password"] = sql.Password;
            }

            return builder.ConnectionString;
        }
    }
}