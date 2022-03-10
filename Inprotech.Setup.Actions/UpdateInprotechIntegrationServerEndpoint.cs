using System;
using System.Collections.Generic;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class UpdateInprotechIntegrationServerEndpoint : ISetupAction
    {
        public bool ContinueOnException => false;

        public string Description => "Update Inprotech Integration Server http endpoint";

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));
            
            ConfigurationUtility.UpdateAppSettings(context.InprotechIntegrationServerConfigFilePath(),
                                                   new Dictionary<string, string>
                                                   {
                                                       {"Port", (string) context["IntegrationServer.Port"]}
                                                   });
            
            ConfigurationUtility.UpdateAppSettings(context.InprotechServerConfigFilePath(),
                                                   new Dictionary<string, string>
                                                   {
                                                       {"IntegrationServerBaseUrl",  GetIntegrationServerBaseUrl(context)}
                                                   });
        }

        static string GetIntegrationServerBaseUrl(IDictionary<string, object> context)
        {
            if (context.TryGetValidRemoteIntegrationServerUrl(out Uri remoteIntegrationServerUri))
            {
                // Uses a different integration server
                return remoteIntegrationServerUri.ToString().TrimEnd('/') + '/';
            }

            var appSettings = ConfigurationUtility.ReadAppSettings(context.InprotechIntegrationServerConfigFilePath());

            var path = appSettings["Path"];
            var port = context["IntegrationServer.Port"];

            return $"http://localhost:{port}/{context.InstanceSpecificLiteral(path)}/";
        }
    }
}