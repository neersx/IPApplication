using System;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using Inprotech.Integration.Security.Authorization;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers
{
    public class DocItemHelper
    {
        readonly IDbContext _dbContext;
        public DocItemHelper(IDbContext dbContext = null)
        {
            _dbContext = dbContext ?? new SqlDbContext();
        }

        public DataSet GetDocItemAfterRun(string docItemName, object entryPoint = null, object userId = null)
        {
            var docItem = _dbContext.Set<DocItem>().First(_ => _.Name == docItemName);
            var p = DefaultDocItemParameters.ForDocItemSqlQueries(entryPoint, userId);
            var pms = p.ToDictionary(_ => "@" + _.Key, _ => _.Value ?? DBNull.Value);
            var sql = pms.Keys.Distinct().Aggregate(docItem.Sql, (current, param) => current.Replace(param.Replace("@", ":"), param));
            var ds = new DataSet();
            using (var sqlCommand = _dbContext.CreateSqlCommand(sql, pms))
            {
                sqlCommand.CommandTimeout = 0;
                using (var adapter = new SqlDataAdapter(sqlCommand))
                {
                    adapter.Fill(ds);
                }
            }

            return ds;
        }

        public UserEmailContent GetEmailContent(string docItemName, object entryPoint)
        {
            var dataSet = GetDocItemAfterRun(docItemName, entryPoint);
            var emailContent = new UserEmailContent();
            var table = dataSet?.Tables.Count > 0 ? dataSet.Tables[0] : new DataTable();
            var dataRow = table.Rows.Count > 0 ? table.Rows[0] : table.NewRow();
            emailContent.Subject = dataRow[0].ToString();
            emailContent.Body = dataRow[1].ToString();
            emailContent.Footer = dataRow[2].ToString();

            return emailContent;
        }
    }
}
