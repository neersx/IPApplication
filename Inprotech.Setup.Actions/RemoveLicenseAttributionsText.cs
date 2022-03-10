using System.Collections.Generic;
using System.IO;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Actions
{
    public class RemoveLicenseAttributionsText : ISetupAction
    {
        public string Description => "Remove App License Attributions.txt";
        public bool ContinueOnException => true;
        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            var ctx = (SetupContext)context;
            var iisPath = ctx.PairedIisApp.PhysicalPath;

            if(iisPath== null) return;

            var licenseAttibutionFilePath = Path.Combine(iisPath, "Desktop","Portal","ProductInfo","App License Attributions.txt");

            eventStream.PublishInformation($"Removing License Attributions file from { Path.GetDirectoryName(licenseAttibutionFilePath)}");
            if (File.Exists(licenseAttibutionFilePath))
            {
                File.Delete(licenseAttibutionFilePath);
            }
        }
    }
}
