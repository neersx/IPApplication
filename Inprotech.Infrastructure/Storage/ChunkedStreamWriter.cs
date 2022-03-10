using System.IO;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.IO;

namespace Inprotech.Infrastructure.Storage
{
    public interface IChunkedStreamWriter
    {
        Task Write(string path, Stream input);
    }

    public class ChunkedStreamWriter : IChunkedStreamWriter
    {
        readonly IFileSystem _fileSystem;

        public ChunkedStreamWriter(IFileSystem fileSystem)
        {
            _fileSystem = fileSystem;
        }

        public async Task Write(string path, Stream input)
        {
            if (!Path.IsPathRooted(path))
                path = _fileSystem.AbsolutePath(path);

            StorageHelpers.EnsureDirectoryExists(path);
            
            using var output = _fileSystem.OpenWrite(path);
            await input.CopyToAsync(output);
        }
    }
}
