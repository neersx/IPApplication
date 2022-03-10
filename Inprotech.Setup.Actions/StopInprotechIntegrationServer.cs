using System;
using System.Collections.Generic;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class StopInprotechIntegrationServer : ISetupAction
    {
        public string Description => "Stop Inprotech Integration Server";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            var instanceName = (string)context["InstanceName"];

            var serviceName = $"Inprotech.IntegrationServer${instanceName}";

            if (!ServiceControllerUtility.TryCheckExists(serviceName, eventStream, out bool exists) || exists)
            {
                // Only stop the service if found to have been installed
                // if there was a problem preventing discovering of service installed status, it should still stop it.

                ServiceControllerUtility.Stop(serviceName, eventStream);
            }
        }
    }
}