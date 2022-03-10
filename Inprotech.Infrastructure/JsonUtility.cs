using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using FormattingJ = Newtonsoft.Json.Formatting;

namespace Inprotech.Infrastructure
{
    public class JsonUtility
    {
        public static Dictionary<string, string> FlattenHierarchy(string json)
        {
            var data = JObject.Parse(json);
            var flat = new Dictionary<string, string>();
            Flatten(null, data, flat);
            return flat;
        }

        public static string NormalizeJsonString(string json, FormattingJ formatting = FormattingJ.None)
        {
            var parsedObject = JObject.Parse(json);

            var normalizedObject = SortPropertiesAlphabetically(parsedObject);

            return JsonConvert.SerializeObject(normalizedObject, formatting);
        }

        static JObject SortPropertiesAlphabetically(JObject original)
        {
            var result = new JObject();

            foreach (var property in original.Properties().ToList().OrderBy(p => p.Name))
            {
                var value = property.Value as JObject;

                if (value != null)
                {
                    value = SortPropertiesAlphabetically(value);
                    result.Add(property.Name, value);
                }
                else
                {
                    result.Add(property.Name, property.Value);
                }
            }

            return result;
        }

        static void Flatten(string prefix, JObject input, Dictionary<string, string> output)
        {
            foreach (var prop in input.Properties())
            {
                if (prop.Value == null || prop.Value.Type == JTokenType.Null) continue;

                var child = prop.Value as JObject;
                if (child != null)
                {
                    Flatten(Prefix(prefix, prop.Name), child, output);
                }
                else
                {
                    output[Prefix(prefix, prop.Name)] = prop.Value.ToString();
                }
            }
        }

        static string Prefix(string prefix, string property)
        {
            if (string.IsNullOrEmpty(prefix)) return property;
            return prefix + "." + property;
        }

        public static string Expand(Dictionary<string, string> translations)
        {
            var translated = JToken.Parse("{}");

            foreach (var translation in translations)
            {
                var val = translation.Value;

                var segments = new Queue<string>(translation.Key.Split('.'));
                var parentNode = translated;
                var currentSeqment = segments.Dequeue();
                var currentNode = translated[currentSeqment];

                while (!string.IsNullOrWhiteSpace(currentSeqment))
                {
                    if (segments.Any())
                    {
                        if (currentNode == null)
                        {
                            parentNode[currentSeqment] = JToken.Parse("{}");
                            currentNode = parentNode[currentSeqment];
                        }

                        currentSeqment = segments.Dequeue();
                        parentNode = currentNode;
                        currentNode = parentNode[currentSeqment];
                        continue;
                    }

                    parentNode[currentSeqment] = val;
                    currentSeqment = null;
                }
            }

            return JsonConvert.SerializeObject(translated, FormattingJ.Indented);
        }
    }
}