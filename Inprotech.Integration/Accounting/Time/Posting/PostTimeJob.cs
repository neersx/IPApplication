using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration.Jobs;
using InprotechKaizen.Model.Components.Accounting.Time;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Accounting.Time.Posting
{
    public class PostTimeJob : IPerformImmediateBackgroundJob
    {
        public string Type => nameof(PostTimeJob);

        public SingleActivity GetJob(JObject jobArguments)
        {
            var args = jobArguments.ToObject<PostTimeArgs>();
            return Activity.Run<PostTimeJob>(_ => _.Execute(args));
        }

        public Task<Activity> Execute(PostTimeArgs args)
        {
            SingleActivity run;
            if (args.SelectedStaffDates != null && args.SelectedStaffDates.Any())
            {
                run = Activity.Run<IPostTimeCommand>(_ => _.PostMultipleStaffInBackground(args));
            }
            else
            {
                run = Activity.Run<IPostTimeCommand>(_ => _.PostInBackground(args));
            }

            return Task.FromResult(Activity.Sequence(run)
                                           .ExceptionFilter<PostTime>((exception, c) => c.HandleException(exception, args))
                                           .ThenContinue());
        }
    }
}
