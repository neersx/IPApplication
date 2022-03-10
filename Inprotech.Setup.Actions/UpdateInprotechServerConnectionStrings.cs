using System;
using System.Collections.Generic;
using System.IO;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class UpdateInprotechServerConnectionStrings : ISetupAction
    {
        public string Description => "Update Inprotech Server connection strings";
        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            var path = Path.Combine(context.InprotechServerPhysicalPath(), "Inprotech.Server.exe.config");
            if (!File.Exists(path))
                throw new SetupFailedException($"Could not find the configuration file {path}");

            ConfigurationUtility.UpdateConnectionString(path, "InprotechIntegration", (string)context["IntegrationConnectionString"]);

            ConfigurationUtility.UpdateConnectionString(path, "Inprotech", (string)context["InprotechConnectionString"]);
        }
    }
}