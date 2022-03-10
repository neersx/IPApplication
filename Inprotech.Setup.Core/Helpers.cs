using System;
using System.Collections.Generic;
using System.IO;

namespace Inprotech.Setup.Core
{
    internal static class Helpers
    {
        public static bool ArePathsEqual(string path1, string path2)
        {
            if (path1 == path2)
                return true;

            if (path1 == null || path2 == null)
                return false;

            return string.Equals(Path.GetFullPath(path1), Path.GetFullPath(path2), StringComparison.OrdinalIgnoreCase);
        }

        public static string GetInstanceName(string instancePath)
        {
            var fullPath = NormalizePath(instancePath);
            var instanceName = Path.GetFileName(fullPath);

            return instanceName;
        }

        public static string NormalizePath(string rawPath)
        {
            return Path.GetFullPath(rawPath).TrimEnd(Path.DirectorySeparatorChar);
        }

        public static WebAppInfo FindWebApp(IEnumerable<WebAppInfo> items, string iisSite, string iisPath)
        {
            foreach (var item in items)
            {
                if (item.Settings == null)
                    continue;

                if (ArePathsEqual(item.Settings.IisSite, iisSite) &&
                    ArePathsEqual(item.Settings.IisPath, iisPath))
                    return item;
            }

            return null;
        }
    }
}
