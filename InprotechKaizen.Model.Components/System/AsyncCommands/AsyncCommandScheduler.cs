using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Processing;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.System.AsyncCommands
{
    public class KnownAsyncCommands
    {
        public static string[] Whitelist =
        {
            "apps_CreatePolicingForAffectedCases",
            "apps_ReverseCaseImportBatch",
            "cs_RecalculateDerivedAttention"
        };
    }

    public class AsyncCommandScheduler : IAsyncCommandScheduler
    {
        readonly IDbContext _dbContext;

        public AsyncCommandScheduler(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task ScheduleAsync(string command, Dictionary<string, object> parameters = null)
        {
            if (string.IsNullOrWhiteSpace(command)) throw new ArgumentNullException(nameof(command));

            if (!KnownAsyncCommands.Whitelist.Contains(command)) throw new NotSupportedException($"The command {command} is not supported");
            
            var parameterString = parameters != null && parameters.Any() ? " " + string.Join(", ", parameters.Select(_ => $"{_.Key}={_.Value}")) : string.Empty;

            using (var dbCommand = _dbContext.CreateStoredProcedureCommand("ipu_ScheduleAsyncCommand"))
            {
                dbCommand.Parameters.Add(new SqlParameter("@psCommand", SqlDbType.NVarChar)
                {
                    Value = $"{command}{parameterString}"
                });

                await dbCommand.ExecuteNonQueryAsync();
            }
        }
    }
}