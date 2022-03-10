using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;

namespace InprotechKaizen.Model.Persistence
{
    public interface ISqlHelper
    {
        IEnumerable<KeyValuePair<string, SqlDbType>> DeriveParameters(string sql);

        IEnumerable<KeyValuePair<string, string>> DeriveReturnColumns(string sql, Dictionary<string, object> parameters = null, bool storedProcedure = false);

        IEnumerable<ReturnColumnSchema> DeriveReturnColumnsSchema(string sql, Dictionary<string, object> parameters = null, bool storedProcedure = false);

        bool IsValidProcedureName(string procName);
    }

    internal class SqlHelper : ISqlHelper
    {
        readonly IDbContext _dbContext;
        readonly ISqlStatementColumnReader _columnReader;

        public SqlHelper(IDbContext dbContext, ISqlStatementColumnReader columnReader)
        {
            _dbContext = dbContext;
            _columnReader = columnReader;
        }

        public bool IsValidProcedureName(string storedProcName)
        {
            var isValidProc = true;
            try
            {
                DeriveParameters(storedProcName);
            }
            catch (Exception)
            {
                isValidProc = false;
            }
            return isValidProc;
        }

        public IEnumerable<KeyValuePair<string, SqlDbType>> DeriveParameters(string sql)
        {
            var sqlCommand = _dbContext.CreateStoredProcedureCommand(sql);

            SqlCommandBuilder.DeriveParameters(sqlCommand);

            return sqlCommand.Parameters
                             .Cast<SqlParameter>()
                             .Where(_ => _.ParameterName != "@RETURN_VALUE")
                             .Select(_ => new KeyValuePair<string, SqlDbType>(_.ParameterName, _.SqlDbType));
        }

        public IEnumerable<KeyValuePair<string, string>> DeriveReturnColumns(string sql, Dictionary<string, object> parameters = null, bool storedProcedure = false)
        {
            if (storedProcedure)
                return DeriveReturnColumnsForStoredProcedure(sql, parameters);
            return _columnReader.DeriveReturnColumnsForSqlStatement(sql, parameters);
        }

        public IEnumerable<ReturnColumnSchema> DeriveReturnColumnsSchema(string sql, Dictionary<string, object> parameters = null, bool storedProcedure = false)
        {
            if (storedProcedure)
                return DeriveReturnColumnsSchemaForStoredProcedure(sql, parameters);
            return _columnReader.DeriveReturnColumnsSchemaForSqlStatement(sql, parameters);
        }

        IEnumerable<KeyValuePair<string, string>> DeriveReturnColumnsForStoredProcedure(string sql, Dictionary<string, object> parameters = null)
        {
            var results = new List<KeyValuePair<string, string>>();
            var sqlCommand = SqlCommand(sql, parameters);

            using (var reader = sqlCommand.ExecuteReader())
            {
                for (var i = 0; i < reader.FieldCount; i++)
                {
                    var name = reader.GetName(i) == string.Empty ? "Column" + (i + 1) : reader.GetName(i);
                    results.Add(new KeyValuePair<string, string>(name, reader.GetDataTypeName(i)));
                }
            }

            return results;
        }

        IEnumerable<ReturnColumnSchema> DeriveReturnColumnsSchemaForStoredProcedure(string sql, Dictionary<string, object> parameters = null)
        {
            var results = new List<ReturnColumnSchema>();
            var sqlCommand = SqlCommand(sql, parameters);

            using (var reader = sqlCommand.ExecuteReader())
            {
                var schemaTable = reader.GetSchemaTable();
                if (schemaTable != null)
                {
                    results.AddRange(from DataRow row in schemaTable.Rows
                                     select new ReturnColumnSchema(row["ColumnName"].ToString(), row["DataTypeName"].ToString(), Convert.ToInt32(row["ColumnSize"])));
                }
            }

            return results;
        }

        SqlCommand SqlCommand(string sql, Dictionary<string, object> parameters)
        {
            var parameterString = parameters != null && parameters.Any() ? string.Join(", ", parameters.Select(_ => " null ")) : string.Empty;

            return _dbContext.CreateSqlCommand($"exec {sql} {parameterString}");

        }
    }

    public class ReturnColumnSchema
    {
        public ReturnColumnSchema(string columnName, string dataTypeName, int columnSize)
        {
            ColumnName = columnName;
            ColumnSize = columnSize;
            DataTypeName = dataTypeName;
        }

        public string ColumnName { get; set; }

        public int ColumnSize { get; set; }

        public string DataTypeName { get; set; }

    }
}

    