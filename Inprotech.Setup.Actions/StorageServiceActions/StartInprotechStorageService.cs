using System;
using System.Collections.Generic;
using System.ServiceProcess;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions.StorageServiceActions
{
    public class StartInprotechStorageService : ISetupAction
    {
        public string Description => "Start Inprotech Storage Service";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            if (context.UseRemoteStorageService())
            {
                eventStream.PublishInformation("This instance does not have an Inprotech Storage Service.");
                return;
            }

            var scm = new ServiceController(string.Format("Inprotech.StorageService${0}", context["InstanceName"]));
            if (scm.Status == ServiceControllerStatus.Running)
                return;

            scm.Start();

            scm.WaitForStatus(ServiceControllerStatus.Running, TimeSpan.FromMinutes(1));
        }
    }
}