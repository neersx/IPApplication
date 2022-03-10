using System.IO;
using System.Threading.Tasks;
using Inprotech.Contracts;

namespace Inprotech.Infrastructure.Storage
{
    public enum BufferedStringReadOption
    {
        Default,
        DeleteAfterRead
    }

    public interface IBufferedStringReader
    {
        Task<string> Read(string path, BufferedStringReadOption option = BufferedStringReadOption.Default);
    }

    public class BufferedStringReader : IBufferedStringReader
    {
        readonly IFileSystem _fileSystem;

        public BufferedStringReader(IFileSystem fileSystem)
        {
            _fileSystem = fileSystem;
        }

        public async Task<string> Read(string path, BufferedStringReadOption option = BufferedStringReadOption.Default)
        {
            if (!Path.IsPathRooted(path))
            {
                path = _fileSystem.AbsolutePath(path);
            }

            string data;
            using (var r = new StreamReader(path))
                data = await r.ReadToEndAsync();

            if (option == BufferedStringReadOption.DeleteAfterRead)
                _fileSystem.DeleteFolder(path);

            return data;
        }
    }
}