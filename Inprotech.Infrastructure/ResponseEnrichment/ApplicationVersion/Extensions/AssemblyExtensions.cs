using System;
using System.Collections.Concurrent;
using System.IO;
using System.Reflection;

namespace Inprotech.Infrastructure.ResponseEnrichment.ApplicationVersion.Extensions
{
    public static class AssemblyExtensions
    {
        static readonly ConcurrentDictionary<Assembly, string> CachedVersion =
            new ConcurrentDictionary<Assembly, string>();

        static readonly ConcurrentDictionary<Assembly, int> CachedYear =
            new ConcurrentDictionary<Assembly, int>();

        public static string Version(this Assembly assembly, string prefix = "v")
        {
            if (assembly == null) throw new ArgumentNullException(nameof(assembly));

            if (CachedVersion.TryGetValue(assembly, out var version))
            {
                return version;
            }

            var name = assembly.GetName();
            version = $"{prefix}{name.Version.Major}.{name.Version.Minor}.{name.Version.Build}";

            CachedVersion.TryAdd(assembly, version);

            return version;
        }

        public static int ReleaseYear(this Assembly assembly)
        {
            if (assembly == null) throw new ArgumentNullException(nameof(assembly));

            if (CachedYear.TryGetValue(assembly, out var year))
            {
                return year;
            }

            var uri = new UriBuilder(assembly.CodeBase);
            year = new FileInfo(Uri.UnescapeDataString(uri.Path)).CreationTime.Year;

            CachedYear.TryAdd(assembly, year);

            return year;
        }
    }
}