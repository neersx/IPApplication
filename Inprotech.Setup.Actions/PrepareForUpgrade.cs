using System.Collections.Generic;
using System.IO;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Actions
{
    public class PrepareForUpgrade : ISetupAction
    {
        readonly IFileSystem _fileSystem;

        public PrepareForUpgrade(IFileSystem fileSystem)
        {
            _fileSystem = fileSystem;
        }

        public string Description => "Backup custom files";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            var instanceDirectory = (string) context["InstanceDirectory"];
            var backupDirectory = Path.Combine(instanceDirectory, (string) context["BackupDirectory"]);
            
            if (_fileSystem.DirectoryExists(backupDirectory))
            {
                _fileSystem.DeleteDirectory(backupDirectory);
            }

            _fileSystem.EnsureDirectory(backupDirectory);

            foreach (var backupFile in GetCustomisations(instanceDirectory))
            {
                var source = Path.Combine(instanceDirectory, backupFile);

                if (!_fileSystem.FileExists(source)) continue;

                var destination = Path.Combine(backupDirectory, backupFile);
                var destinationDirectory = Path.GetDirectoryName(destination);

                if (destinationDirectory != null && !_fileSystem.DirectoryExists(destinationDirectory))
                {
                    _fileSystem.EnsureDirectory(destinationDirectory);
                }

                eventStream.PublishInformation($"Copy from {source} to {destination}");

                _fileSystem.CopyFile(source, destination, true);
            }
        }

        IEnumerable<string> GetCustomisations(string instancePath)
        {
            yield return Constants.Branding.CustomStylesheet;

            yield return Constants.Branding.BatchEventCustomStylesheet;

            yield return Constants.Branding.FavIcon;

            var lastSeparatorIndex = instancePath.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar).Length + 1;

            foreach (var image in _fileSystem.GetFiles(Path.Combine(instancePath, Constants.Branding.ImagesFolder))) 
                yield return image.Remove(0, lastSeparatorIndex);
        }
    }
}