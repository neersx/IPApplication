using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.PtoAccess;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.MessageQueueMonitor
{
    public interface IDequeueUsptoMessagesJob
    {
        Task<Activity> Execute(long jobExecutionId);
    }

    class DequeueUsptoMessagesJob : IPerformBackgroundJob, IDequeueUsptoMessagesJob
    {
        readonly IPrivatePairService _service;
        readonly IPersistJobState _persistJobState;
        readonly IInnographyPrivatePairSettingsValidator _innographyPrivatePairSettingsValidator;
        readonly IFileSystem _fileSystem;
        readonly IUsptoMessageFileLocationResolver _usptoMessageFileLocationResolver;
        private readonly IBackgroundProcessLogger<IDequeueUsptoMessagesJob> _logger;

        public string Type => nameof(DequeueUsptoMessagesJob);

        public DequeueUsptoMessagesJob(IPrivatePairService service, IPersistJobState persistJobState, IInnographyPrivatePairSettingsValidator innographyPrivatePairSettingsValidator, IFileSystem fileSystem, IUsptoMessageFileLocationResolver usptoMessageFileLocationResolver, IBackgroundProcessLogger<IDequeueUsptoMessagesJob> logger)
        {
            _service = service;
            _persistJobState = persistJobState;
            _innographyPrivatePairSettingsValidator = innographyPrivatePairSettingsValidator;
            _fileSystem = fileSystem;
            _usptoMessageFileLocationResolver = usptoMessageFileLocationResolver;
            _logger = logger;
        }

        public SingleActivity GetJob(long jobExecutionId, JObject jobArguments)
        {
            return Activity.Run<IDequeueUsptoMessagesJob>(b => b.Execute(jobExecutionId));
        }

        public async Task<Activity> Execute(long jobExecutionId)
        {
            var (isValid, alreadyInProgress, _) = await _innographyPrivatePairSettingsValidator.HasValidSchedule();
            if (!isValid) return DefaultActivity.NoOperation();
            if (alreadyInProgress) return await SetAlreadyInProgress(jobExecutionId);

            var messageFolderLocation = _usptoMessageFileLocationResolver.ResolveMessagePath();
            Message[] messages;
            var failedMessages = new List<Message>();
            try
            {
                do
                {
                    messages = (await _service.DequeueMessages()).ToArray();
                    if (messages.Any())
                    {
                        try
                        {
                            SaveToFile(messages, messageFolderLocation);
                        }
                        catch (Exception)
                        {
                            failedMessages.AddRange(messages);
                        }
                    }
                }
                while (messages.Any());
            }
            finally
            {
                if (failedMessages.Any())
                {
                    await PersistJobState(jobExecutionId, failedMessages: failedMessages);
                }
            }

            return Activity.Run<IStoreDequeuedMessagesFromFileJob>(b => b.Execute(jobExecutionId));
        }

        async Task<Activity> SetAlreadyInProgress(long jobExecutionId)
        {
            await PersistJobState(jobExecutionId, status: "Schedule Download already in progress. Job will resume once the inprogress schedule completes");
            return DefaultActivity.NoOperation();
        }

        async Task PersistJobState(long jobExecutionId, string status = null, List<Message> failedMessages = null)
        {
            DequeueUsptoMessagesJobStatus savedState = null;
            try
            {
                savedState = await _persistJobState.Load<DequeueUsptoMessagesJobStatus>(jobExecutionId);
            }
            catch (Exception exp)
            {
                _logger.Exception(exp);
            }
            finally
            {
                if (savedState == null)
                    savedState = new DequeueUsptoMessagesJobStatus();
            }

            if (status != null)
                savedState.Status = status;

            if (failedMessages != null)
                savedState.FailedMessages = failedMessages;

            await _persistJobState.Save(jobExecutionId, savedState);
        }

        void SaveToFile(Message[] messages, string messageFolderLocation)
        {
            _fileSystem.WriteAllText(Path.Combine(messageFolderLocation, $"{Guid.NewGuid()}.json"), JsonConvert.SerializeObject(messages));
        }
    }

    public class DequeueUsptoMessagesJobStatus
    {
        public string Status { get; set; }

        public List<Message> FailedMessages { get; set; }
    }
}