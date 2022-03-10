using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Integration;
using Inprotech.Integration.Innography;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess.Recovery;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public interface IMessages
    {
        Task<Activity> Retrieve(Session session);
        Task<Activity> RetrieveRecoverable(Session session);
        Task Requeue(Session session, DateTime startDate, DateTime endDate);
        Task<Activity> DispatchMessageFilesForProcessing(Session session);
        Task SortIntoApplicationBucket(Session session, int index);
    }

    public class Messages : IMessages
    {
        readonly IArtifactsLocationResolver _artifactsLocationResolver;
        readonly IArtifactsService _artifactsService;
        readonly IFileSystem _fileSystem;
        readonly IManageRecoveryInfo _recoveryInfoManager;
        readonly IScheduleRecoverableReader _scheduleRecoverableReader;
        readonly IScheduleRuntimeEvents _scheduleRuntimeEvents;
        readonly IReadScheduleSettings _scheduleSettingsReader;
        readonly IPrivatePairService _service;
        readonly ISponsorshipHealthCheck _sponsorshipHealthCheck;
        readonly IUpdateArtifactMessageIndex _updateArtifact;
        readonly IRequeueMessageDates _requeueMessageDates;
        readonly IRepository _repository;
        const int RetrieveBatchSize = 1000;

        public Messages(IFileSystem fileSystem,
                        IArtifactsLocationResolver artifactsLocationResolver,
                        IArtifactsService artifactsService,
                        IReadScheduleSettings scheduleSettingsReader,
                        IManageRecoveryInfo recoveryInfoManager,
                        IScheduleRecoverableReader scheduleRecoverableReader,
                        IScheduleRuntimeEvents scheduleRuntimeEvents,
                        ISponsorshipHealthCheck sponsorshipHealthCheck,
                        IPrivatePairService service, IUpdateArtifactMessageIndex updateArtifact, IRequeueMessageDates requeueMessageDates, IRepository repository)
        {
            _artifactsLocationResolver = artifactsLocationResolver;
            _artifactsService = artifactsService;
            _scheduleSettingsReader = scheduleSettingsReader;
            _recoveryInfoManager = recoveryInfoManager;
            _scheduleRecoverableReader = scheduleRecoverableReader;
            _scheduleRuntimeEvents = scheduleRuntimeEvents;
            _fileSystem = fileSystem;
            _service = service;
            _updateArtifact = updateArtifact;
            _requeueMessageDates = requeueMessageDates;
            _repository = repository;
            _sponsorshipHealthCheck = sponsorshipHealthCheck;
        }

        public async Task<Activity> RetrieveRecoverable(Session session)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));

            var settingsId = _scheduleSettingsReader.GetTempStorageId(session.ScheduleId);
            var recoveryInfo = _recoveryInfoManager.GetIds(settingsId).Single();

            var recoverable = _scheduleRecoverableReader.GetRecoverable(DataSourceType.UsptoPrivatePair, recoveryInfo.ScheduleRecoverableIds).ToArray();

            var messageFolderLocation = _artifactsLocationResolver.Resolve(session, "messages");
            var applicationsFolderLocation = _artifactsLocationResolver.Resolve(session, "applications");
            var excludeLogExtension = new[] { ".log" };

            foreach (var recoverableScheduleExecution in recoverable)
            {
                if (recoverableScheduleExecution.ArtifactId.HasValue)
                {
                    var applicationId = recoverableScheduleExecution.ApplicationNumber.SanitizeApplicationNumber();
                    var applicationIdFolder = Path.Combine(applicationsFolderLocation, applicationId);
                    _fileSystem.EnsureFolderExists(applicationIdFolder);
                    _fileSystem.EnsureFolderExists(Path.Combine(applicationIdFolder, "Files"));
                    _fileSystem.EnsureFolderExists(Path.Combine(applicationIdFolder, "Logs"));

                    await _artifactsService.ExtractIntoDirectory(recoverableScheduleExecution.Artifact, applicationIdFolder, excludeLogExtension);
                }
                else
                {
                    _fileSystem.EnsureFolderExists(messageFolderLocation);
                    var existingFiles = _fileSystem.Files(messageFolderLocation, "*.json");
                    if (existingFiles.Any())
                    {
                        var zipFile = await _updateArtifact.Update(recoverableScheduleExecution.Artifact, recoverableScheduleExecution.Id.ToString(), messageFolderLocation);
                        _artifactsService.ExtractIntoDirectory(zipFile, messageFolderLocation, excludeLogExtension);
                        continue;
                    }

                    await _artifactsService.ExtractIntoDirectory(recoverableScheduleExecution.Artifact, messageFolderLocation, excludeLogExtension);
                }
            }

            var requeueActivities = new List<Activity>();
            var sortedDates = _requeueMessageDates.GetDateRanges(session);

            foreach (var dateCombination in sortedDates)
            {
                requeueActivities.Add(Activity.Run<IMessages>(_ => _.Requeue(session, dateCombination.startDate, dateCombination.endDate)));
            }

            return Activity.Sequence(requeueActivities);
        }

        public async Task Requeue(Session session, DateTime startDate, DateTime endDate)
        {
            await _service.RequeueMessages(startDate, endDate);
        }

        public async Task<Activity> Retrieve(Session session)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));

            var path = _artifactsLocationResolver.Resolve(session);
            var messagePath = Path.Combine(path, "messages");
            _fileSystem.EnsureFolderExists(messagePath);

            var processId = await _scheduleSettingsReader.GetProcessId(session.ScheduleId);
            var skip = 0;
            var messages = new MessageStore[0];
            do
            {
                try
                {
                    messages = await _repository.Set<MessageStore>().Where(_ => _.ProcessId == processId)
                                                .OrderBy(_ => _.Id)
                                                .Skip(skip)
                                                .Take(RetrieveBatchSize)
                                                .ToArrayAsync();
                    if (!messages.Any()) break;

                    skip += RetrieveBatchSize;
                    var existingFileNames = _fileSystem.Files(messagePath, "*.json").Select(f => int.TryParse(Path.GetFileNameWithoutExtension(f), out var index) ? index : 0).ToArray();
                    var fileName = Path.Combine(messagePath, (existingFileNames.Any() ? existingFileNames.Max(n => n) + 1 : 0).ToString());

                    _fileSystem.WriteAllText(fileName + ".json", JsonConvert.SerializeObject(messages.Select(_ => JsonConvert.DeserializeObject<Message>(_.MessageData))));
                }
                catch (InnographyIntegrationException)
                {
                    if (!_fileSystem.Files(messagePath, "*.json").Any())
                    {
                        throw;
                    }
                }
                catch (PrivatePairServiceException e)
                {
                    _scheduleRuntimeEvents.MarkUnrecoverable(session.Id, e.Data["ServiceResponseData"]);

                    if (!_fileSystem.Files(messagePath, "*.json").Any())
                    {
                        throw;
                    }
                }
            }
            while (messages.Any());

            var dispatchMessageFilesForProcessing = Activity.Run<IMessages>(_ => _.DispatchMessageFilesForProcessing(session));

            var dispatchApplicationDownloads = Activity.Run<IApplicationList>(_ => _.DispatchDownload(session));

            return Activity.Sequence(dispatchMessageFilesForProcessing, dispatchApplicationDownloads)
                           .AnyFailed(Activity.Run<IScheduleInitialisationFailure>(s => s.SaveArtifactAndNotify(session)));
        }

        public Task<Activity> DispatchMessageFilesForProcessing(Session session)
        {
            var sortDispatcherActivities = new List<Activity>();
            var sessionFolder = _artifactsLocationResolver.Resolve(session);
            var messageFolder = Path.Combine(sessionFolder, "messages");

            _fileSystem.EnsureFolderExists(Path.Combine(sessionFolder, "applications"));
            foreach (var file in _fileSystem.Files(messageFolder, "*.json"))
            {
                var fileName = Path.GetFileNameWithoutExtension(file);
                if (int.TryParse(fileName, out var number))
                {
                    sortDispatcherActivities.Add(Activity.Run<IMessages>(_ => _.SortIntoApplicationBucket(session, number)));
                }
            }

            return Task.FromResult<Activity>(Activity.Sequence(sortDispatcherActivities));
        }

        public async Task SortIntoApplicationBucket(Session session, int index)
        {
            var sessionFolder = _artifactsLocationResolver.Resolve(session);
            var messagesFile = $"{index}.json";
            var messages = ReadFromFile(Path.Combine(sessionFolder, "messages"), messagesFile).ToList();

            foreach (var m in messages)
            {
                if (m.Meta == null || !_service.IsServiceRegistered(m.Meta.ServiceId))
                {
                    continue;
                }

                _sponsorshipHealthCheck.CheckErrors(m);
                var linkInfo = m.Links.For("pdf");
                if (linkInfo == null)
                {
                    continue;
                }

                var documentUrl = new Uri(linkInfo.Link);
                var documentName = Path.GetFileName(documentUrl.LocalPath);

                var appMessagesStorageLocation = _artifactsLocationResolver.Resolve(new ApplicationDownload
                {
                    CustomerNumber = session.CustomerNumber,
                    ApplicationId = m.ApplicationId(),
                    SessionId = session.Id,
                    SessionName = session.Name,
                    SessionRoot = session.Root
                }, $"{documentName}.json");

                _fileSystem.WriteAllText(appMessagesStorageLocation, JsonConvert.SerializeObject(m));
            }

            await _sponsorshipHealthCheck.SetSponsorshipStatus();
        }

        [SuppressMessage("Microsoft.Usage", "CA2202:Do not dispose objects multiple times")]
        IEnumerable<Message> ReadFromFile(string sessionFolder, string fileName)
        {
            string content;
            var filePath = Path.Combine(sessionFolder, fileName);
            if (!_fileSystem.Exists(filePath))
            {
                return Enumerable.Empty<Message>();
            }

            using (var stream = _fileSystem.OpenRead(filePath))
            using (var reader = new StreamReader(stream))
            {
                content = reader.ReadToEnd();
            }

            return JsonConvert.DeserializeObject<IEnumerable<Message>>(content);
        }
    }
}