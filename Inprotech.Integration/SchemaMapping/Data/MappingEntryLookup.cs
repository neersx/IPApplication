using System.Collections.Generic;
using Newtonsoft.Json;

namespace Inprotech.Integration.SchemaMapping.Data
{
    interface IMappingEntryLookup
    {
        MappingEntry GetMappingInfo(string id);
        DocItem GetDocItem(string id);
        DocItemBinding GetDocItemBinding(string id);
        object GetFixedValue(string id);
    }

    class MappingEntryLookup : IMappingEntryLookup
    {
        readonly IDictionary<string, MappingEntry> _dictionary;

        public MappingEntryLookup(string jsonStr)
        {
            if (string.IsNullOrWhiteSpace(jsonStr))
                return;

            _dictionary = JsonConvert.DeserializeObject<MappingInfo>(jsonStr, new DocItemParameterConverter()).MappingEntries;
        }

        public MappingEntry GetMappingInfo(string id)
        {
            if (_dictionary == null)
                return null;

            if (!_dictionary.ContainsKey(id))
                return null;

            return _dictionary[id];
        }

        public DocItem GetDocItem(string id)
        {
            var mappingInfo = GetMappingInfo(id);

            if (mappingInfo == null)
                return null;

            return mappingInfo.DocItem;
        }

        public DocItemBinding GetDocItemBinding(string id)
        {
            var mappingInfo = GetMappingInfo(id);

            if (mappingInfo == null)
                return null;

            return mappingInfo.DocItemBinding;
        }

        public object GetFixedValue(string id)
        {
            var mappingInfo = GetMappingInfo(id);

            return mappingInfo?.FixedValue;
        }
    }
}