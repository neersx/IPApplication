using System;
using System.Collections.Generic;
using System.IO;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class UnregisterInprotechServer : ISetupAction
    {
        public string Description => "Unregister Inprotech Server";

        public bool ContinueOnException => true;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            var inprotechServerPhysicalPath = context.InprotechServerPhysicalPath();

            if (!Directory.Exists(inprotechServerPhysicalPath))
                throw new SetupFailedException($"Directory does not exist or not accessible {inprotechServerPhysicalPath}");

            var instanceName = (string)context["InstanceName"];
            var r = ConfigurationUtility.UnRegisterService(
                                                         Path.Combine(
                                                                      inprotechServerPhysicalPath,
                                                                      "Inprotech.Server.exe"), instanceName);

            if (!string.IsNullOrWhiteSpace(r.Output))
                eventStream.PublishInformation(r.Output);

            if (r.ExitCode != 0)
                throw new SetupFailedException(r.Error);
        }
    }
}