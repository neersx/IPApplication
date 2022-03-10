using System;
using System.Collections.Generic;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class UpdateReleaseVersion : ISetupAction
    {
        public string Description => "Update release version";

        public bool ContinueOnException => true;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            var inprotechAdministrationConnectionString = (string)context["InprotechAdministrationConnectionString"];
            var integrationAdministrationConnectionString = (string)context["IntegrationAdministrationConnectionString"];

            var version = (Version)context["Version"];
            var webAppsVersion = version.Major + "." + version.Minor + "." + version.Build;
            string siteControl = "Inprotech Web Apps Version";

            DatabaseUtility.UpdateInprotechVersion(inprotechAdministrationConnectionString, webAppsVersion, siteControl);
            DatabaseUtility.UpdateInprotechIntegrationVersion(integrationAdministrationConnectionString, webAppsVersion, siteControl);
        }
    }
}
