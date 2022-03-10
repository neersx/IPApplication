using System;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;

namespace Inprotech.Integration.Schedules
{
    public enum ErrorAction
    {
        Default,
        NullIfSourcePathNotExists
    }

    public interface IArtifactsService
    {
        byte[] CreateCompressedArchive(string path, ErrorAction action = ErrorAction.Default, string[] retainMessageNames = null);
        Task<byte[]> Compress(string file);
        Task<byte[]> Compress(string name, string content);
        Task ExtractIntoDirectory(byte[] data, string destinationLocation, string[] excludeFileExtension = null);
        void ExtractIntoDirectory(string zipFullPath, string destinationLocation, string[] excludeFileExtension = null);
    }

    public class ArtifactsService : IArtifactsService
    {
        static readonly string[] RetainFileTypes =
        {
            ".json", ".xml", ".log"
        };

        readonly ICompressionHelper _compressionHelper;
        readonly IFileHelpers _fileHelpers;
        readonly IFileSystem _fileSystem;
        readonly Func<Guid> _uniqueFileNameCreator;

        public ArtifactsService(IFileSystem fileSystem, IFileHelpers fileHelpers, ICompressionHelper compressionHelper, Func<Guid> uniqueFileNameCreator)
        {
            _fileSystem = fileSystem;
            _fileHelpers = fileHelpers;
            _compressionHelper = compressionHelper;
            _uniqueFileNameCreator = uniqueFileNameCreator;
        }
        
        public byte[] CreateCompressedArchive(string path, ErrorAction action = ErrorAction.Default, string[] retainMessageNames = null)
        {
            if (string.IsNullOrEmpty(path)) throw new ArgumentNullException(nameof(path));

            if (!_fileHelpers.DirectoryExists(_fileSystem.AbsolutePath(path)) && action == ErrorAction.NullIfSourcePathNotExists)
            {
                return null;
            }

            var sourceLocation = _fileSystem.AbsolutePath(path);
            var zip = _uniqueFileNameCreator() + ".zip";
            var zipFullPath = _fileSystem.AbsolutePath(zip);

            _compressionHelper.CreateFromDirectory(sourceLocation, zipFullPath);

            _compressionHelper.UpdateZipArchiveFilterItems(zipFullPath, RetainFileTypes, retainMessageNames);

            var bytes = _fileSystem.ReadAllBytes(zipFullPath);

            _fileSystem.DeleteFile(zip);

            return bytes;
        }

        public async Task ExtractIntoDirectory(byte[] data, string destinationLocation, string[] excludeFileExtension = null)
        {
            var zip = _uniqueFileNameCreator() + ".zip";
            var zipFullPath = await _compressionHelper.CreateZipFile(data, zip);

            _compressionHelper.ExtractToDirectory(zipFullPath, _fileSystem.AbsolutePath(destinationLocation), excludeFileExtension);

            _fileSystem.DeleteFile(zip);
        }

        public void ExtractIntoDirectory(string zipFullPath, string destinationLocation, string[] excludeFileExtension = null)
        {
            _compressionHelper.ExtractToDirectory(zipFullPath, _fileSystem.AbsolutePath(destinationLocation), excludeFileExtension);

            _fileSystem.DeleteFile(Path.GetFileName(zipFullPath));
        }

        public async Task<byte[]> Compress(string file)
        {
            return await Compress(file, _fileSystem.ReadAllBytes(file));
        }

        public async Task<byte[]> Compress(string name, string content)
        {
            var data = Encoding.Default.GetBytes(content.ToCharArray());
            return await Compress(name, data);
        }

        async Task<byte[]> Compress(string name, byte[] data)
        {
            var zipPath = _fileSystem.AbsolutePath(_fileSystem.UniqueDirectory());

            var zip = Path.Combine(zipPath, "index.zip");

            await _compressionHelper.AddToArchive(zip, new MemoryStream(data), name);

            var contents = _fileSystem.ReadAllBytes(zip);

            _fileSystem.DeleteFolder(zipPath);

            return contents;
        }
    }
}