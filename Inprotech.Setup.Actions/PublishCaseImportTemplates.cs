using System;
using System.Collections.Generic;
using System.IO;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Actions
{
    public class PublishCaseImportTemplates : ISetupAction
    {
        readonly IFileSystem _fileSystem;

        public PublishCaseImportTemplates(IFileSystem fileSystem)
        {
            if (fileSystem == null) throw new ArgumentNullException(nameof(fileSystem));
            _fileSystem = fileSystem;
        }

        public PublishCaseImportTemplates() : this(new FileSystem())
        {
        }

        public string Description => "Publish Case Import Templates";

        public bool ContinueOnException => true;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (!context.ContainsKey("StorageLocation"))
                return;

            var ctx = (SetupContext) context;
            var instancePath = ctx.InstancePath;

            var sourcePath = Path.Combine(instancePath, "Inprotech.Server", "Assets", "CaseImportTemplates");

            var baseTemplatePath = Path.Combine((string)context["StorageLocation"], "bulkCaseImport-templates");

            var destPath = Path.Combine(baseTemplatePath, "standard");

            eventStream.PublishInformation($"Publishing Case Import Templates from {sourcePath} to {destPath}");

            _fileSystem.CopyDirectory(sourcePath, destPath);

            _fileSystem.EnsureDirectory(Path.Combine(baseTemplatePath, "custom"));

            eventStream.PublishInformation("Case Import Templates Published");
        }
    }
}