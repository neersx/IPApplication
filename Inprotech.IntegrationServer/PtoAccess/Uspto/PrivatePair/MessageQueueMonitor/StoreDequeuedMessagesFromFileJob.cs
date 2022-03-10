
using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Infrastructure.DependencyInjection;
using Inprotech.Integration;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.PtoAccess;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Schedules.Extensions;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess.Recovery;
using InprotechKaizen.Model.Components.Security;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.MessageQueueMonitor
{
    public interface IStoreDequeuedMessagesFromFileJob
    {
        Task<Activity> Execute(long jobExecutionId);
        Task DeleteFile(string path);
    }

    class StoreDequeuedMessagesFromFileJob : IStoreDequeuedMessagesFromFileJob
    {
        readonly ILifetimeScope _lifetimeScope;
        readonly IPersistJobState _persistJobState;
        readonly IInnographyPrivatePairSettingsValidator _innographyPrivatePairSettingsValidator;
        readonly Func<DateTime> _systemClock;
        readonly IRepository _repository;
        readonly ISecurityContext _securityContext;
        readonly IReadScheduleSettings _scheduleSettings;
        readonly IFileSystem _fileSystem;
        readonly IUsptoMessageFileLocationResolver _usptoMessageFileLocationResolver;

        public StoreDequeuedMessagesFromFileJob(ILifetimeScope lifetimeScope, IPersistJobState persistJobState, IInnographyPrivatePairSettingsValidator innographyPrivatePairSettingsValidator,
                                  Func<DateTime> systemClock, IRepository repository, ISecurityContext securityContext, IReadScheduleSettings scheduleSettings, IFileSystem fileSystem, IUsptoMessageFileLocationResolver usptoMessageFileLocationResolver)
        {
            _lifetimeScope = lifetimeScope;
            _persistJobState = persistJobState;
            _innographyPrivatePairSettingsValidator = innographyPrivatePairSettingsValidator;
            _systemClock = systemClock;
            _repository = repository;
            _securityContext = securityContext;
            _scheduleSettings = scheduleSettings;
            _fileSystem = fileSystem;
            _usptoMessageFileLocationResolver = usptoMessageFileLocationResolver;
        }

        public async Task<Activity> Execute(long jobExecutionId)
        {
            var (isValid, alreadyInProgress, parentSchedule) = await _innographyPrivatePairSettingsValidator.HasValidSchedule();
            if (!isValid) return DefaultActivity.NoOperation();
            if (alreadyInProgress) return await SetAlreadyInProgress(jobExecutionId);

            var messageFolderLocation = _usptoMessageFileLocationResolver.ResolveMessagePath();
            _fileSystem.EnsureFolderExists(messageFolderLocation);
            Message[] messages;
            var deleteActivities = new List<Activity>();
            long? processId = null;

            var existingFiles = _fileSystem.Files(messageFolderLocation, "*.json")
                                           .OrderBy(_fileSystem.CreatedDate)
                                           .Select(_ => _.ToLower())
                                           .ToList();

            if (!existingFiles.Any())
                return PerformCleanupWhileFree();

            var processedFiles = await _repository.Set<MessageStoreFileQueue>().Select(_ => _.Path).ToListAsync();

            foreach (var processed in existingFiles.Intersect(processedFiles))
            {
                deleteActivities.Add(Activity.Run<IStoreDequeuedMessagesFromFileJob>(_ => _.DeleteFile(processed))
                                                         .ThenContinue());
            }

            foreach (var file in existingFiles.Except(processedFiles))
            {
                messages = JsonConvert.DeserializeObject<Message[]>(_fileSystem.ReadAllText(file));

                if (messages.Any())
                {
                    processId = processId ?? await GetNextOrValidCurrentProcessId(parentSchedule);
                    await SaveDetached(messages, processId.Value, file);
                    if (!SafeDelete(file))
                        deleteActivities.Add(Activity.Run<IStoreDequeuedMessagesFromFileJob>(_ => _.DeleteFile(file))
                                                     .ThenContinue());
                }
            }

            if (processId.HasValue)
            {
                await DispatchScheduleExecution(parentSchedule, processId.Value);
            }

            return deleteActivities.Any() ? Activity.Sequence(deleteActivities) : DefaultActivity.NoOperation();
        }

        public Task DeleteFile(string path)
        {
            if (!_fileSystem.Exists(path) || _fileSystem.DeleteFile(path))
            {
                _repository.Delete(_repository.Set<MessageStoreFileQueue>().Where(_ => _.Path == path));
                return Task.CompletedTask;
            }

            throw new Exception($"Failed to delete file: {path}");

        }

        bool SafeDelete(string path)
        {
            try
            {
                var result = _fileSystem.DeleteFile(path);
                if (result)
                    _repository.Delete(_repository.Set<MessageStoreFileQueue>().Where(_ => _.Path == path));
                return result;
            }
            catch
            {
                return false;
            }
        }

        async Task<Activity> SetAlreadyInProgress(long jobExecutionId)
        {
            await _persistJobState.Save(jobExecutionId, new
            {
                Status = $"Schedule Download already in progress. Job will resume once the inprogress schedule completes"
            });
            return DefaultActivity.NoOperation();
        }

        async Task SaveDetached(Message[] messages, long processId, string file)
        {
            var data = new List<MessageStore>();
            foreach (var m in messages.OrderBy(_ => _.Meta?.EventDateParsed))
            {
                if (m.Meta == null)
                    continue;
                var link = m.Links?.For(LinkTypes.Pdf);
                data.Add(new MessageStore()
                {
                    ServiceType = m.Meta.ServiceType,
                    ServiceId = m.Meta.ServiceId,
                    MessageTransactionId = m.Meta.TransactionId,
                    MessageText = m.Meta.Message,
                    MessageStatus = m.Meta.Status,
                    MessageTimestamp = m.Meta.EventDateParsed,
                    MessageData = JsonConvert.SerializeObject(m),
                    LinkStatus = link?.Status,
                    LinkFileName = link?.DocumentName(),
                    LinkApplicationId = m.ApplicationId(),
                    ProcessId = processId
                });
            }
            await SaveRecordsByTimestamp(data, file);
        }

        async Task<long> GetNextOrValidCurrentProcessId(Schedule parentSchedule)
        {
            long currentMax = await _repository.Set<MessageStore>().MaxAsync(_ => (long?)_.ProcessId) ?? 1;
            var lastSchedule = await GetLastUsptoSchedule(parentSchedule);
            if (lastSchedule != null && _scheduleSettings.GetProcessId(lastSchedule) == currentMax)
            {
                return ++currentMax;
            }

            return currentMax;
        }

        async Task SaveRecordsByTimestamp(List<MessageStore> messageStoreRecords, string file)
        {
            using (var scope = _lifetimeScope.BeginLifetimeScope())
            {
                var repository = scope.Resolve<IRepository>().WithUntrackedContext();

                repository.AddRange(messageStoreRecords.OrderBy(_ => _.MessageTimestamp));

                repository.Set<MessageStoreFileQueue>().Add(new MessageStoreFileQueue() { Path = file });

                await repository.SaveChangesAsync();
            }
        }

        async Task DispatchScheduleExecution(Schedule parentSchedule, long processId)
        {
            var now = _systemClock();
            var extendedSettings = _scheduleSettings.AddProcessId(parentSchedule.ExtendedSettings, processId);

            _repository.Set<Schedule>().Add(new Schedule
            {
                Name = parentSchedule.Name,
                DownloadType = parentSchedule.DownloadType,
                CreatedOn = now,
                CreatedBy = _securityContext.User.Id,
                IsDeleted = false,
                NextRun = now,
                DataSourceType = parentSchedule.DataSourceType,
                ExtendedSettings = JsonConvert.SerializeObject(extendedSettings),
                ExpiresAfter = now,
                Parent = parentSchedule,
                State = ScheduleState.RunNow,
                Type = ScheduleType.Scheduled
            });
            await _repository.SaveChangesAsync();
        }

        async Task<Schedule> GetLastUsptoSchedule(Schedule parentSchedule)
        {
            var parentSchedules = _repository.Set<Schedule>()
                                                .Where(_ => _.ParentId == null && _.Type == ScheduleType.Continuous)
                                                .SchedulesFor(DataSourceType.UsptoPrivatePair)
                                                .Select(_ => _.Id);
            return await _repository.Set<Schedule>()
                .Where(_ => _.ParentId != null && parentSchedules.Contains(_.ParentId.Value))
                .OrderByDescending(_ => _.Id)
                .FirstOrDefaultAsync();
        }

        SingleActivity PerformCleanupWhileFree()
        {
            return Activity.Run<ICleanupMessageStoreJob>(b => b.CleanupMessageStoreTable());
        }
    }
}