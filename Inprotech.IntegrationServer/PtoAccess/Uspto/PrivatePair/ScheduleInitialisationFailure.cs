using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Schedules;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public interface IScheduleInitialisationFailure
    {
        Task SaveArtifactAndNotify(Session session);

        Task Notify(Session session);
    }

    public class ScheduleInitialisationFailure : IScheduleInitialisationFailure
    {
        readonly IArtifactsLocationResolver _artifactsLocationResolver;
        readonly IArtifactsService _artifactsService;
        readonly IGlobErrors _exceptionGlobber;
        readonly IFileSystem _fileSystem;
        readonly IScheduleRuntimeEvents _scheduleRuntimeEvents;

        public ScheduleInitialisationFailure(
            IFileSystem fileSystem,
            IScheduleRuntimeEvents scheduleRuntimeEvents,
            IArtifactsLocationResolver artifactsLocationResolver,
            IArtifactsService artefactsService,
            IGlobErrors exceptionGlobber)
        {
            _fileSystem = fileSystem;
            _scheduleRuntimeEvents = scheduleRuntimeEvents;
            _artifactsLocationResolver = artifactsLocationResolver;
            _artifactsService = artefactsService;
            _exceptionGlobber = exceptionGlobber;
        }

        public async Task SaveArtifactAndNotify(Session session)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));

            var sessionFolder = _artifactsLocationResolver.Resolve(session);
            var messageFolderLocation = _artifactsLocationResolver.Resolve(session, "messages");

            var hasRecoverableFiles = _fileSystem.Folders(sessionFolder).Any(m => m.EndsWith(messageFolderLocation))
                                      && _fileSystem.Files(messageFolderLocation, "*.json").Any();

            var downloadedMessages = hasRecoverableFiles ? _artifactsService.CreateCompressedArchive(messageFolderLocation) : null;

            var logs = JsonConvert.SerializeObject(await _exceptionGlobber.GlobFor(session));

            _scheduleRuntimeEvents.Failed(session.Id, logs, downloadedMessages);
        }

        public async Task Notify(Session session)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));

            _scheduleRuntimeEvents.Failed(
                session.Id,
                JsonConvert.SerializeObject(await _exceptionGlobber.GlobFor(session)));
        }
    }
}