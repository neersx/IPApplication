using System;
using System.Collections.Generic;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions.StorageServiceActions
{
    public class UpdateInprotechStorageServiceEndpoint : ISetupAction
    {
        public bool ContinueOnException => false;

        public string Description => "Update Inprotech Storage Service http endpoint";

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            ConfigurationUtility.UpdateAppSettings(context.InprotechStorageServiceConfigFilePath(),
                                                   new Dictionary<string, string>
                                                   {
                                                       {"Port", (string) context["IntegrationServer.Port"]}
                                                   });

            ConfigurationUtility.UpdateAppSettings(context.InprotechServerConfigFilePath(),
                                                   new Dictionary<string, string>
                                                   {
                                                       {"StorageServiceBaseUrl",  GetStorageServiceBaseUrl(context)}
                                                   });
        }

        static string GetStorageServiceBaseUrl(IDictionary<string, object> context)
        {
            if (context.TryGetValidRemoteStorageServiceUrl(out Uri remoteStorageServiceUri))
            {
                // Uses a different integration server
                return remoteStorageServiceUri.ToString().TrimEnd('/') + '/';
            }

            var appSettings = ConfigurationUtility.ReadAppSettings(context.InprotechStorageServiceConfigFilePath());

            var path = appSettings["Path"];
            var port = context["IntegrationServer.Port"];

            return $"http://localhost:{port}/{context.InstanceSpecificLiteral(path)}/";
        }
    }
}