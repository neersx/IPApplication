using System.Collections.Generic;
using System.IO;
using System.Linq;
using Newtonsoft.Json;

namespace Inprotech.Web.Translation
{
    public class TranslatableItem
    {
        public string Id
        {
            get { return Source + "-" + ResourceKey; }
        }

        public string AreaKey
        {
            get { return "screenlabels.area." + (Area ?? "common"); }
        }

        public string Area { get; set; }

        [JsonIgnore]
        public string Source { get; set; }

        [JsonProperty("Key")]
        public string ResourceKey { get; set; }

        [JsonProperty("Original")]
        public string Default { get; set; }

        [JsonProperty("Translation")]
        public string Translated { get; set; }
    }

    public static class TranslatableItemExtensions
    {
        public static IEnumerable<string> UniqueSourceKeys(this IEnumerable<TranslatableItem> source)
        {
            return source.Select(_ => _.Source).Distinct();
        }

        public static string ClassicAppSourceKey(this string filePath, string basePath)
        {
            var source = filePath
                .Replace(basePath, string.Empty)
                .Replace(Path.GetFileName(filePath), string.Empty)
                .Trim(Path.DirectorySeparatorChar)
                .Replace(Path.DirectorySeparatorChar, '-');

            return "classic-" + source;
        }
        
        public static string CondorAppSourceKey(this string resourceKey)
        {
            var hierachy = resourceKey.Split('.');
            if (hierachy.Length > 1)
                return "condor-" + hierachy[0];

            return "condor-global";
        }
    }
}