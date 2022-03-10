using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;

#pragma warning disable 1998

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Extensibility
{
    public interface IPrivatePairRuntimeEvents
    {
        Task CaseProcessed(Session session, ApplicationDownload application);
        Task TrackCaseProgress(Session session, int numberOfCases);
        Task TrackDocumentProgress(ApplicationDownload application, int documentsToInclude, AvailableDocument[] unrecoverableDocuments);
        Task EndSession(Session session);
    }

    public class PrivatePairRuntimeEvents : IPrivatePairRuntimeEvents
    {
        readonly IArtifactsLocationResolver _artifactsLocationResolver;
        readonly IArtifactsService _artifactsService;
        readonly IFileSystem _fileSystem;
        readonly IRepository _repository;
        readonly IScheduleRuntimeEvents _scheduleRuntimeEvents;

        public PrivatePairRuntimeEvents(IScheduleRuntimeEvents scheduleRuntimeEvents, IRepository repository,
                                        IArtifactsService artifactsService,
                                        IFileSystem fileSystem,
                                        IArtifactsLocationResolver artifactsLocationResolver)
        {
            _scheduleRuntimeEvents = scheduleRuntimeEvents;
            _repository = repository;
            _artifactsService = artifactsService;
            _fileSystem = fileSystem;
            _artifactsLocationResolver = artifactsLocationResolver;
        }

        public async Task CaseProcessed(Session session, ApplicationDownload application)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));
            if (application == null) throw new ArgumentNullException(nameof(application));

            var @case =
                _repository.Set<Case>()
                           .Single(
                                   c =>
                                       c.Source == DataSourceType.UsptoPrivatePair &&
                                       c.ApplicationNumber == application.Number);
            if (@case == null)
            {
                throw new Exception($"Matching UsptoPrivatePair Case with Application Number {application.Number} not found.");
            }

            var caseArtifactsLocation = _artifactsLocationResolver.Resolve(application);

            var caseArtifacts = _artifactsService.CreateCompressedArchive(caseArtifactsLocation);

            _scheduleRuntimeEvents.CaseProcessed(session.Id, @case, caseArtifacts);
        }

        public async Task TrackCaseProgress(Session session, int numberOfCases)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));
            var sessionFolder = _artifactsLocationResolver.Resolve(session);
            var messageFolderLocation = _artifactsLocationResolver.Resolve(session, "messages");

            var hasRecoverableFiles = _fileSystem.Folders(sessionFolder).Any(m => m.EndsWith(messageFolderLocation))
                                      && _fileSystem.Files(messageFolderLocation, "*.json").Any();

            var executionArtifact = hasRecoverableFiles ? _artifactsService.CreateCompressedArchive(messageFolderLocation) : null;

            _scheduleRuntimeEvents.IncludeCases(session.Id, numberOfCases, executionArtifact);
        }

        public async Task TrackDocumentProgress(ApplicationDownload application, int documentsToInclude, AvailableDocument[] unrecoverableDocuments)
        {
            if (application == null) throw new ArgumentNullException(nameof(application));
            if (unrecoverableDocuments == null) throw new ArgumentNullException(nameof(unrecoverableDocuments));

            _scheduleRuntimeEvents.IncludeDocumentsForCase(application.SessionId, documentsToInclude);

            if (unrecoverableDocuments.Any())
            {
                var unrecoverableArtefacts = unrecoverableDocuments
                                             .Select(
                                                     _ => new
                                                     {
                                                         application.CustomerNumber,
                                                         ApplicationNumber = application.Number,
                                                         _
                                                     }
                                                    )
                                             .Cast<object>()
                                             .ToArray();

                _scheduleRuntimeEvents.MarkUnrecoverable(application.SessionId, unrecoverableArtefacts);
            }
        }

        public async Task EndSession(Session session)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));

            _scheduleRuntimeEvents.End(session.Id);
        }
    }
}