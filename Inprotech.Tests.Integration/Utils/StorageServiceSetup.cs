using System.IO;

namespace Inprotech.Tests.Integration.Utils
{
    public static class StorageServiceSetup
    {
        public static string _rootContentLocation;
        public static (string folder, string file) MakeAvailable(string assetResourcePath, string folderName)
        {
            _rootContentLocation = Path.Combine(Path.GetDirectoryName(typeof(Program).Assembly.Location) ?? string.Empty, "Content\\Documents");
            var folderLocation = _rootContentLocation + (string.IsNullOrWhiteSpace(folderName) ? $"" : "\\" + folderName + "\\");
            var filePath = Path.Combine(folderLocation, assetResourcePath);

            if (!Directory.Exists(folderLocation))
                Directory.CreateDirectory(folderLocation);

            File.WriteAllText(filePath, From.EmbeddedAssets(assetResourcePath));

            return (folderLocation, assetResourcePath);
        }

        public static void Delete(SearchOption searchOption = SearchOption.AllDirectories)
        {
            foreach (var file in Directory.EnumerateFiles(_rootContentLocation, "*", searchOption))
            {
                Try.Do(() => File.Delete(file));
            }
        }
    }
}