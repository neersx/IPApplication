using Dependable;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Jobs
{
    public interface IPerformBackgroundJob
    {
        string Type { get; }

        SingleActivity GetJob(long jobExecutionId, JObject jobArguments);
    }

    public interface IPerformImmediateBackgroundJob
    {
        string Type { get; }

        SingleActivity GetJob(JObject data);
    }
}
