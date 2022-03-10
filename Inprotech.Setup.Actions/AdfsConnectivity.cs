using System;
using System.Collections.Generic;
using System.Windows.Threading;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Actions
{
    public class AdfsConnectivity : ISetupAction
    {
        public string Description => "ADFS Connectivity Check";
        public bool ContinueOnException => true;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (!AuthModeUtility.IsAuthModeEnabled(context, Constants.AuthenticationModeKeys.Adfs) || !context.ContainsKey("AdfsSettings") || !context.ContainsKey("Dispatcher"))
            {
                eventStream.PublishInformation("Not required");
                return;
            }

            AdfsSettings adfsSettings;
            var verified = false;
            var errorMessage = "Unable to verify all ADFS configurations.";

            if ((adfsSettings = context["AdfsSettings"] as AdfsSettings) == null) return;

            var dispatcher = (Dispatcher)context["Dispatcher"];
            dispatcher.Invoke(() =>
            {
                try
                {
                    var form = new AdfsConnectivityTest(adfsSettings);
                    if (form.ShowDialog() == true)
                    {
                        verified = true;
                    }
                    else
                    {
                        errorMessage += $" {form.CurrentUrlIndex - 1} of {form.TotalUrls} ReturnUrls were successfully tested.";
                    }
                }
                catch (Exception exp)
                {
                    errorMessage = exp.Message;
                }
            });

            if (!verified)
                throw new SetupFailedException(errorMessage);
        }
    }
}