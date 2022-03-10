using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using Inprotech.Contracts;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.BulkCaseImport
{
    public interface IImportServer
    {
        bool TryResetAbortedProcesses();
    }

    public class ImportServer : IImportServer
    {
        readonly IDbContext _dbContext;
        readonly ILogger<ImportServer> _logger;
        readonly IDbArtifacts _dbArtifacts;

        const string HighPrivilegeSql =
            @"
UPDATE PROCESSREQUEST 
        SET STATUSCODE = @newStatus, 
            STATUSMESSAGE = @message 
FROM PROCESSREQUEST PR 
LEFT JOIN master.dbo.SYSPROCESSES SP ON (SP.SPID = PR.SPID and SP.LOGIN_TIME = PR.LOGINTIME) 
WHERE SP.SPID IS NULL AND PR.STATUSCODE = @oldStatus";

        const string HighPrivilegeSqlAfterDb16 =
            @"
UPDATE PROCESSREQUEST 
        SET STATUSCODE = @newStatus, 
            STATUSMESSAGE = @message 
FROM PROCESSREQUEST PR 
LEFT JOIN dbo.fn_GetSysProcesses() SP ON (SP.SPID = PR.SPID and SP.LOGIN_TIME = PR.LOGINTIME) 
WHERE SP.SPID IS NULL AND PR.STATUSCODE = @oldStatus";

        const string StatusDescription = "The background job has stopped unexpectedly. Try to resubmit the batch. Please contact Administrator, if the status continues to be in ''Error''.";

        public ImportServer(IDbContext dbContext, ILogger<ImportServer> logger, IDbArtifacts dbArtifacts)
        {
            _dbContext = dbContext;
            _logger = logger;
            _dbArtifacts = dbArtifacts;
        }

        public bool TryResetAbortedProcesses()
        {
            var sql = _dbArtifacts.Exists(Functions.GetSysProcesses, SysObjects.Function) ? HighPrivilegeSqlAfterDb16 : HighPrivilegeSql;

            try
            {
                var parameters = new Dictionary<string, object>
                                 {
                                     {"@newStatus", (int) ProcessRequestStatus.Error},
                                     {"@message", StatusDescription},
                                     {"@oldStatus", (int) ProcessRequestStatus.Processing}
                                 };

                using (var command = _dbContext.CreateSqlCommand(sql, parameters))
                    command.ExecuteNonQuery();
            }
            catch (SqlException ex)
            {
                _logger.Exception(ex);
                return false;
            }

            return true;
        }
    }
}