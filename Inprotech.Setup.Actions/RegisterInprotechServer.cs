using System;
using System.Collections.Generic;
using System.IO;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class RegisterInprotechServer : ISetupAction
    {
        public bool ContinueOnException => false;

        public string Description => "Register Inprotech Server";

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            var serviceUser = (string) context["ServiceUser"];
            var password = (string) context["Password"];
            var builtInServiceUser = (bool) context["IsBuiltInServiceUser"];

            var r = ConfigurationUtility.RegisterService(
                                                         Path.Combine(
                                                                      context.InprotechServerPhysicalPath(),
                                                                      "Inprotech.Server.exe"),
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