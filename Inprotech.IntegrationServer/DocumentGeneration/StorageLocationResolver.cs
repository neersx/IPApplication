using System.IO;
using Inprotech.Contracts;

namespace Inprotech.IntegrationServer.DocumentGeneration
{
    public interface IStorageLocationResolver
    {
        string UniqueDirectory(string prefix = null, string fileNameOrPath = null);
    }

    public class StorageLocationResolver : IStorageLocationResolver
    {
        readonly IFileSystem _fileSystem;

        public StorageLocationResolver(IFileSystem fileSystem)
        {
            _fileSystem = fileSystem;
        }

        public string UniqueDirectory(string prefix = null, string fileNameOrPath = null)
        {
            var path = KnownStorageLocation.DocGenRoot;

            if (prefix != null)
            {
                path = Path.Combine(path, prefix);
            }

            return _fileSystem.AbsoluteUniquePath(path, fileNameOrPath);
        }
    }

    public static class KnownStorageLocation
    {
        public const string DocGenRoot = "docgen";
    }
}
