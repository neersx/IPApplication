using System;
using System.Collections.Generic;
using System.IO;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class MoveStorageLocationContents : ISetupAction
    {
        readonly IFileSystem _fileSystem;

        public MoveStorageLocationContents(IFileSystem fileSystem)
        {
            _fileSystem = fileSystem ?? throw new ArgumentNullException(nameof(fileSystem));
        }

        public MoveStorageLocationContents() : this(new FileSystem())
        {
            
        }

        public string Description => "Move storage location contents";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (!context.ContainsKey("StorageLocation"))
                return;

            var newLocation = (string) context["StorageLocation"];
            
            var appSettings = ConfigurationUtility.ReadAppSettings(context.InprotechServerConfigFilePath());

            var oldLocation = appSettings["StorageLocation"];

            if (!Directory.Exists(oldLocation) ||
                string.Equals(PathExtensions.NormalisePath(oldLocation), PathExtensions.NormalisePath(newLocation),
                    StringComparison.InvariantCultureIgnoreCase))
                return;

            eventStream.PublishInformation($"Copy storage location files from {oldLocation} to {newLocation}");

            var totalFiles = _fileSystem.GetTotalFileCount(oldLocation);

            int filesCopied = 0, progress = 0;
            _fileSystem.CopyDirectory(oldLocation, newLocation, () =>
            {
                filesCopied ++;

                var newProgress = (filesCopied * 100) / totalFiles;

                if (newProgress - progress >= 10 || filesCopied == totalFiles)
                {
                    eventStream.PublishInformation($"({filesCopied} / {totalFiles}) files copied");
                    progress = newProgress;
                }
            });
        }
    }
}
