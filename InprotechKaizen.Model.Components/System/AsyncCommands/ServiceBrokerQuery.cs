using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.System.AsyncCommands
{
    public interface IServiceBrokerQuery
    {
        bool IsEnabled();
    }
    class ServiceBrokerQuery : IServiceBrokerQuery
    {
        readonly IDbContext _dbContext;

        public ServiceBrokerQuery(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }
        public bool IsEnabled()
        {
            var command = _dbContext.CreateSqlCommand("SELECT is_broker_enabled FROM sys.databases WHERE name = DB_NAME()");
            var res = command.ExecuteScalar();
            if (res is bool b)
                return b;
            return false;
        }
    }
}
