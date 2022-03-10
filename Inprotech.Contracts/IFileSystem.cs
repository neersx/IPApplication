using System;
using System.Collections.Generic;
using System.IO;

namespace Inprotech.Contracts
{
    public interface IFileSystem
    {
        string UniqueDirectory(string path = "");

        string AbsolutePath(string path);

        DateTime CreatedDate(string path);
        
        string AbsoluteUniquePath(string folderPath, string fileName);

        byte[] ReadAllBytes(string path);

        string ReadAllText(string path);

        void WriteAllText(string path, string text);

        IEnumerable<string> Files(string path, string searchPattern = "", bool recurse = false);

        IEnumerable<string> Folders(string path, string searchPattern = "*", bool recurse = false);

        Stream OpenRead(string path);

        Stream OpenWrite(string path, bool ensureDirectoryExists = false);

        Stream CreateFileStream(string path, FileMode mode, FileAccess access);
        
        bool Exists(string filePath);

        bool FolderExists(string folderPath);

        void EnsureFolderExists(string path);

        bool DeleteFile(string path);

        void DeleteFolder(string path, bool recurse = true);

        string RelativeStorageLocationPath(string absolutePath);
        
        long GetLength(string path);

        string GetFileName(string path);
    }
}