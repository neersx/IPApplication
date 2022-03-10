using System.Threading.Tasks;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Jobs.States;

namespace Inprotech.IntegrationServer.PtoAccess.DmsIntegration
{
    public interface IUpdateDmsIntegrationJobStates
    {
        Task DocumentSent(long jobExecutionId);

        Task JobStarted(long jobExecutionId, int total);
    }

    public class DmsIntegrationJobStateUpdater : IUpdateDmsIntegrationJobStates
    {
        readonly IPersistJobState _persister;

        public DmsIntegrationJobStateUpdater(IPersistJobState persister)
        {
            _persister = persister;
        }

        public async Task DocumentSent(long jobExecutionId)
        {
            var state = await _persister.Load<SendAllDocumentsForSourceState>(jobExecutionId);
            state.SentDocuments++;
            await _persister.Save(jobExecutionId, state);
        }

        public async Task JobStarted(long jobExecutionId, int total)
        {
            var state = new SendAllDocumentsForSourceState {SentDocuments = 0, TotalDocuments = total};
            await _persister.Save(jobExecutionId, state);
        }
    }
}