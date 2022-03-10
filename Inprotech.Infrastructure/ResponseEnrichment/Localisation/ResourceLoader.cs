using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json.Linq;

namespace Inprotech.Infrastructure.ResponseEnrichment.Localisation
{
    public interface IResourceLoader
    {
        bool TryLoadResources(string path, out Dictionary<string, object> resources, string area = null);
    }

    public class ResourceLoader : IResourceLoader
    {
        public bool TryLoadResources(string path, out Dictionary<string, object> resources, string area = null)
        {
            resources = null;
            if (!File.Exists(path)) return false;
            if (string.IsNullOrEmpty(area))
            {
                resources = JObject
                            .Parse(File.ReadAllText(path))
                            .ToObject<Dictionary<string, object>>();
            }
            else
            {
                var jObject = JObject
                    .Parse(File.ReadAllText(path));
                resources = jObject[area] == null ? null : jObject[area].ToObject<Dictionary<string, object>>();
            }

            return resources != null;
        }
    }
}