using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;

namespace Inprotech.Infrastructure
{
    public interface IFileHelpers
    {
        bool DirectoryExists(string path);
        void CreateDirectory(string path);
        string GetDirectoryName(string path);

        bool Exists(string path);
        void DeleteFile(string path);
        Stream OpenRead(string path, FileAccess fileAccess = FileAccess.Read);
        Stream OpenWrite(string path);
        void WriteAllText(string path, string content, Encoding encoding);

        string ChangeExtension(string path, string extensionToChangeTo);
        string GetFileExtension(string path);
        string PathCombine(string path1, string path2);
        string PathCombine(string path1, string path2, string path3);
        string PathCombine(string path1, string path2, string path3, string path4);
        string PathCombine(params string[] paths);
        bool IsPathRooted(string path);
        string GetPathRoot(string path);
        bool FilePathValid(string path);
        void CreateFileDirectory(string path);

        string[] GetFiles(string path, string searchPattern, SearchOption searchOption);
        FileInfoWrapper GetFileInfo(string path);
        FileInfo[] GetFileInfos(string path);
        byte[] ReadAllBytes(string path);
        void Copy(string fromPath, string toPath);

        IEnumerable<string> EnumerateDirectories(string path);
        IEnumerable<string> EnumerateDirectories(string path, string searchPattern);
        IEnumerable<string> EnumerateDirectories(string path, string searchPattern, SearchOption searchOption);
        IEnumerable<string> EnumerateFileSystemEntries(string path);
        IEnumerable<string> EnumerateFileSystemEntries(string path, string searchPattern);
        IEnumerable<string> EnumerateFileSystemEntries(string path, string searchPattern, SearchOption searchOption);
        string[] ReadAllLines(string path);
    }

    public class FileInfoWrapper
    {
        public FileInfoWrapper()
        {
        }

        public FileInfoWrapper(FileInfo fileInfo)
        {
            LastWriteTime = fileInfo.LastWriteTime;
        }

        public DateTime LastWriteTime { get; set; }
    }

    public class FileHelpers : IFileHelpers
    {
        public bool DirectoryExists(string path)
        {
            return Directory.Exists(path);
        }

        public void CreateDirectory(string path)
        {
            Directory.CreateDirectory(path);
        }

        public string GetDirectoryName(string path)
        {
            return Path.GetDirectoryName(path);
        }

        public bool Exists(string path)
        {
            return File.Exists(path);
        }

        public void DeleteFile(string path)
        {
            File.Delete(path);
        }

        public Stream OpenRead(string path, FileAccess fileAccess = FileAccess.Read)
        {
            return new FileStream(path, FileMode.Open, fileAccess);
        }

        public byte[] ReadAllBytes(string path)
        {
            return File.ReadAllBytes(path);
        }

        public void Copy(string fromPath, string toPath)
        {
            File.Copy(fromPath, toPath, true);
        }

        public Stream OpenWrite(string path)
        {
            return File.OpenWrite(path);
        }

        public void WriteAllText(string path, string content, Encoding encoding)
        {
            File.WriteAllText(path, content, encoding);
        }

        public string[] ReadAllLines(string path)
        {
            return File.ReadAllLines(path);
        }

        public string ChangeExtension(string path, string extensionToChangeTo)
        {
            return Path.ChangeExtension(path, extensionToChangeTo);
        }

        public string PathCombine(string path1, string path2)
        {
            return Path.Combine(path1, path2);
        }

        public string PathCombine(string path1, string path2, string path3)
        {
            return Path.Combine(path1, path2, path3);
        }

        public string PathCombine(string path1, string path2, string path3, string path4)
        {
            return Path.Combine(path1, path2, path3, path4);
        }

        public string PathCombine(params string[] paths)
        {
            return Path.Combine(paths);
        }

        public bool IsPathRooted(string path)
        {
            return Path.IsPathRooted(path);
        }

        public bool FilePathValid(string path)
        {
            return Regex.IsMatch(path, @"^(?:[\w]\:|\\)(?!.*\.\.)");
        }

        public void CreateFileDirectory(string path)
        {
            var directoryInfo = new FileInfo(path).Directory;
            directoryInfo?.Create();
        }

        public string GetPathRoot(string path)
        {
            return Path.GetPathRoot(path);
        }

        public string[] GetFiles(string path, string searchPattern, SearchOption searchOption)
        {
            return Directory.GetFiles(path, searchPattern, searchOption);
        }

        public FileInfoWrapper GetFileInfo(string path)
        {
            return new FileInfoWrapper(new FileInfo(path));
        }

        public FileInfo[] GetFileInfos(string path)
        {
            return new DirectoryInfo(path).GetFiles();
        }

        public string GetFileExtension(string path)
        {
            var fileInfo = new FileInfo(path);
            return fileInfo.Exists ? fileInfo.Extension.Substring(1) : Path.GetExtension(path);
        }

        public IEnumerable<string> EnumerateDirectories(string path)
        {
            return Directory.EnumerateDirectories(path);
        }

        public IEnumerable<string> EnumerateDirectories(string path, string searchPattern)
        {
            return Directory.EnumerateDirectories(path, searchPattern);
        }

        public IEnumerable<string> EnumerateDirectories(string path, string searchPattern, SearchOption searchOption)
        {
            return Directory.EnumerateDirectories(path, searchPattern, searchOption);
        }

        public IEnumerable<string> EnumerateFileSystemEntries(string path)
        {
            return Directory.EnumerateFileSystemEntries(path);
        }

        public IEnumerable<string> EnumerateFileSystemEntries(string path, string searchPattern)
        {
            return Directory.EnumerateFileSystemEntries(path, searchPattern);
        }

        public IEnumerable<string> EnumerateFileSystemEntries(string path, string searchPattern, SearchOption searchOption)
        {
            return Directory.EnumerateFileSystemEntries(path, searchPattern, searchOption);
        }
    }
}