using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration.Artifacts;

namespace Inprotech.IntegrationServer.PtoAccess.Activities
{
    public interface IChunckedDownloadRequests
    {
        /// <summary>
        ///     Dispatches download requests in chunks to workaround a
        ///     StackOverflow exception from the Dependable runtime where job lot is too large.
        /// </summary>
        IEnumerable<Activity> Dispatch(List<DataDownload> requiredApplications, int size, Func<DataDownload[], Activity> createDownloadActivity);

        Task<IEnumerable<Activity>> DispatchAsync(List<DataDownload> requiredApplications, int size, Func<DataDownload[], Task<Activity>> createDownloadActivity);
    }

    public class ChunckedDownloadRequests : IChunckedDownloadRequests
    {
        public IEnumerable<Activity> Dispatch(List<DataDownload> requiredApplications, int size, Func<DataDownload[], Activity> createDownloadActivity)
        {
            if (requiredApplications == null) throw new ArgumentNullException(nameof(requiredApplications));
            if (createDownloadActivity == null) throw new ArgumentNullException(nameof(createDownloadActivity));

            var currentChunk = requiredApplications.Take(size).ToArray();
            while (currentChunk.Any())
            {
                requiredApplications = requiredApplications.Except(currentChunk).ToList();

                yield return createDownloadActivity(currentChunk);

                currentChunk = requiredApplications.Take(size).ToArray();
            }
        }

        public async Task<IEnumerable<Activity>> DispatchAsync(List<DataDownload> requiredApplications, int size, Func<DataDownload[], Task<Activity>> createDownloadActivity)
        {
            if (requiredApplications == null) throw new ArgumentNullException(nameof(requiredApplications));
            if (createDownloadActivity == null) throw new ArgumentNullException(nameof(createDownloadActivity));

            var created = new List<Activity>();

            var currentChunk = requiredApplications.Take(size).ToArray();
            while (currentChunk.Any())
            {
                requiredApplications = requiredApplications.Except(currentChunk).ToList();

                created.Add(await createDownloadActivity(currentChunk));

                currentChunk = requiredApplications.Take(size).ToArray();
            }

            return created;
        }
    }
}