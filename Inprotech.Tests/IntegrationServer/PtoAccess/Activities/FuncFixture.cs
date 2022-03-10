using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration.Artifacts;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Activities
{
    public interface IFuncFixture
    {
        Activity CreateDownloadActivity(DataDownload[] dataDownloads);

        Task<Activity> CreateDownloadActivityAsync(DataDownload[] dataDownloads);
    }
}