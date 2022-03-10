using System;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Infrastructure.ResponseEnrichment.Localisation
{
    public interface ILocalisationResources
    {
        Dictionary<string, object> For(IEnumerable<string> applications, IEnumerable<string> cultures);
    }

    public class LocalisationResources : ILocalisationResources
    {
        readonly IResourceLoader _resourceLoader;

        public LocalisationResources(IResourceLoader resourceLoader)
        {
            _resourceLoader = resourceLoader;
        }

        public Dictionary<string, object> For(IEnumerable<string> applications, IEnumerable<string> cultures)
        {
            if(cultures == null) throw new ArgumentNullException(nameof(cultures));

            var preferredCulture = cultures.ToArray();

            var apps = applications.ToArray();

            var allResources = new List<Dictionary<string, object>>();

            allResources.AddRange(apps.Skip(1).Select(component => LoadResources($"resources/{component}/", preferredCulture)));

            allResources.Add(LoadResources($"resources/{apps.First()}/", preferredCulture));

            allResources.Add(LoadResources("client/condor/localisation/translations/translations_", preferredCulture, apps.First()));

            allResources.Add(LoadResources("client/condor/localisation/translations/translations_", new[] {"en"}, apps.First()));

            var finalResources = new Dictionary<string,object>();

            foreach (var resourceSet in allResources)
            {
                foreach (var kv in resourceSet)
                {
                    /* avoid duplicate keys blocks the page */
                    if (!finalResources.ContainsKey(kv.Key))
                        finalResources[kv.Key] = kv.Value;
                }
            }

            return finalResources;
        }

        Dictionary<string, object> LoadResources(string path, IEnumerable<string> preferredCultures, string area = null)
        {
            foreach(var preferredCulture in preferredCultures)
            {
                var resourceFile = path + preferredCulture + ".json";

                if(_resourceLoader.TryLoadResources(resourceFile, out var resources, area))
                    return resources;
            }

            return new Dictionary<string, object>();
        }
    }
}
