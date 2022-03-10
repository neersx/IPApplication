using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Threading.Tasks;
using Inprotech.Contracts;

namespace Inprotech.Infrastructure
{
    public interface IArchivable
    {
        string Name { get; }

        Task Prepare(string basePath);
    }

    public interface ICompressionUtility
    {
        Task<string> CreateArchive(string file, IEnumerable<IArchivable> archivables, string context = null);

        Task AppendArchive(string archive, IEnumerable<IArchivable> archivables, string context = null);

        void CreateArchive(string file, string sourceDirectory, string context = null);
    }

    public class CompressionUtility : ICompressionUtility
    {
        const string DefaultContextFolder = "temp";

        readonly IFileSystem _fileSystem;
        readonly ICompressionHelper _compressionHelper;

        public CompressionUtility(IFileSystem fileSystem, ICompressionHelper compressionHelper)
        {
            _fileSystem = fileSystem;
            _compressionHelper = compressionHelper;
        }

        public async Task<string> CreateArchive(string file, IEnumerable<IArchivable> archivables, string context = null)
        {
            var archive = FullPath(file, context);
            
            var workPath = _fileSystem.AbsolutePath(_fileSystem.UniqueDirectory(DefaultContextFolder));

            _fileSystem.EnsureFolderExists(workPath);

            foreach (var achivable in archivables)
            {
                await achivable.Prepare(workPath);
            }

            _compressionHelper.CreateFromDirectory(workPath, archive);

            _fileSystem.DeleteFolder(workPath);

            return archive;
        }

        public async Task AppendArchive(string archive, IEnumerable<IArchivable> archivables, string context = null)
        {
            var path = _fileSystem.AbsolutePath(_fileSystem.UniqueDirectory(DefaultContextFolder));

            _fileSystem.EnsureFolderExists(path);
            
            using (var s = new FileStream(EnsureAbsolutePath(archive), FileMode.Open))
            using (var z = new ZipArchive(s, ZipArchiveMode.Update))
            {
                foreach (var i in archivables)
                {
                    await i.Prepare(path);

                    var entry = z.CreateEntry(i.Name);

                    using (var z1 = _fileSystem.OpenRead(Path.Combine(path, i.Name)))
                    using (var z2 = entry.Open())
                        await z1.CopyToAsync(z2);
                }
            }

            _fileSystem.DeleteFolder(path);
        }
        
        public void CreateArchive(string file, string sourceDirectory, string context = null)
        {
            var archive = FullPath(file, context);

            _compressionHelper.CreateFromDirectory(sourceDirectory, archive);
        }

        string FullPath(string fileName, string context = null)
        {
            var archive = Path.Combine(_fileSystem.UniqueDirectory(context ?? DefaultContextFolder), fileName);

            _fileSystem.EnsureFolderExists(archive);

            return _fileSystem.AbsolutePath(archive);
        }

        string EnsureAbsolutePath(string archive)
        {
            if (Path.IsPathRooted(archive))
                return archive;

            return _fileSystem.AbsolutePath(archive);
        }
    }
}