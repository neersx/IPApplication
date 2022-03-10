using System.Collections.Generic;
using System.IO;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Actions
{
    public class CopyLicenseAttributionsText : ISetupAction
    {
        public string Description => "Copy App License Attributions.txt";

        public bool ContinueOnException => true;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            var ctx = (SetupContext) context;
            var iisPath = ctx.PairedIisApp.PhysicalPath;
            if (iisPath == null) return;
            var instancePath = ctx.InstancePath;
            var licenseAttibutionFile = "App License Attributions.txt";

            var sourceFilePath = Path.Combine(instancePath, licenseAttibutionFile);
            var destFilePath = Path.Combine(iisPath, "Desktop", "Portal", "ProductInfo", licenseAttibutionFile);

            eventStream.PublishInformation($"Copying License Attributions file from {sourceFilePath} to {destFilePath}");
            File.Copy(sourceFilePath, destFilePath, true);
        }
    }
}