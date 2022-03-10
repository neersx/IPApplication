using System.Threading.Tasks;
using Dependable.Dispatcher;
using Inprotech.Integration.Jobs;
using Newtonsoft.Json;

namespace Inprotech.Integration.Names.Consolidations
{
    public interface IFailedConsolidatingName
    {
        void NameNotConsolidated(ExceptionContext ex, long jobExecutionId, int nameBeingConsolidated);
    }

    public class FailedConsolidatingName : IFailedConsolidatingName
    {
        readonly IPersistJobState _persistJobState;

        public FailedConsolidatingName(IPersistJobState persistJobState)
        {
            _persistJobState = persistJobState;
        }

        public void NameNotConsolidated(ExceptionContext ex, long jobExecutionId, int nameBeingConsolidated)
        {
            PersistErrorDetailsInJobState(ex, jobExecutionId, nameBeingConsolidated).Wait();
        }

        async Task PersistErrorDetailsInJobState(ExceptionContext ex, long jobExecutionId, int nameBeingConsolidated)
        {
            var status = await _persistJobState.Load<NameConsolidationStatus>(jobExecutionId);
            status.Errors[nameBeingConsolidated] = JsonConvert.SerializeObject(ex, new JsonSerializerSettings
            {
                ReferenceLoopHandling = ReferenceLoopHandling.Ignore,
                Formatting = Formatting.Indented
            });

            await _persistJobState.Save(jobExecutionId, status);
        }
    }
}