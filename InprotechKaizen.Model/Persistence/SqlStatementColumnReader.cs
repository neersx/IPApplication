using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;

namespace InprotechKaizen.Model.Persistence
{
    public interface ISqlStatementColumnReader
    {
        IEnumerable<KeyValuePair<string, string>> DeriveReturnColumnsForSqlStatement(string sql, Dictionary<string, object> parameters = null);

        IEnumerable<ReturnColumnSchema> DeriveReturnColumnsSchemaForSqlStatement(string sql, Dictionary<string, object> parameters = null);
    }

    internal class SqlStatementColumnReaderLegacy : ISqlStatementColumnReader
    {
        readonly IDbContext _dbContext;

        public SqlStatementColumnReaderLegacy(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IEnumerable<KeyValuePair<string, string>> DeriveReturnColumnsForSqlStatement(string sql, Dictionary<string, object> parameters = null)
        {
            var results = new List<KeyValuePair<string, string>>();
            var sqlCommand = _dbContext.CreateSqlCommand($"SET FMTONLY ON\n{sql}\nSET FMTONLY OFF", parameters);

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

        public IEnumerable<ReturnColumnSchema> DeriveReturnColumnsSchemaForSqlStatement(string sql, Dictionary<string, object> parameters = null)
        {
            var results = new List<ReturnColumnSchema>();
            var sqlCommand = _dbContext.CreateSqlCommand($"SET FMTONLY ON\n{sql}\nSET FMTONLY OFF", parameters);

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
    }

    internal class SqlStatementColumnReader : ISqlStatementColumnReader
    {
        readonly IDbContext _dbContext;

        public SqlStatementColumnReader(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IEnumerable<KeyValuePair<string, string>> DeriveReturnColumnsForSqlStatement(string sql, Dictionary<string, object> parameters = null)
        {
            var results = new List<KeyValuePair<string, string>>();
            var sqlCommand = SqlCommand(sql, parameters);
            int i = 0;
            using (var reader = sqlCommand.ExecuteReader())
            {
                while (reader.Read())
                {
                    var name = reader["name"] == DBNull.Value ? "Column" + i++ : reader["name"].ToString();
                    results.Add(new KeyValuePair<string, string>(name, DataTypeWithoutLength(reader["system_type_name"].ToString())));
                }
            }

            return results;
        }

        public IEnumerable<ReturnColumnSchema> DeriveReturnColumnsSchemaForSqlStatement(string sql, Dictionary<string, object> parameters = null)
        {
            var results = new List<ReturnColumnSchema>();
            var sqlCommand = SqlCommand(sql, parameters);

            using (var reader = sqlCommand.ExecuteReader())
            {
                while (reader.Read())
                {
                    results.Add(new ReturnColumnSchema(reader["name"].ToString(), DataTypeWithoutLength(reader["system_type_name"].ToString()), Convert.ToInt32(reader["tds_length"]) / 2));
                }
            }

            return results;
        }

        string DataTypeWithoutLength(string dataType)
        {
            var index = dataType.IndexOf('(');
            return index > -1 ? dataType.Substring(0, index) : dataType;
        }

        SqlCommand SqlCommand(string sql, Dictionary<string, object> parameters)
        {
            var parameterString = parameters != null && parameters.Any() ? string.Join(", ", parameters.Select(_ => $"{_.Key} {_.Value.ToString()}")) : string.Empty;
            var sqlCommand = _dbContext.CreateStoredProcedureCommand("sp_describe_first_result_set");
            sqlCommand.Parameters.Add(new SqlParameter("@tsql", sql));
            sqlCommand.Parameters.Add(new SqlParameter("@params", parameterString));
            return sqlCommand;
        }
    }
}

    