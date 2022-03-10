using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using Inprotech.Integration.Artifacts;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.CaseSource
{
    public interface IResolveCasesForDownload
    {
        IEnumerable<int> GetCaseIds(DataDownload session, int savedQueryId, int executeAs);
    }

    public class CasesForDownloadResolver : IResolveCasesForDownload
    {
        readonly IDbContext _dbContext;

        public CasesForDownloadResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IEnumerable<int> GetCaseIds(DataDownload session, int savedQueryId, int executeAs)
        {
            var cases = new List<int>();

            using(var sqlCommand = _dbContext.CreateStoredProcedureCommand("apps_SavedQueryCases"))
            {
                sqlCommand.CommandTimeout = 0;
                sqlCommand.Parameters.AddRange(
                                               new[]
                                               {
                                                   new SqlParameter("@pnUserIdentityId", executeAs),
                                                   new SqlParameter("@pnQueryKey", savedQueryId)
                                               });
                
                using(IDataReader dr = sqlCommand.ExecuteReader())
                {
                    while(dr.Read())
                    {
                        cases.Add((int) dr["CaseKey"]);
                    }
                }
            }

            return cases;
        }
    }
}