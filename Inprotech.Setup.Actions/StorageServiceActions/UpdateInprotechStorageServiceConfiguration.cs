using System;
using System.Collections.Generic;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions.StorageServiceActions
{
    public class UpdateInprotechStorageServiceConfiguration : ISetupAction
    {
        public string Description => "Update Inprotech Storage Service configuration";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            UpdateAppConfig(context);
            UpdateAppSettings(context);
        }

        static void UpdateAppConfig(IDictionary<string, object> context)
        {
            var integrationConnectionString = (string) context["IntegrationConnectionString"];

            var inprotechConnectionString = (string) context["InprotechConnectionString"];

            var path = context.InprotechStorageServiceConfigFilePath();

            ConfigurationUtility.UpdateConnectionString(path, "InprotechIntegration", integrationConnectionString);

            ConfigurationUtility.UpdateConnectionString(path, "Inprotech", inprotechConnectionString);
        }

        static void UpdateAppSettings(IDictionary<string, object> context)
        {
            var addOrUpdateSettings = new Dictionary<string, string>
            {
                {
                    "InstanceName",
                    (string) context["InstanceName"]
                },
                {
                    "Port",
                    (string) context["IntegrationServer.Port"]
                }
            };

            if (context.ContainsKey("IsE2EMode") && (bool) context["IsE2EMode"])
            {
                addOrUpdateSettings["e2e"] = "true";
            }

            ConfigurationUtility.AddUpdateAppSettings(context.InprotechStorageServiceConfigFilePath(), addOrUpdateSettings);
        }
    }
}