using System;
using System.Collections.Generic;
using System.IO;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class UnregisterInprotechIntegrationServer : ISetupAction
    {
        public string Description => "Unregister Inprotech Integration Server";

        public bool ContinueOnException => true;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            var inprotechIntegrationServerPhysicalPath = context.InprotechIntegrationServerPhysicalPath();

            if (!Directory.Exists(inprotechIntegrationServerPhysicalPath))
                throw new SetupFailedException($"Directory does not exist or not accessible {inprotechIntegrationServerPhysicalPath}");

            var instanceName = (string)context["InstanceName"];

            if (!ServiceControllerUtility.TryCheckExists($"Inprotech.IntegrationServer${instanceName}", eventStream, out bool exists) || exists)
            {
                // If could not check for existence, still attempt to unregister anyway

                var r = ConfigurationUtility.UnRegisterService(
                                                               Path.Combine(
                                                                            inprotechIntegrationServerPhysicalPath,
                                                                            "Inprotech.IntegrationServer.exe"), instanceName);

                if (!string.IsNullOrWhiteSpace(r.Output))
                    eventStream.PublishInformation(r.Output);

                if (r.ExitCode != 0)
                    throw new SetupFailedException(r.Error);
            }
        }
    }
}