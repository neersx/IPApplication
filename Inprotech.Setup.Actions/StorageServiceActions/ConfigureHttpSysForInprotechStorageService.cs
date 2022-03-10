using System;
using System.Collections.Generic;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions.StorageServiceActions
{
    public class ConfigureHttpSysForInprotechStorageService : ISetupAction
    {
        public bool ContinueOnException => false;

        public string Description => "Configure http.sys for Inprotech Storage Service";

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            if (context.UseRemoteStorageService())
            {
                eventStream.PublishInformation("This instance does not require http.sys configuration for its Inprotech Storage Service.");
                return;
            }

            var serviceUser = (string) context["ServiceUser"];

            var appSettings = ConfigurationUtility.ReadAppSettings(context.InprotechStorageServiceConfigFilePath());
            var host = appSettings["Host"];
            var port = appSettings["Port"];
            var path = appSettings["Path"];

            var url = $"http://{host}:{port}/{context.InstanceSpecificLiteral(path)}/";

            var r = HttpSysUtility.AddSingleReservation(url, serviceUser);

            if (!String.IsNullOrWhiteSpace(r.Output))
                eventStream.PublishInformation(r.Output);

            if (r.ExitCode != 0)
                throw new SetupFailedException(r.Error);
        }
    }
}