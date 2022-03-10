using System;
using System.Collections.ObjectModel;
using System.IO;
using System.IO.Compression;
using System.Linq;
using Inprotech.Contracts;
using Inprotech.Infrastructure.IO;

namespace Inprotech.Infrastructure.Storage
{
    public interface IZipStreamHelper
    {
        ReadOnlyCollection<ZipArchiveEntry> ReadEntriesFromStream(Stream stream);

        bool ExtractIfExists(ReadOnlyCollection<ZipArchiveEntry> archive, string fileName, string path, string outFileName = null);
    }

    public class ZipStreamHelper : IZipStreamHelper
    {
        readonly IFileSystem _fileSystem;

        public ZipStreamHelper(IFileSystem fileSystem)
        {
            _fileSystem = fileSystem;
        }

        public ReadOnlyCollection<ZipArchiveEntry> ReadEntriesFromStream(Stream stream)
        {
            return new ZipArchive(stream).Entries;
        }

        public bool ExtractIfExists(ReadOnlyCollection<ZipArchiveEntry> archive, string fileName, string path, string outFileName = null)
        {
            if (archive == null) throw new ArgumentNullException("archive");

            var file = archive.SingleOrDefault(l => l.Name == fileName);
            if (file == null) return false;

            if (!Path.IsPathRooted(path))
                path = _fileSystem.AbsolutePath(path);

            StorageHelpers.EnsureDirectoryExists(path);

            file.ExtractToFile(Path.Combine(path, outFileName ?? fileName), true);
            return true;
        }
    }
}