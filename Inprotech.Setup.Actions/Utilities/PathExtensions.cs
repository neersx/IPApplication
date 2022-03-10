using System;
using System.IO;

namespace Inprotech.Setup.Actions.Utilities
{
    public static class PathExtensions
    {
        public static string AsHttpSysCompatiblePath(this string input)
        {
            input = input.Replace('\\', '/');
            if (!input.StartsWith("/"))
            {
                input = "/" + input;
            }

            if (!input.EndsWith("/"))
            {
                input = input + "/";
            }

            return input;
        }

        public static string AsAppSettingsCompatiblePath(this string input)
        {
            return input.TrimStart('/').TrimEnd('\\');
        }

        public static string NormalisePath(string path)
        {
            return Path.GetFullPath(new Uri(path).LocalPath)
                .TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
        }
    }
}