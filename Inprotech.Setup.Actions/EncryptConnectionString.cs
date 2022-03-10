using System.Collections.Generic;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class EncryptConnectionString : ISetupAction
    {
        public string Description => "Encrypt connection string";
        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            ConfigurationUtility.EncryptConnectionString(context.InprotechServerConfigFilePath());

            ConfigurationUtility.EncryptConnectionString(context.InprotechIntegrationServerConfigFilePath());

            ConfigurationUtility.EncryptConnectionString(context.InprotechStorageServiceConfigFilePath());
        }
    }
}
