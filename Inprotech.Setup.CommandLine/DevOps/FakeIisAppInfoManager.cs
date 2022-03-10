using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using Inprotech.Setup.Core;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;

namespace Inprotech.Setup.CommandLine.DevOps
{
    internal class FakeIisAppInfoManager : IIisAppInfoManager
    {
        readonly IFileSystem _fileSystem;
        readonly string _profilePath;

        IEnumerable<IisAppInfo> Load()
        {
            var content = _fileSystem.ReadAllText(_profilePath);

            return JsonConvert.DeserializeObject<IEnumerable<IisAppInfo>>(content, new JsonSerializerSettings
            {
                ContractResolver = new IisAppInfoContractResolver(),
                Converters = new List<JsonConverter>{ new VersionConverter() }
            });
        }

        public FakeIisAppInfoManager(string profilePath, IFileSystem fileSystem)
        {
            _profilePath = profilePath;
            _fileSystem = fileSystem;
        }

        public IEnumerable<IisAppInfo> FindAll()
        {
            return Find();
        }

        public IisAppInfo Find(string site, string path)
        {
            var result = (from i in Find()
                          where string.Equals(i.Site, site, StringComparison.OrdinalIgnoreCase) &&
                                string.Equals(i.VirtualPath, path, StringComparison.OrdinalIgnoreCase)
                          select i)
                .SingleOrDefault();

            if (result == null)
            {
                throw new Exception("Iis Application not found: " + site + path);
            }

            return result;
        }

        IEnumerable<IisAppInfo> Find()
        {
            return Load();
        }

        class IisAppInfoContractResolver : DefaultContractResolver
        {
            protected override IList<JsonProperty> CreateProperties(Type type, MemberSerialization memberSerialization)
            {
                var props = type.GetProperties(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance)
                                .Select(p => base.CreateProperty(p, memberSerialization))
                                .Union(type.GetFields(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance)
                                           .Select(f => base.CreateProperty(f, memberSerialization)))
                                .ToList();
                props.ForEach(p => { p.Writable = true; p.Readable = true; });
                return props;
            }
        }

        class VersionConverter : JsonConverter
        {
            public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
            {
                // default serialization
                serializer.Serialize(writer, value);
            }

            public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer)
            {
                // create a new Version instance and pass the properties to the constructor
                // (you may also use dynamics if you like)
                var dict = serializer.Deserialize<Dictionary<string, int>>(reader);
                return new Version(dict["Major"], dict["Minor"], dict["Build"], dict["Revision"]);
            }

            public override bool CanConvert(Type objectType)
            {
                return objectType == typeof(Version);
            }
        }
    }
}