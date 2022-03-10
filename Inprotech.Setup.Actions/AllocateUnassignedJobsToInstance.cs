using System.Collections.Generic;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Actions
{
    public class AllocateUnassignedJobsToInstance : ISetupAction
    {
        public string Description => "Allocate unassigned jobs to this Instance";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context.UseRemoteIntegrationServer())
            {
                eventStream.PublishInformation("This instance will not process background jobs.");
                return;
            }

            var ctx = (SetupContext) context;

            var connectionString = (string) ctx["IntegrationAdministrationConnectionString"];

            var instanceName = (string) ctx["InstanceName"];

            var rowsAffected = DatabaseUtility.UpdateJobAllocations(connectionString, null, instanceName);

            if (rowsAffected <= 0) return;

            eventStream.PublishInformation("Unallocated Jobs have been assigned to this instance.");
        }
    }
}