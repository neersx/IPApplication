using System;
using System.Collections.Generic;
using System.IO;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class RestoreBackup : ISetupAction
    {
        readonly IFileSystem _fileSystem;

        public RestoreBackup(IFileSystem fileSystem)
        {
            if (fileSystem == null) throw new ArgumentNullException(nameof(fileSystem));
            _fileSystem = fileSystem;
        }

        public RestoreBackup() : this(new FileSystem())
        {
        }

        public string Description => "Restore custom files";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            var instanceDirectory = (string) context["InstanceDirectory"];
            var backupDirectory = Path.Combine(instanceDirectory, (string) context["BackupDirectory"]);

            eventStream.PublishInformation($"Copy backup files from {backupDirectory} to {instanceDirectory}");

            _fileSystem.CopyDirectory(backupDirectory, instanceDirectory);
        }
    }
}