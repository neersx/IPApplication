using System.IO;

namespace Inprotech.Tests.Integration.Utils
{
    public static class StorageFolder
    {
        static string DefaultStorageFolderLocation => Runtime.StorageLocation;// @"c:\inprotech\storage";

        public static string MakeAvailable(string assetResourcePath, string storageName, string newFileName = null, bool overwrite = false)
        {
            var storageFolder = Path.Combine(DefaultStorageFolderLocation, storageName);

            var dest = Path.Combine(Path.Combine(storageFolder, newFileName ?? Path.GetFileName(assetResourcePath)));

            File.WriteAllText(dest, From.EmbeddedAssets(assetResourcePath));

            if (!Directory.Exists(storageFolder))
                Directory.CreateDirectory(storageFolder);

            if (!overwrite && File.Exists(dest))
                return dest;

            return dest;
        }

        public static void DeleteFrom(string storageName, SearchOption searchOption = SearchOption.AllDirectories)
        {
            var filePath = Path.Combine(DefaultStorageFolderLocation, storageName);

            foreach (var file in Directory.EnumerateFiles(filePath, "*", searchOption))
            {
                Try.Do(() => File.Delete(file));
            }
        }

        public static void DeleteFile(string relativeFilePath, SearchOption searchOption = SearchOption.AllDirectories)
        {
            var filePath = Path.Combine(DefaultStorageFolderLocation, relativeFilePath);

            FileSetup.DeleteFile(filePath);
        }
    }
}