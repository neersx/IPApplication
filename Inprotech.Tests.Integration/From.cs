using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.Reflection;

namespace Inprotech.Tests.Integration
{
    public static class From
    {
        public static string EmbeddedScripts(string path)
        {
            return Embedded(typeof(Program).Namespace + ".Scripts." + path);
        }

        public static string EmbeddedAssets(string path)
        {
            return Embedded(typeof(Program).Namespace + ".Assets." + path);
        }

        [SuppressMessage("Microsoft.Usage", "CA2202:Do not dispose objects multiple times")]
        static string Embedded(string fullpath)
        {
            using (var resourceStream = Assembly.GetAssembly(typeof(Program)).GetManifestResourceStream(fullpath))
            using (var reader = new StreamReader(resourceStream))
            {
                return reader.ReadToEnd();
            }
        }
    }
}