using System;
using System.Collections.Generic;
using System.IO;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class RegisterInprotechIntegrationServer : ISetupAction
    {
        public string Description => "Register Inprotech Integration Server";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            if (context.UseRemoteIntegrationServer())
            {
                eventStream.PublishInformation("This instance does not require setting up of Inprotech Integration Server.");
                return;
            }

            var serviceUser = (string) context["ServiceUser"];
            var password = (string) context["Password"];
            var builtInServiceUser = (bool) context["IsBuiltInServiceUser"];

            var r = ConfigurationUtility.RegisterService(
                                                         Path.Combine(
                                                                      context.InprotechIntegrationServerPhysicalPath(),
                                                                      "Inprotech.IntegrationServer.exe"),
                                                         serviceUser,
                                                         password,
                                                         (string) context["InstanceName"],
                                                         builtInServiceUser);

            if (!string.IsNullOrWhiteSpace(r.Output))
            {
                eventStream.PublishInformation(r.Output);
            }

            if (r.ExitCode != 0)
            {
                throw new SetupFailedException(r.Error);
            }
        }
    }
}