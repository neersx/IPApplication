using System;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.IO;

#pragma warning disable 612, 618 

namespace Inprotech.Infrastructure
{
    public interface ICompressionHelper
    {
        Task<string> CreateZipFile(byte[] data, string zipFileName);
        void CreateFromDirectory(string sourceDirectory, string destinationArchiveFileName);
        void UpdateZipArchiveFilterItems(string zipFullPath, string[] includeFileTypes = null, string[] includeFiles = null);
        Task AddToArchive(string archiveFileName, string file, string entryName = null);
        Task AddToArchive(string archiveFileName, Stream stream, string entryName);
        void ExtractToDirectory(string sourceFileName, string destinationDirectory, string[] excludeFileExtension = null);
    }

    public class CompressionHelper : ICompressionHelper
    {
        readonly IFileSystem _fileSystem;

        public CompressionHelper(IFileSystem fileSystem)
        {
            _fileSystem = fileSystem;
        }

        public async Task<string> CreateZipFile(byte[] data, string zipFileName)
        {
            var zipFullPath = _fileSystem.AbsolutePath(zipFileName);

            using (var file = _fileSystem.OpenWrite(zipFullPath))
            using (var s = new MemoryStream(data))
            {
                await s.CopyToAsync(file);
            }

            return zipFullPath;
        }

        public void CreateFromDirectory(string sourceDirectory, string destinationArchiveFileName)
        {
            ZipFile.CreateFromDirectory(sourceDirectory, destinationArchiveFileName);
        }

        public void UpdateZipArchiveFilterItems(string zipFullPath, string[] includeFileTypes = null, string[] includeFiles = null)
        {
            if (includeFileTypes == null && includeFiles == null)
                return;

            using (var archive = ZipFile.Open(zipFullPath, ZipArchiveMode.Update))
            {
                foreach (var entry in archive.Entries.ToList())
                {
                    if ((includeFileTypes == null || includeFileTypes.Any(_ => entry.FullName.EndsWith(_))) &&
                        (includeFiles == null || includeFiles.Any(_ => entry.FullName.EndsWith(_))))
                        continue;

                    entry.Delete();
                }
            }
        }

        [SuppressMessage("Microsoft.Usage", "CA2202:Do not dispose objects multiple times")]
        public void ExtractToDirectory(string sourceFileName, string destinationDirectory, string[] excludeFileExtension = null)
        {
            var excludes = excludeFileExtension ?? new string[0];

            using (var s = new FileStream(sourceFileName, FileMode.Open))
            using (var z = new ZipArchive(s, ZipArchiveMode.Read))
            {
                foreach (var file in z.Entries)
                {
                    var extension = Path.GetExtension(file.FullName);
                    if (excludes.Contains(extension)) continue;

                    var completeFileName = Path.Combine(destinationDirectory, file.FullName);
                    file.ExtractToFile(completeFileName, true);
                }
            }
        }

        public async Task AddToArchive(string archiveFileName, string absoluteFilePath, string entryName = null)
        {
            if (string.IsNullOrWhiteSpace(archiveFileName)) throw new ArgumentNullException("archiveFileName");
            if (string.IsNullOrWhiteSpace(absoluteFilePath)) throw new ArgumentNullException("absoluteFilePath");

            StorageHelpers.EnsureDirectoryExists(archiveFileName);
            var zipEntryName = StorageHelpers.EnsureValid(entryName ?? absoluteFilePath);

            using (var s = new FileStream(archiveFileName, FileMode.OpenOrCreate))
            using (var z = new ZipArchive(s, ZipArchiveMode.Update))
            {
                if (absoluteFilePath.EndsWith(".zip"))
                {
                    var entry = z.CreateEntry(zipEntryName);
                    using (var z1 = File.OpenRead(absoluteFilePath))
                    using (var z2 = entry.Open())
                        await z1.CopyToAsync(z2);
                }
                else
                {
                    var fileInfo = new FileInfo(absoluteFilePath);
                    z.CreateEntryFromFile(fileInfo.FullName, fileInfo.Name);
                }
            }
        }

        public async Task AddToArchive(string archiveFileName, Stream stream, string entryName)
        {
            if (string.IsNullOrWhiteSpace(archiveFileName)) throw new ArgumentNullException("archiveFileName");
            if (string.IsNullOrWhiteSpace(entryName)) throw new ArgumentNullException("entryName");
            if (stream == null) throw new ArgumentNullException("stream");

            StorageHelpers.EnsureDirectoryExists(archiveFileName);
            var zipEntryName = StorageHelpers.EnsureValid(entryName);

            using (var s = new FileStream(archiveFileName, FileMode.OpenOrCreate))
            using (var z = new ZipArchive(s, ZipArchiveMode.Update))
            {
                var entry = z.CreateEntry(zipEntryName);
                using (var z2 = entry.Open())
                    await stream.CopyToAsync(z2);
            }
        }
    }
}