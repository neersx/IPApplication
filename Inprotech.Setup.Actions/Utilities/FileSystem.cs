using System;
using System.IO;

namespace Inprotech.Setup.Actions.Utilities
{
    public interface IFileSystem
    {
        void CopyDirectory(string sourcePath, string destinationPath, Action filesCopied = null);

        void DeleteDirectory(string path);

        int GetTotalFileCount(string path);

        string WriteTemperoryFile(string content, string extension = ".txt");

        string ReadAllText(string path);

        void WriteAllText(string path, string content);
    }

    public class FileSystem : IFileSystem
    {
        public void CopyDirectory(string sourcePath, string destinationPath, Action filesCopied = null)
        {
            if (!Directory.Exists(destinationPath))
                Directory.CreateDirectory(destinationPath);

            foreach (var file in Directory.GetFiles(sourcePath))
            {
                File.Copy(file, Path.Combine(destinationPath, Path.GetFileName(file)), true);

                filesCopied?.Invoke();
            }

            foreach (var folder in Directory.GetDirectories(sourcePath))
            {
                if (folder == null) continue;

                CopyDirectory(folder, Path.Combine(destinationPath, Path.GetFileName(folder)), filesCopied);
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

        public int GetTotalFileCount(string path)
        {
            return Directory.GetFiles(path, "*", SearchOption.AllDirectories).Length;
        }

        public string WriteTemperoryFile(string content, string extension = ".txt")
        {
            var filePath = Path.GetTempPath() + Guid.NewGuid() + extension;
            File.WriteAllText(filePath, content);
            return filePath;
        }

        public string ReadAllText(string path)
        {
            return File.ReadAllText(path);
        }

        public void WriteAllText(string path, string content)
        {
            File.WriteAllText(path, content);
        }
    }
}