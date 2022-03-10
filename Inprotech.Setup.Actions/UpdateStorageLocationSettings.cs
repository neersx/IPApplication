using System.Collections.Generic;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class UpdateStorageLocationSettings : ISetupAction
    {
        public string Description => "Update storage location settings";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            eventStream.PublishInformation("Update storage location settings for inprotech server");
            UpdateConfig(context.InprotechServerConfigFilePath(), context);

            eventStream.PublishInformation("Update storage location settings for integration server");
            UpdateConfig(context.InprotechIntegrationServerConfigFilePath(), context);
        }

        static void UpdateConfig(string rootPath, IDictionary<string, object> context)
        {
            if (!context.ContainsKey("StorageLocation"))
                return;
            
            ConfigurationUtility.UpdateAppSettings(rootPath, new Dictionary<string, string>
            {
                {
                    "StorageLocation",
                    (string) context["StorageLocation"]
                }
            });
        }
    }
}