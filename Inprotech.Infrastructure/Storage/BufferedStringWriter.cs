using System.IO;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.IO;

namespace Inprotech.Infrastructure.Storage
{
    public interface IBufferedStringWriter
    {
        Task Write(string path, string content);
    }

    public class BufferedStringWriter : IBufferedStringWriter
    {
        readonly IFileSystem _fileSystem;

        public BufferedStringWriter(IFileSystem fileSystem)
        {
            _fileSystem = fileSystem;
        }

        public async Task Write(string path, string content)
        {
            if (!Path.IsPathRooted(path))
                path = _fileSystem.AbsolutePath(path);

            StorageHelpers.EnsureDirectoryExists(path);

            _fileSystem.DeleteFile(path);

            using (var writer = new StreamWriter(File.OpenWrite(path)))
            {
                await writer.WriteAsync(content);
            }
        }
    }
}
