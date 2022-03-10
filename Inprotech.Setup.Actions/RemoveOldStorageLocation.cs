using System;
using System.Collections.Generic;
using System.IO;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class RemoveOldStorageLocation : ISetupAction
    {
        readonly IFileSystem _fileSystem;

        public RemoveOldStorageLocation(IFileSystem fileSystem)
        {
            if (fileSystem == null) throw new ArgumentNullException(nameof(fileSystem));
            _fileSystem = fileSystem;
        }

        public RemoveOldStorageLocation() : this(new FileSystem())
        {
            
        }

        public string Description => "Remove old storage location";

        public bool ContinueOnException => true;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (!context.ContainsKey("StorageLocation"))
                return;

            var newLocation = (string)context["StorageLocation"];
            
            var appSettings = ConfigurationUtility.ReadAppSettings(context.InprotechServerConfigFilePath());

            var oldLocation = appSettings["StorageLocation"];

            if (!Directory.Exists(oldLocation) ||
                string.Equals(PathExtensions.NormalisePath(oldLocation), PathExtensions.NormalisePath(newLocation),
                    StringComparison.InvariantCultureIgnoreCase))
                return;

            eventStream.PublishInformation($"Remove old storage location {oldLocation}");

            try
            {
                _fileSystem.DeleteDirectory(oldLocation);
            }
            catch
            {
                eventStream.PublishWarning("Unable to remove old storage location, it will have to be removed manually.");
            }
        }
    }
}
