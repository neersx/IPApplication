using System.Threading.Tasks;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Integration.Jobs;

namespace Inprotech.Integration.Search.Export
{
    public class ExportExecutionHandler : IHandleAsync<ExportExecutionJobArgs>
    {
        readonly IIntegrationServerClient _jobsServer;
        readonly IJobArgsStorage _exportJobArgsStorage;

        public ExportExecutionHandler(IIntegrationServerClient jobsServer, IJobArgsStorage exportJobArgsStorage)
        {
            _jobsServer = jobsServer;
            _exportJobArgsStorage = exportJobArgsStorage;
        }

        public async Task HandleAsync(ExportExecutionJobArgs args)
        {
            var storageId = await _exportJobArgsStorage.CreateAsync(args);

            await _jobsServer.Post("api/jobs/ExportExecutionJob/start", new { StorageId = storageId });
        }
    }
}