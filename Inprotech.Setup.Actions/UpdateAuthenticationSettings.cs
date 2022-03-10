using System.Collections.Generic;
using System.Linq;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Actions
{
    public class UpdateAuthenticationSettings : ISetupAction
    {
        public string Description => "Update authentication mode settings";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            eventStream.PublishInformation("Update authentication settings for inprotech server");

            var valuesToBeUpdated = new Dictionary<string, string>();

            if (context.ContainsKey("AuthenticationMode"))
            {
                valuesToBeUpdated.Add("AuthenticationMode", (string)context["AuthenticationMode"]);
            }
            if(context.ContainsKey("Authentication2FAMode"))
            {
                valuesToBeUpdated.Add("Authentication2FAMode", (string)context["Authentication2FAMode"]);
            }
            if (AuthModeUtility.IsAuthModeEnabled(context, Constants.AuthenticationModeKeys.Sso) && context.ContainsKey("IpPlatformSettings"))
            {
                var ipPlatformSettings = context["IpPlatformSettings"] as IpPlatformSettings;
                if (ipPlatformSettings != null)
                {
                    valuesToBeUpdated.Add(Constants.IpPlatformSettings.ClientId, ipPlatformSettings.ClientId);
                    valuesToBeUpdated.Add(Constants.IpPlatformSettings.ClientSecret, ipPlatformSettings.ClientSecret);
                }
            }

            if (!valuesToBeUpdated.Any())
                return;

            ConfigurationUtility.UpdateAppSettings(context.InprotechServerConfigFilePath(), valuesToBeUpdated);
            ConfigurationUtility.UpdateAppSettings(context.InprotechIntegrationServerConfigFilePath(), valuesToBeUpdated);
        }
    }
}