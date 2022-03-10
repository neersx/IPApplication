using System;
using System.Collections.Generic;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class RemoveHttpSysConfigurationForInprotechServer : ISetupAction
    {
        public string Description => "Remove http.sys configuration for Inprotech Server";

        public bool ContinueOnException => true;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));
            
            var appSettings = ConfigurationUtility.ReadAppSettings(context.InprotechServerConfigFilePath());
            var bindingUrls = appSettings["BindingUrls"].Split(',');
            var virtualPath = appSettings["ParentPath"].AsHttpSysCompatiblePath();

            HttpSysUtility.RemoveAllReservations(bindingUrls, virtualPath + "apps", eventStream);
            HttpSysUtility.RemoveAllReservations(bindingUrls, virtualPath + "i", eventStream);
            HttpSysUtility.RemoveAllReservations(bindingUrls, virtualPath + "winAuth", eventStream);
        }
    }
}