using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.IO;

namespace Inprotech.Web.Translation
{
    public interface IResourceFile
    {
        Task<string> ReadAsync(string filePath);

        Task WriteAsync(string filePath, string content);

        string BasePath { get; }

        IEnumerable<string> Fetch(string path, params string[] searchPatterns);
        
        bool Exists(string filePath);

        string Export(Dictionary<string, string> sources);
    }

    public class ResourceFile : IResourceFile
    {
        readonly IFileSystem _fileSystem;

        public ResourceFile(IFileSystem fileSystem)
        {
            if (fileSystem == null) throw new ArgumentNullException("fileSystem");
            _fileSystem = fileSystem;
        }

        public async Task<string> ReadAsync(string filePath)
        {
            using (var r = new StreamReader(filePath))
                return await r.ReadToEndAsync();
        }

        public async Task WriteAsync(string filePath, string content)
        {
            StorageHelpers.EnsureDirectoryExists(filePath);

            _fileSystem.DeleteFile(filePath);

            using (var writer = new StreamWriter(File.OpenWrite(filePath)))
            {
                await writer.WriteAsync(content);
            }
        }

        public string BasePath
        {
            get { return Path.GetFullPath("."); }
        }

        public IEnumerable<string> Fetch(string path, params string[] searchPatterns)
        {
            return searchPatterns.SelectMany(pattern => _fileSystem.Files(path, pattern, true));
        }
        
        public bool Exists(string filePath)
        {
            if (!Path.IsPathRooted(filePath))
                return _fileSystem.Exists(Path.Combine(BasePath, filePath));

            return _fileSystem.Exists(filePath);
        }

        public string Export(Dictionary<string, string> sources)
        {
            var path = _fileSystem.AbsolutePath(_fileSystem.UniqueDirectory(Path.Combine("mui", "work")));
            _fileSystem.EnsureFolderExists(path);

            foreach (var source in sources)
            {
                var start = source.Value;
                var zipPath = Path.Combine(path, source.Key + ".zip");

                ZipFile.CreateFromDirectory(start, zipPath, CompressionLevel.Fastest, true);
            }

            var finalPath = _fileSystem.AbsoluteUniquePath("mui", "resources.zip");
            ZipFile.CreateFromDirectory(path, finalPath);

            _fileSystem.DeleteFolder(Path.Combine("mui", "work"));
            return finalPath;
        }
    }
}