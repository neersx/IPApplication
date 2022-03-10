using System;
using System.Collections.Generic;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class StopInprotechServer : ISetupAction
    {
        public string Description => "Stop Inprotech Server";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if(context == null) throw new ArgumentNullException(nameof(context));
            if(eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            var instanceName = (string)context["InstanceName"];
            ServiceControllerUtility.Stop($"Inprotech.Server${instanceName}", eventStream);
        }
    }
}