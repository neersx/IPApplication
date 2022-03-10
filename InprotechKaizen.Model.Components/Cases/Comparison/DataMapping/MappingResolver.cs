using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Ede.DataMapping;

namespace InprotechKaizen.Model.Components.Cases.Comparison.DataMapping
{
    public interface IMappingResolver
    {
        IEnumerable<MappedValue> Resolve(string sourceSystem, MapScenario mapScenario, IEnumerable<Source> sources);
    }

    public class MappingResolver : IMappingResolver
    {
        public IEnumerable<MappedValue> Resolve(string sourceSystem, MapScenario mapScenario, IEnumerable<Source> sources)
        {
            if (sourceSystem == null) throw new ArgumentNullException(nameof(sourceSystem));

            var mapStructure = mapScenario.MapStructure;

            var rawMappings = mapStructure.Mappings.Where(
                                                          m =>
                                                              m.DataSource != null &&
                                                              m.DataSource.DataSourceCode == sourceSystem)
                                          .ToArray();

            var standardMappings = mapStructure.Mappings.Where(
                                                               m =>
                                                                   m.DataSource == null &&
                                                                   m.MapStructure.Id == mapStructure.Id)
                                               .ToArray();

            var currentScheme = mapScenario.EncodingScheme?.Id ?? KnownEncodingSchemes.CpaInproStandard;

            var encodedValues = mapStructure.EncodedValues.Where(
                                                                 e => e.SchemeId == currentScheme)
                                            .ToArray();

            foreach (var source in sources)
            {
                var dataSourceMapByCode = rawMappings.FirstOrDefault(m => CompareCode(source.Code, m.InputCode));
                var dataSourceMapByDescription = rawMappings.FirstOrDefault(m => CompareDescription(source.Description, m.InputDescription));
                var dataSourceMapDescriptionToCode = rawMappings.FirstOrDefault(m => CompareDescription(source.Code, m.InputDescription));

                if (TryFindApplicableMapping(dataSourceMapByCode ?? dataSourceMapByDescription ?? dataSourceMapDescriptionToCode,
                                             standardMappings, out Mapping potentialRawMap))
                {
                    if (potentialRawMap != null)
                    {
                        yield return new MappedValue(source, potentialRawMap);
                    }
                    continue;
                }

                // fallback to mapping against map scenario's encoding scheme
                var encodedValueByCode = encodedValues.FirstOrDefault(e => CompareCode(source.Code, e.Code));
                var encodedValueByDescription = encodedValues.FirstOrDefault(e => CompareDescription(source.Description, e.Description));
                var encodedValueMapDescriptionToCode = encodedValues.FirstOrDefault(m => CompareDescription(source.Code, m.Description));

                if (encodedValueByCode == null && encodedValueByDescription == null && encodedValueMapDescriptionToCode == null)
                {
                    if (!mapScenario.IgnoreUnmapped)
                    {
                        yield return new FailedMapping(source, mapStructure.Name);
                    }

                    continue;
                }

                var encodedValueId = (encodedValueByCode?.Id ?? encodedValueByDescription?.Id) ?? encodedValueMapDescriptionToCode.Id;

                if (TryFindApplicableMapping(standardMappings.FirstOrDefault(cm => cm.InputCodeId == encodedValueId),
                                             standardMappings, out Mapping potentialEncodedMap))
                {
                    if (potentialEncodedMap != null)
                    {
                        yield return new MappedValue(source, potentialEncodedMap);
                    }
                    continue;
                }

                if (mapScenario.IgnoreUnmapped)
                {
                    continue;
                }

                yield return new FailedMapping(source, mapStructure.Name);
            }
        }

        static bool CompareCode(string sourceCode, string mapCode)
        {
            return !string.IsNullOrEmpty(mapCode) &&
                   string.Equals(mapCode, sourceCode, StringComparison.OrdinalIgnoreCase);
        }

        static bool CompareDescription(string sourceDesc, string mapDesc)
        {
            return !string.IsNullOrEmpty(sourceDesc) &&
                   string.Equals(sourceDesc, mapDesc, StringComparison.InvariantCultureIgnoreCase);
        }

        static bool TryFindApplicableMapping(Mapping map, IEnumerable<Mapping> standardMappings, out Mapping mapping)
        {
            mapping = null;

            if (map == null)
            {
                return false;
            }

            if (map.IsNotApplicable)
            {
                return true;
            }

            if (!string.IsNullOrEmpty(map.OutputValue))
            {
                mapping = map;
                return true;
            }

            if (map.OutputCodeId == null)
            {
                return false;
            }

            var commonMap = standardMappings.FirstOrDefault(m =>
                                                       m.InputCodeId == map.OutputCodeId);
            if(commonMap == null)
            {
                return false;
            }

            if (commonMap.IsNotApplicable)
            {
                return true;
            }

            if (!string.IsNullOrEmpty(commonMap.OutputValue))
            {
                mapping = commonMap;
                return true;
            }

            return false;
        }
    }
}