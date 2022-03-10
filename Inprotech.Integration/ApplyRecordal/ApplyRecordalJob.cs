using Dependable;
using Inprotech.Integration.Jobs;
using Newtonsoft.Json.Linq;
using System.Threading.Tasks;

namespace Inprotech.Integration.ApplyRecordal
{
    public class ApplyRecordalJob : IPerformImmediateBackgroundJob
    {
        public string Type => nameof(ApplyRecordalJob);

        public SingleActivity GetJob(JObject jobArguments)
        {
            var args = jobArguments.ToObject<ApplyRecordalArgs>();
            return Activity.Run<ApplyRecordalJob>(_ => _.Execute(args));
        }

        public Task<Activity> Execute(ApplyRecordalArgs args)
        {

            var run = Activity.Run<ApplyRecordal>(_ => _.Run(args));
            var addBackgroundProcess = Activity.Run<ApplyRecordal>(_ => _.AddBackgroundProcess(args));

            return Task.FromResult(Activity.Sequence(run, addBackgroundProcess)
                                           .ExceptionFilter<ApplyRecordal>((exception, c) => c.HandleException(exception, args))
                                           .ThenContinue());
        }
    }
}
