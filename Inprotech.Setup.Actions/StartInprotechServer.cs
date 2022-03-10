using System;
using System.Collections.Generic;
using System.ServiceProcess;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class StartInprotechServer : ISetupAction
    {
        public string Description => "Start Inprotech Server";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            var scm = new ServiceController($"Inprotech.Server${context["InstanceName"]}");
            if (scm.Status == ServiceControllerStatus.Running)
                return;

            scm.Start();

            scm.WaitForStatus(ServiceControllerStatus.Running, TimeSpan.FromMinutes(1));
        }
    }
}