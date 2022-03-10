using System;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.BulkCaseImport
{
    public interface IBulkLoadProcessing
    {
        string CurrentDbContextUser();
        void ClearCorruptBatch(string user);
        int? AcquireBatchNumber();
        void ValidateBatchHeader(int batchNumber);
        void SubmitToEde(int batchNumber);
    }

    public class BulkLoadProcessing : IBulkLoadProcessing
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly Func<DateTime> _now;

        public BulkLoadProcessing(IDbContext dbContext, ISecurityContext securityContext, Func<DateTime> now)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _now = now;
        }

        public string CurrentDbContextUser()
        {
            using (var command = _dbContext.CreateSqlCommand("SELECT @u = USER"))
            {
                var p = command.Parameters.Add(new SqlParameter
                {
                    ParameterName = "@u",
                    Direction = ParameterDirection.Output,
                    SqlDbType = SqlDbType.NVarChar,
                    Size = 120
                });

                command.ExecuteNonQuery();
                return p.Value as string;
            }
        }

        public void ClearCorruptBatch(string user)
        {
            using (var sqlCommand = _dbContext.CreateStoredProcedureCommand("dbo.ede_ClearCorruptBatch"))
            {
                sqlCommand.Parameters.Add(new SqlParameter("@psUserName", user));
                sqlCommand.ExecuteNonQuery();
            }
        }

        public int? AcquireBatchNumber()
        {
            using (var sqlCommand = _dbContext.CreateStoredProcedureCommand("dbo.ede_AssignBatchNumber"))
            {
                var batchNumberParam = sqlCommand.Parameters.Add("@pnBatchNo", SqlDbType.Int);
                batchNumberParam.Direction = ParameterDirection.Output;

                sqlCommand.ExecuteNonQuery();

                return batchNumberParam.Value as int?;
            }
        }

        public void ValidateBatchHeader(int batchNumber)
        {
            using (var sqlCommand = _dbContext.CreateStoredProcedureCommand("dbo.ede_ValidateBatchHeader"))
            {
                sqlCommand.Parameters.Add(new SqlParameter("@pnBatchNo", batchNumber));
                sqlCommand.ExecuteNonQuery();
            }
        }

        public void SubmitToEde(int batchNumber)
        {
            using (var tcs = _dbContext.BeginTransaction())
            {
                var currentUser = CurrentDbContextUser();

                var status = _dbContext.Set<TableCode>().Single(t => t.Id == (int)ProcessRequestStatus.Processing);

                var pr = _dbContext.Set<ProcessRequest>().Add(new ProcessRequest
                                                              {
                                                                  BatchId = batchNumber,
                                                                  RequestDate = _now(),
                                                                  Context = ProcessRequestContexts.ElectronicDataExchange,
                                                                  User = currentUser,
                                                                  RequestType = "EDE Resubmit Batch",
                                                                  RequestDescription = "Resubmit EDE batch for data maping and update live data",
                                                                  Status = status
                                                              });

                _dbContext.SaveChanges();

                using (var sqlCommand = _dbContext.CreateStoredProcedureCommand("dbo.ede_AsynchMapData"))
                {
                    var sqlString = string.Format(@"exec ede_MapData 
                                                @psCulture = null, @pnProcessId = {2}, @pbReducedLocking = null, 
                                                @pnUserIdentityId = {0},
                                                @pnBatchNo = {1}",
                                                  _securityContext.User.Id, batchNumber, pr.Id);
                    sqlCommand.Parameters.Add(new SqlParameter("@pnProcessId", pr.Id));
                    sqlCommand.Parameters.Add(new SqlParameter("@psCommand", sqlString));
                    sqlCommand.ExecuteNonQuery();
                }

                tcs.Complete();
            }
        }
    }
}
