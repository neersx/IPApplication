using System;
using System.IO;
using System.Linq;

namespace Inprotech.Setup.Core
{
    public interface IFileSystem
    {
        bool FileExists(string path);
        string ReadAllText(string path);
        void WriteAllText(string path, string text);
        void DeleteFile(string path);
        void DeleteDirectory(string path);
        void DeleteAllExcept(string root, params string[] ignoredItems);
        void EnsureDirectory(string path);
        bool DirectoryExists(string path);
        string[] GetDirectories(string path);
        string[] GetFiles(string directoryPath);
        void CopyFile(string source, string target, bool @override = false);
        void CopyDirectory(string sourceDirName, string destDirName);
        string GetFullPath(string path);
        string GetSafeFolderName(string path);
    }

    public class FileSystem : IFileSystem
    {
        public bool FileExists(string path)
        {
            return File.Exists(path);
        }

        public string ReadAllText(string path)
        {
            return File.ReadAllText(path);
        }

        public void WriteAllText(string path, string text)
        {
            File.WriteAllText(path, text);
        }

        public void DeleteFile(string path)
        {
            if (FileExists(path))
            {
                File.Delete(path);
            }
        }

        public void DeleteDirectory(string path)
        {
            var files = Directory.GetFiles(path);

            foreach (var file in files)
                File.Delete(file);

            var dirs = Directory.GetDirectories(path);

            foreach (var dir in dirs)
                DeleteDirectory(dir);

            Directory.Delete(path, true);
        }

        public void DeleteAllExcept(string root, params string[] ignoredItems)
        {
            foreach (var path in Directory.EnumerateFileSystemEntries(root))
            {
                if (ignoredItems.Any(i => string.Equals(Path.GetFileName(path), i, StringComparison.InvariantCultureIgnoreCase)))
                {
                    continue;
                }

                if (File.Exists(path))
                {
                    File.Delete(path);
                }
                else if (Directory.Exists(path))
                {
                    DeleteDirectory(path);
                }
            }
        }

        public void EnsureDirectory(string path)
        {
            if (!Directory.Exists(path))
            {
                Directory.CreateDirectory(path);
            }
        }

        public bool DirectoryExists(string path)
        {
            return Directory.Exists(path);
        }

        public string[] GetDirectories(string path)
        {
            return Directory.GetDirectories(path);
        }

        public string[] GetFiles(string directoryPath)
        {
            return Directory.GetFiles(directoryPath);
        }

        public void CopyFile(string source, string target, bool @override = false)
        {
            File.Copy(source, target, @override);
        }

        public void CopyDirectory(string sourcePath, string destinationPath)
        {
            if (!Directory.Exists(destinationPath))
            {
                Directory.CreateDirectory(destinationPath);
            }

            foreach (var file in Directory.GetFiles(sourcePath))
            {
                File.Copy(file, Path.Combine(destinationPath, Path.GetFileName(file)), true);
            }

            foreach (var folder in Directory.GetDirectories(sourcePath))
            {
                if (folder == null) continue;

                CopyDirectory(folder, Path.Combine(destinationPath, Path.GetFileName(folder)));
            }
        }

        public string GetFullPath(string path)
        {
            return Path.GetFullPath(path);
        }

        public string GetSafeFolderName(string path)
        {
            return Path.GetInvalidPathChars()
                       .Aggregate(path, (current, c) => current.Replace(c, ' '))
                       .Replace(Path.DirectorySeparatorChar, ' ')
                       .Replace(Path.AltDirectorySeparatorChar, ' ')
                       .Replace(" ", string.Empty);
        }
    }
}