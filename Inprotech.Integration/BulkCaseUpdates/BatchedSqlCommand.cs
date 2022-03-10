using InprotechKaizen.Model.Persistence;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Inprotech.Integration.BulkCaseUpdates
{
    public interface IBatchedSqlCommand
    {
        Task ExecuteAsync(string sqlCommand, Dictionary<string, object> parameters);
    }

    public class BatchedSqlCommand : IBatchedSqlCommand
    {
        readonly IDbContext _dbContext;

        public BatchedSqlCommand(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task ExecuteAsync(string sqlCommand, Dictionary<string, object> parameters)
        {
            using (var command = _dbContext.CreateSqlCommand(sqlCommand, parameters))
            {
                command.CommandTimeout = 0;
                await command.ExecuteNonQueryAsync();
            }
        }
    }
}
