using System;
using System.Collections.Generic;
using System.IO;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions.StorageServiceActions
{
    public class UnRegisterInprotechStorageService : ISetupAction
    {
        public string Description => "Unregister Inprotech Storage Service";

        public bool ContinueOnException => true;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            var inprotechStorageServicePhysicalPath = context.InprotechStorageServicePhysicalPath();

            if (!Directory.Exists(inprotechStorageServicePhysicalPath))
                throw new SetupFailedException($"Directory does not exist or not accessible {inprotechStorageServicePhysicalPath}");

            var instanceName = (string) context["InstanceName"];

            if (!ServiceControllerUtility.TryCheckExists($"Inprotech.StorageService${instanceName}", eventStream, out bool exists) || exists)
            {
                // If could not check for existence, still attempt to unregister anyway

                var r = ConfigurationUtility.UnRegisterService(
                                                               Path.Combine(
                                                                            inprotechStorageServicePhysicalPath,
                                                                            "Inprotech.StorageService.exe"), instanceName);

                if (!string.IsNullOrWhiteSpace(r.Output))
                    eventStream.PublishInformation(r.Output);

                if (r.ExitCode != 0)
                    throw new SetupFailedException(r.Error);
            }
        }
    }
}