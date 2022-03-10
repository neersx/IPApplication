using System;
using System.Collections.Generic;
using System.IO;
using Inprotech.Contracts;

namespace Inprotech.Infrastructure.IO
{
    public class FileSystem : IFileSystem
    {
        static readonly string DirectorySeparator = Path.DirectorySeparatorChar.ToString();

        readonly IStorageLocation _storageLocation;
        readonly Func<Guid> _uniqueGenerator;

        public FileSystem(IStorageLocation storageLocation, Func<Guid> uniqueGenerator)
        {
            if (storageLocation == null) throw new ArgumentNullException("storageLocation");
            if (uniqueGenerator == null) throw new ArgumentNullException("uniqueGenerator");
            _storageLocation = storageLocation;
            _uniqueGenerator = uniqueGenerator;
        }

        public string UniqueDirectory(string path = "")
        {
            return Path.Combine(path, _uniqueGenerator().ToString());
        }

        public DateTime CreatedDate(string path)
        {
            return File.GetCreationTime(path);
        }

        public string AbsolutePath(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentException("A valid path is required.");
            if (Path.IsPathRooted(path)) throw new InvalidOperationException("Path must be a relative path.");

            return Path.Combine(_storageLocation.Resolve(), path);
        }

        public string AbsoluteUniquePath(string folderPath, string fileName)
        {
            if (string.IsNullOrWhiteSpace(folderPath)) throw new ArgumentNullException("folderPath");
            if (string.IsNullOrWhiteSpace(fileName)) throw new ArgumentNullException("fileName");

            var path = AbsolutePath(Path.Combine(UniqueDirectory(folderPath), fileName));
            StorageHelpers.EnsureDirectoryExists(path);

            return path;
        }

        public string RelativeStorageLocationPath(string absolutePath)
        {
            if (string.IsNullOrWhiteSpace(absolutePath)) throw new ArgumentNullException("absolutePath");
            if (!Path.IsPathRooted(absolutePath)) throw new InvalidOperationException("Path must be an absolute path.");

            var storageLocation = _storageLocation.Resolve();

            if (!absolutePath.StartsWith(storageLocation)) throw new InvalidOperationException("Path must start with storage location");

            var path = absolutePath.Substring(storageLocation.Length);
            while (path.StartsWith(DirectorySeparator)) path = path.Substring(1);

            return path;
        }

        public IEnumerable<string> Files(string path, string searchPattern = "", bool recurse = false)
        {
            var filePath = Path.IsPathRooted(path) ? path : AbsolutePath(path);
            var searchOption = recurse ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly;

            return Directory.EnumerateFiles(filePath, searchPattern, searchOption);
        }

        public IEnumerable<string> Folders(string path, string searchPattern = "*", bool recurse = false)
        {
            var absolutePath = Path.IsPathRooted(path) ? path : AbsolutePath(path);
            var searchOption = recurse ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly;

            return Directory.EnumerateDirectories(absolutePath, searchPattern, searchOption);
        }

        public bool Exists(string filePath)
        {
            if (string.IsNullOrWhiteSpace(filePath)) throw new ArgumentNullException("filePath");

            if (Path.IsPathRooted(filePath))
            {
                return File.Exists(filePath);
            }

            return File.Exists(AbsolutePath(filePath));
        }

        public bool FolderExists(string folderPath)
        {
            if (string.IsNullOrWhiteSpace(folderPath)) throw new ArgumentNullException("folderPath");

            return Directory.Exists(folderPath);
        }

        public Stream OpenRead(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentNullException("path");

            return File.OpenRead(Path.IsPathRooted(path) ? path : AbsolutePath(path));
        }

        public Stream OpenWrite(string path, bool ensureDirectoryExists = false)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentNullException("path");

            var absolutePath = Path.IsPathRooted(path) ? path : AbsolutePath(path);

            if (ensureDirectoryExists) StorageHelpers.EnsureDirectoryExists(absolutePath);

            return File.OpenWrite(absolutePath);
        }

        public Stream CreateFileStream(string path, FileMode mode, FileAccess access)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentNullException("path");

            var destinationFilePath = Path.IsPathRooted(path) 
                ? path
                : AbsolutePath(path);

            return new FileStream(path, mode, access);
        }

        public long GetLength(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentNullException("path");

            return new FileInfo(Path.IsPathRooted(path) ? path : AbsolutePath(path)).Length;
        }

        public byte[] ReadAllBytes(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentNullException("path");

            return File.ReadAllBytes(Path.IsPathRooted(path) ? path : AbsolutePath(path));
        }

        public string ReadAllText(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentNullException("path");

            return File.ReadAllText(Path.IsPathRooted(path) ? path : AbsolutePath(path));
        }

        public void WriteAllText(string path, string text)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentNullException("path");

            var p = Path.IsPathRooted(path) ? path : AbsolutePath(path);

            EnsureFolderExists(p);

            File.WriteAllText(p, text);
        }

        public void EnsureFolderExists(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentNullException("path");

            var p = Path.IsPathRooted(path) ? path : AbsolutePath(path);
            StorageHelpers.EnsureDirectoryExists(p);
        }

        public bool DeleteFile(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentNullException("path");

            var p = Path.IsPathRooted(path) ? path : AbsolutePath(path);

            if (!Exists(p)) return false;

            File.Delete(p);
            return true;
        }

        public void DeleteFolder(string path, bool recurse = true)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentNullException("path");

            var p = Path.IsPathRooted(path) ? path : AbsolutePath(path);

            var dirName = Path.HasExtension(p) ? Path.GetDirectoryName(p) : p;

            var directoryInfo = new DirectoryInfo(dirName);
            directoryInfo.Delete(recurse);
        }
        
        public string GetFileName(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentNullException("path");

            return Path.IsPathRooted(path) ? Path.GetFileName(path) : path;
        }
    }
}