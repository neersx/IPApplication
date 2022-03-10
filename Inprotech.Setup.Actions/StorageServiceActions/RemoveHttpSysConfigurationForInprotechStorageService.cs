using System;
using System.Collections.Generic;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions.StorageServiceActions
{
    public class RemoveHttpSysConfigurationForInprotechStorageService : ISetupAction
    {
        public string Description => "Remove http.sys configuration for Inprotech Storage Service";

        public bool ContinueOnException => true;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            var appSettings = ConfigurationUtility.ReadAppSettings(context.InprotechStorageServiceConfigFilePath());
            var host = appSettings["Host"];
            var port = appSettings["Port"];
            var path = appSettings["Path"];

            var url = $"http://{host}:{port}/{context.InstanceSpecificLiteral(path)}";

            if (!HttpSysUtility.IsUrlAclReserved(url))
            {
                eventStream.PublishInformation("http.sys configuration for Inprotech Storage Service does not exist");
                return;
            }

            var r = HttpSysUtility.RemoveSingleReservation(url);

            if (!String.IsNullOrWhiteSpace(r.Output))
                eventStream.PublishInformation(r.Output);

            if (r.ExitCode != 0)
                throw new SetupFailedException(r.Error);
        }
    }
}