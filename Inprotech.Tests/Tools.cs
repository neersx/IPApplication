using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.Reflection;

namespace Inprotech.Tests
{
    public class Tools
    {
        [SuppressMessage("Microsoft.Usage", "CA2202:Do not dispose objects multiple times")]
        public static string ReadFromEmbededResource(string path)
        {
            using (var resourceStream = Assembly.GetAssembly(typeof(Tools)).GetManifestResourceStream(path))
            using (var reader = new StreamReader(resourceStream))
            {
                return reader.ReadToEnd();
            }
        }
    }
}