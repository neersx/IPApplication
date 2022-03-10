using System;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Search.TaskPlanner
{
    public interface ILastWorkingDayFinder
    {
        Task<DateTime> GetLastWorkingDayAsync();
    }

    public class LastWorkingDayFinder : ILastWorkingDayFinder
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        public LastWorkingDayFinder(IDbContext dbContext, Func<DateTime> now)
        {
            _dbContext = dbContext;
            _now = now;
        }
        public async Task<DateTime> GetLastWorkingDayAsync()
        {
            DateTime lastWorkingDay;
            using (var sqlCommand = _dbContext.CreateStoredProcedureCommand("dbo.ipr_GetOneAfterPrevWorkDay"))
            {
                var pdtResultDate = sqlCommand.CreateParameter();
                pdtResultDate.ParameterName = "pdtResultDate";
                pdtResultDate.SqlDbType = SqlDbType.DateTime;
                pdtResultDate.Direction = ParameterDirection.Output;

                sqlCommand.Parameters.Add(new SqlParameter("@pdtStartDate", _now()));
                sqlCommand.Parameters.Add(new SqlParameter("@pbCalledFromCentura", 0));
                sqlCommand.Parameters.Add(pdtResultDate);
                lastWorkingDay =(DateTime) await sqlCommand.ExecuteScalarAsync();
            }

            return lastWorkingDay;
        }
    }
}
