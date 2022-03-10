using System;
using System.Collections.Generic;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class ConfigureHttpSysForInprotechServer : ISetupAction
    {
        public bool ContinueOnException => false;

        public string Description => "Configure http.sys for Inprotech Server";

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if(context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            var path = ((string)context["VirtualPath"]).AsHttpSysCompatiblePath();
            var serviceUser = (string)context["ServiceUser"];
            
            HttpSysUtility.AddAllReservations(context, path + "i", serviceUser, eventStream);
            HttpSysUtility.AddAllReservations(context, path + "apps", serviceUser, eventStream);
            HttpSysUtility.AddAllReservations(context, path + "winAuth", serviceUser, eventStream);
        }
    }
}