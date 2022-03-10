using System.IO;
using System.Text.RegularExpressions;

namespace Inprotech.Infrastructure.IO
{
    public static class StorageHelpers
    {
        public static void EnsureDirectoryExists(string path)
        {
            var dirName = Path.HasExtension(path) ? Path.GetDirectoryName(path) : path;
            if (string.IsNullOrEmpty(dirName))
                return;
            if (!Directory.Exists(dirName))
                Directory.CreateDirectory(dirName);
        }

        public static string EnsureValid(string input)
        {
            var regexSearch = new string(Path.GetInvalidFileNameChars()) + new string(Path.GetInvalidPathChars());
            var r = new Regex(string.Format("[{0}]", Regex.Escape(regexSearch)));
            return r.Replace(input, string.Empty);
        }
    }
}