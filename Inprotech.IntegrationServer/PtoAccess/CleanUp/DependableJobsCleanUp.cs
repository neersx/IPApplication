using System.Threading.Tasks;
using Dependable;
using Dependable.Extensions.Persistence.Sql;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Integration.Jobs;
using Newtonsoft.Json.Linq;

namespace Inprotech.IntegrationServer.PtoAccess.CleanUp
{
    public class DependableJobsCleanUp : IPerformBackgroundJob
    {
        readonly IAppSettingsProvider _appSettingsProvider;
        readonly IConnectionStrings _connectionStrings;

        public DependableJobsCleanUp(IConnectionStrings connectionStrings, IAppSettingsProvider appSettingsProvider)
        {
            _connectionStrings = connectionStrings;
            _appSettingsProvider = appSettingsProvider;
        }

        public string Type => "DependableJobsCleanUp";

        public SingleActivity GetJob(long jobExecutionId, JObject jobArguments)
        {
            return Activity.Run<DependableJobsCleanUp>(_ => _.Run(jobExecutionId));
        }

        public Task Run(long jobExecutionId)
        {
            return Task.Run(() => DependableJobsTable.Clean(_connectionStrings["InprotechIntegration"], _appSettingsProvider["InstanceName"]));
        }
    }
}