using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Actions
{
    public class ReassignRunningJobAllocations : ISetupActionAsync
    {
        public string Description => "Reassign running job allocations";

        public bool ContinueOnException => true;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            Task.Run(() => RunAsync(context, eventStream));
        }

        public async Task RunAsync(IDictionary<string, object> context, IEventStream eventStream)
        {
            var ctx = (SetupContext) context;

            var inprotechServerConnString = (string) ctx["InprotechAdministrationConnectionString"];

            var integrationServerConnString = (string) ctx["IntegrationAdministrationConnectionString"];

            var instanceName = (string) ctx["InstanceName"];

            var instanceDetails = await new InprotechServerPersistingConfigManager().GetPersistedInstanceDetails(inprotechServerConnString);

            var otherInstance = instanceDetails.IntegrationServer.FirstOrDefault(_ => _.Name != instanceName);

            var rowsAffected = DatabaseUtility.UpdateJobAllocations(integrationServerConnString, instanceName, otherInstance?.Name);

            if (rowsAffected <= 0) return;

            eventStream.PublishInformation("Running jobs have been reassigned.");
        }
    }
}