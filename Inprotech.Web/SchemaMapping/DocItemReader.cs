using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.DocumentGeneration.Processor;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.SchemaMapping
{
    public interface IDocItemReader
    {
        dynamic Read(int id);
        dynamic ReturnColumnInformation(DocItem item, bool returnsImage);
        IEnumerable<ReturnColumnSchema> ReturnColumnSchema(DocItem item);
        bool InvalidFormatCaseIdForCaseValidation(DocItem item);
    }

    internal class DocItemReader : IDocItemReader
    {
        const string CaseIdFormat = "=:CaseId";
        readonly IDbContext _dbContext;
        readonly ISqlHelper _sqlHelper;

        public DocItemReader(IDbContext dbContext, ISqlHelper sqlHelper)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _sqlHelper = sqlHelper ?? throw new ArgumentNullException(nameof(sqlHelper));
        }

        public dynamic Read(int id)
        {
            var docItem = _dbContext.Set<DocItem>().FirstOrDefault(_ => _.Id == id);
            if (docItem == null)
            {
                return null;
            }

            IEnumerable<KeyValuePair<string, string>> parameters = null;
            IEnumerable<KeyValuePair<string, string>> returnColumns = null;

            switch (docItem.ItemType)
            {
                case 0:
                    string sql;
                    parameters = DeriveParameters(docItem.Sql, out sql);
                    returnColumns = _sqlHelper.DeriveReturnColumns(sql, parameters.ToDictionary(_ => _.Key, _ => (object)_.Value));
                    break;
                case 1:
                case 3:
                    parameters = _sqlHelper.DeriveParameters(docItem.Sql).Select(_ => new KeyValuePair<string, string>(_.Key, _.Value.ToString()));
                    returnColumns = _sqlHelper.DeriveReturnColumns(docItem.Sql, parameters.ToDictionary(_ => _.Key, _ => (object)_.Value), true);
                    break;
            }

            return new
            {
                docItem.Id,
                Code = docItem.Name,
                docItem.Description,
                docItem.Sql,
                Parameters =
                    parameters?.Select((p, index) => new { Name = p.Key.Replace("@", string.Empty), Type = p.Value, Index = index }).ToArray(),
                Columns =
                    returnColumns?.Select((p, index) => new { Name = p.Key, Type = p.Value, Index = index })
                                 .ToArray()
            };
        }

        public dynamic ReturnColumnInformation(DocItem item, bool returnsImage)
        {
            var sqlDescribe = string.Empty;
            var sqlInto = string.Empty;

            var numberCount = 0;
            var stringCount = 0;
            var longStringCount = 0;
            var dateCount = 0;

            var returnColumns = ReturnColumnSchema(item).ToArray();

            foreach (var returnColumn in returnColumns)
            {
                if (!string.IsNullOrEmpty(sqlInto))
                {
                    sqlInto = $"{sqlInto}, ";
                    sqlDescribe = $"{sqlDescribe},";
                }

                if (KnownDbDataTypes.StringDataTypes.Contains(returnColumn.DataTypeName.ToLower()))
                {
                    if (returnColumn.ColumnSize >= 255)
                    {
                        if (returnsImage)
                        {
                            sqlInto = $"{sqlInto}:l[0]";
                            sqlDescribe = $"{sqlDescribe}9";
                        }
                        else
                        {
                            sqlInto = $"{sqlInto}:l[{longStringCount}]";
                            sqlDescribe = $"{sqlDescribe}4";
                            longStringCount++;
                        }
                    }
                    else
                    {
                        sqlInto = $"{sqlInto}:s[{stringCount}]";
                        sqlDescribe = $"{sqlDescribe}1";
                        stringCount++;
                    }
                }
                else if (KnownDbDataTypes.DateDataTypes.Contains(returnColumn.DataTypeName.ToLower()))
                {
                    sqlInto = $"{sqlInto}:d[{dateCount}]";
                    sqlDescribe = $"{sqlDescribe}3";
                    dateCount++;
                }
                else if (KnownDbDataTypes.NumberDataTypes.Contains(returnColumn.DataTypeName.ToLower()))
                {
                    sqlInto = $"{sqlInto}:n[{numberCount}]";
                    sqlDescribe = $"{sqlDescribe}2";
                    numberCount++;
                }
                else
                {
                    sqlInto = $"{sqlInto}:s[{stringCount}]";
                    sqlDescribe = $"{sqlDescribe}1";
                    stringCount++;
                }
            }

            return new { SqlDescribe = sqlDescribe, SqlInto = sqlInto };
        }

        public IEnumerable<ReturnColumnSchema> ReturnColumnSchema(DocItem item)
        {
            IEnumerable<KeyValuePair<string, string>> parameters;
            IEnumerable<ReturnColumnSchema> returnColumns;

            if (item.ItemType == (int)DataItemType.SqlStatement)
            {
                parameters = DeriveParameters(item.Sql, out var sql);
                returnColumns = _sqlHelper.DeriveReturnColumnsSchema(sql, parameters.ToDictionary(_ => _.Key, _ => (object)_.Value)).ToArray();
            }
            else
            {
                parameters = _sqlHelper.DeriveParameters(item.Sql).Select(_ => new KeyValuePair<string, string>(_.Key, _.Value.ToString()));
                returnColumns = _sqlHelper.DeriveReturnColumnsSchema(item.Sql, parameters.ToDictionary(_ => _.Key, _ => (object)_.Value), true).ToArray();
            }

            return returnColumns;
        }

        public bool InvalidFormatCaseIdForCaseValidation(DocItem item)
        {
            if (item != null && item.ItemType == (int)DataItemType.SqlStatement)
            {
                return !item.Sql.Contains(CaseIdFormat);
            }

            return false;
        }

        static IEnumerable<KeyValuePair<string, string>> DeriveParameters(string sql, out string returnSql)
        {
            var matchCollection = Regex.Matches(sql, @":\w+");
            var matches = matchCollection.Cast<Match>().Select(m => m.Value).Distinct();

            var parameters = new List<KeyValuePair<string, string>>();
            foreach (var param in matches)
            {
                var replaceParam = param.Replace(":", "@");

                parameters.Add(new KeyValuePair<string, string>(replaceParam, "nvarchar"));

                sql = sql.Replace(param, replaceParam);
            }

            returnSql = sql;
            return parameters;
        }
    }
}