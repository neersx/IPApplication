using System.Collections.Generic;
using System.IO;
using System.Xml;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class RemoveAppsBridgeCsrfNounceForInprotechConfiguration : ISetupAction
    {
        public string Description => "Remove Apps bridge Csrf Nounce for Inprotech configuration";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            eventStream.PublishInformation("Removing Csrf Nounce for Apps bridge for Inprotech configuration");

            var webConfigPath = Path.Combine((string)context["PhysicalPath"], "web.config");

            var doc = new XmlDocument();
            doc.Load(webConfigPath);

            ConfigurationUtility.RemoveAppSettings(doc, new []
                                                        {
                                                            "AppsBridgeCsrfNounce"
                                                        });

            doc.Save(webConfigPath);

            eventStream.PublishInformation("Removed Csrf Nounce for Apps bridge for Inprotech configuration");
        }
    }
}
