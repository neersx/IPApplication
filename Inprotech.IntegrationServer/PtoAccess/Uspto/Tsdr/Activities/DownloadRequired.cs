using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.IntegrationServer.PtoAccess.Activities;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities
{
    public class DownloadRequired
    {
        public Task<Activity> Dispatch(DataDownload[] cases)
        {
            var each = cases.Select(c =>
                Activity.Run<CaseRequired>(_ => _.Download(c))
                    .ExceptionFilter<ErrorLogger>((ex, e) => e.Log(ex, c))
                    .Failed(Activity.Run<IDownloadFailedNotification>(d => d.Notify(c)))
                    .ThenContinue());

            return Task.FromResult<Activity>(Activity.Sequence(each));
        }
    }
}