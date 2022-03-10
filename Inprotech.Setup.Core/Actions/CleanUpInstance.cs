using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Core.Actions
{
    public class CleanUpInstance : ISetupActionAsync
    {
        readonly IFileSystem _fileSystem;
        readonly IInprotechServerPersistingConfigManager _manager;

        public CleanUpInstance(IFileSystem fileSystem, IInprotechServerPersistingConfigManager manager)
        {
            _manager = manager;
            _fileSystem = fileSystem;
        }

        public int MaxRetries { get; set; } = 2;

        public string Description => "Clean up instance";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            RunAsync(context, eventStream).Wait();
        }

        public async Task RunAsync(IDictionary<string, object> context, IEventStream eventStream)
        {
            var ctx = (SetupContext)context;

            var connectionString = (string)ctx["InprotechConnectionString"];

            var instanceName = Helpers.GetInstanceName(ctx.InstancePath);

            var exceeded = 0;

            do
            {
                try
                {
                    _fileSystem.DeleteAllExcept(ctx.InstancePath, Constants.SettingsFileName);

                    _fileSystem.DeleteDirectory(ctx.InstancePath);

                    break;
                }
                catch (Exception) when (exceeded++ < MaxRetries)
                {
                    eventStream.PublishInformation($"Attempting to clean up #{exceeded}.");

                    Thread.Sleep(TimeSpan.FromSeconds(2));
                }
            }
            while (true);

            var instanceDetails = await _manager.GetPersistedInstanceDetails(connectionString);

            if (instanceDetails.RemoveInstance(instanceName))
            {
                await _manager.SetPersistedInstanceDetails(connectionString, instanceDetails);

                eventStream.PublishInformation($"{instanceName} details cleared.");
            }
        }
    }
}