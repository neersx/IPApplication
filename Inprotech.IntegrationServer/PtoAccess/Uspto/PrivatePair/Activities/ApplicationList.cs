using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Extensibility;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public interface IApplicationList
    {
        Task<Activity> DispatchDownload(Session session);
    }

    public class ApplicationList : IApplicationList
    {
        readonly IArtifactsLocationResolver _artifactsLocationResolver;
        readonly IFileSystem _fileSystem;
        readonly IPrivatePairRuntimeEvents _runtimeEvents;

        public ApplicationList(IArtifactsLocationResolver artifactsLocationResolver, IFileSystem fileSystem, IPrivatePairRuntimeEvents runtimeEvents)
        {
            _artifactsLocationResolver = artifactsLocationResolver;
            _fileSystem = fileSystem;
            _runtimeEvents = runtimeEvents;
        }

        public async Task<Activity> DispatchDownload(Session session)
        {
            var applicationFolderLocation = _artifactsLocationResolver.Resolve(session, "applications");
            var downloadActivities = new List<Activity>();

            var applications = _fileSystem.Folders(applicationFolderLocation).Select(Path.GetFileName).ToList();

            foreach (var application in applications)
            {
                var applicationDownload = new ApplicationDownload
                {
                    CustomerNumber = session.CustomerNumber,
                    ApplicationId = application,
                    SessionId = session.Id,
                    SessionName = session.Name,
                    SessionRoot = session.Root,
                    Number = application.GetApplicationNumber()
                };

                downloadActivities.Add(Activity.Run<IApplicationDocuments>(_ => _.Download(session, applicationDownload))
                                               .ExceptionFilter<IPtoFailureLogger>((c, e) => e.LogApplicationDownloadError(c, applicationDownload))
                                               .Failed(Activity.Run<IApplicationDownloadFailed>(_ => _.SaveArtifactAndNotify(applicationDownload)))
                                               .ThenContinue());
            }

            await _runtimeEvents.TrackCaseProgress(session, applications.Count);

            return applications.Any() ? Activity.Sequence(downloadActivities).ThenContinue() : DefaultActivity.NoOperation();
        }
    }
}