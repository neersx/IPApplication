using System;
using System.IO;
using System.Reflection;

namespace Inprotech.Setup.Core
{
    public interface ISetupActionsAssemblyLoader
    {
        Assembly Load(string instanceRoot);
    }

    class SetupActionsAssemblyLoader : ISetupActionsAssemblyLoader
    {
        readonly IFileSystem _fileSystem;

        public SetupActionsAssemblyLoader(IFileSystem fileSystem)
        {
            _fileSystem = fileSystem;
        }

        public Assembly Load(string instanceRoot)
        {
            _fileSystem.EnsureDirectory(Constants.WorkingDirectory);

            var sourcePath = Path.Combine(instanceRoot, Constants.SetupActionsFileName);
            var targetPath = Path.Combine(Constants.WorkingDirectory, Guid.NewGuid() + ".dll");

            if (!_fileSystem.FileExists(sourcePath))
                return null;

            _fileSystem.CopyFile(sourcePath, targetPath);

            var assembly = Assembly.LoadFile(Path.GetFullPath(targetPath));

            return assembly;
        }
    }
}