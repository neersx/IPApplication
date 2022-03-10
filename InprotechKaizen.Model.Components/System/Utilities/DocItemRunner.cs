using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.System.Utilities
{
    internal class DocItemRunner : IDocItemRunner
    {
        const int CommandTimeout = 30;
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControlReader;
        readonly ISqlHelper _sqlHelper;

        public DocItemRunner(IDbContext dbContext, ISqlHelper sqlHelper, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _sqlHelper = sqlHelper;
            _siteControlReader = siteControlReader;
        }

        public DataSet Run(string docItemName, IDictionary<string, object> parameters)
        {
            var docItem = _dbContext.Set<DocItem>().SingleOrDefault(_ => _.Name == docItemName);
            if (docItem == null) throw new ArgumentException("Requested Data item not found");
            if (parameters != null) parameters = NormaliseParameters(parameters);

            return Run(docItem, parameters);
        }

        public DataSet Run(int docItemId, IDictionary<string, object> parameters, Action<object> docItemAction = null)
        {
            var docItem = _dbContext.Set<DocItem>().SingleOrDefault(_ => _.Id == docItemId);
            if (docItem == null) throw new ArgumentException("Requested Data item not found");
            if (parameters != null) parameters = NormaliseParameters(parameters);
            docItemAction?.Invoke(docItem);
            return Run(docItem, parameters);
        }

        DataSet Run(DocItem docItem, IDictionary<string, object> parameters)
        {
            using var sqlCommand = SqlCommandFactory(docItem, parameters);
            var timeout = _siteControlReader.Read<int?>(SiteControls.DocItemsCommandTimeout);
            sqlCommand.CommandTimeout = timeout ?? CommandTimeout;

            var ds = new DataSet();
            using var adapter = new SqlDataAdapter(sqlCommand);
            adapter.Fill(ds);

            return ds;
        }

        SqlCommand SqlCommandFactory(DocItem docItem, IDictionary<string, object> parameters)
        {
            if (docItem.ItemType == 0) return CreateSqlQueryCommand(docItem.Sql, parameters);
            if (docItem.ItemType is 3 or 1) return CreateStoredProcCommand(docItem.Sql, parameters);

            throw new NotSupportedException($"The ItemType {docItem.ItemType} is not supported");
        }

        internal SqlCommand CreateStoredProcCommand(string sql, IDictionary<string, object> parameters)
        {
            var derivedParams = _sqlHelper.DeriveParameters(sql).ToArray();
            var sqlCommand = _dbContext.CreateSqlCommand(sql, ConstructDerivedParams(derivedParams, parameters), CommandType.StoredProcedure);

            foreach (SqlParameter param in sqlCommand.Parameters)
            {
                param.SqlDbType = derivedParams.Single(_ => _.Key == param.ParameterName).Value;

                if (param.DbType != DbType.String || !string.IsNullOrEmpty((string)param.Value)) continue;
                var emptyParamsAsNulls = _siteControlReader.Read<bool?>(SiteControls.DocItemEmptyParamsAsNulls);
                param.Value = emptyParamsAsNulls == true ? null : string.Empty;
            }

            return sqlCommand;
        }

        IDictionary<string, object> ConstructDerivedParams(IEnumerable<KeyValuePair<string, SqlDbType>> derivedParams, IDictionary<string, object> parameters)
        {
            var paramsCollection = new Dictionary<string, object>();
            foreach (var derivedParam in derivedParams)
            {
                paramsCollection.Add(derivedParam.Key, parameters.TryGetValue(derivedParam.Key, out var paramValue)
                                         ? paramValue : null);
            }

            return paramsCollection;
        }

        internal SqlCommand CreateSqlQueryCommand(string sql, IDictionary<string, object> parameters)
        {
            if (parameters != null)
            {
                if (parameters.TryGetValue("@gstrEntryPoint", out var entryPoint)
                    && entryPoint is string entryPointString
                    && entryPointString.Contains(","))
                {
                    var inClause = new StringBuilder("in (");
                    var entryPoints = entryPointString.Split(',');
                    for (var i = 0; i < entryPoints.Length; i++)
                    {
                        parameters[$"@gstrEntryPoint{i}"] = entryPoints[i];
                        inClause.Append($"@gstrEntryPoint{i}");
                        if (i == entryPoints.Length - 1) continue;
                        inClause.Append(",");
                    }

                    inClause.Append(")");
                    sql = ExpectEntryPointAsCsv(sql, inClause.ToString());

                    parameters.Remove("@gstrEntryPoint");
                }

                sql = ReplaceParametersInSql(sql, parameters.Keys.Distinct());
            }

            var concatNullYieldsNull = _siteControlReader.Read<bool?>(SiteControls.DocItemConcatNull);
            if (concatNullYieldsNull == false)
            {
                sql = "SET CONCAT_NULL_YIELDS_NULL OFF" + Environment.NewLine + sql;
            }

            return _dbContext.CreateSqlCommand(sql, parameters);
        }

        internal static IDictionary<string, object> NormaliseParameters(
            IEnumerable<KeyValuePair<string, object>> parameters)
        {
            return parameters.ToDictionary(_ => "@" + _.Key, _ => _.Value ?? DBNull.Value);
        }

        internal static string ReplaceParametersInSql(string sql, IEnumerable<string> parameters)
        {
            return parameters.Aggregate(sql, (current, param) => current.Replace(param.Replace("@", ":"), param));
        }

        static string ExpectEntryPointAsCsv(string sql, string replacement)
        {
            return sql.Replace("=:gstrEntryPoint", replacement)
                      .Replace("= :gstrEntryPoint", replacement);
        }
    }

    public static class DataSetExtension
    {
        public static T ScalarValue<T>(this DataSet dataSet)
        {
            var table = dataSet.Tables[0];
            var row = table.Rows[0];
            return row.Field<T>(table.Columns[0]);
        }

        public static T ScalarValueOrDefault<T>(this DataSet dataSet)
        {
            var table = dataSet?.Tables.Count > 0 ? dataSet.Tables[0] : new DataTable();
            var row = table.Rows.Count > 0 ? table.Rows[0] : table.NewRow();
            return table.Columns.Count > 0
                ? row.Field<T>(table.Columns[0])
                : default;
        }

        public static IEnumerable<T> MultipleScalarValueOrDefault<T>(this DataSet dataSet)
        {
            var table = dataSet?.Tables.Count > 0 ? dataSet.Tables[0] : new DataTable();
            foreach (DataRow row in table.Rows)
            {
                yield return table.Columns.Count > 0
                    ? row.Field<T>(table.Columns[0])
                    : default;
            }
        }
    }

    public static class DefaultDocItemParameters
    {
        public static Dictionary<string, object> ForDocItemSqlQueries(object entryPoint = null, object userId = null, string culture = null)
        {
            return new Dictionary<string, object>
            {
                { "gstrEntryPoint", entryPoint },
                { "gstrUserId", userId },
                { "gstrCulture", culture },
                { "p1", null },
                { "p2", null },
                { "p3", null },
                { "p4", null }
            };
        }
    }
}

