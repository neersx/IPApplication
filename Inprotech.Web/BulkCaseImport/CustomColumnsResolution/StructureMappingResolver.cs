using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Ede.DataMapping;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.BulkCaseImport.CustomColumnsResolution
{
    public interface IStructureMappingResolver
    {
        bool Resolve(JToken @case, List<Mapping> rawEdeMappings, int structureId, Action<string, object> setData, out string duplicateMapping);
    }

    public class StructureMappingResolver : IStructureMappingResolver
    {
        public bool Resolve(JToken @case, List<Mapping> rawEdeMappings, int structureId, Action<string, object> setData, out string duplicateMapping)
        {
            duplicateMapping = string.Empty;

            var structureMappings = rawEdeMappings.Where(_ => _.StructureId == structureId && !string.IsNullOrWhiteSpace(_.InputCode)).ToList();
            if (!structureMappings.Any())
                return true;

            var mappedNames = new Dictionary<string, int>();

            if (structureId == KnownMapStructures.NameType)
            {
                structureMappings.Where(_=> !string.IsNullOrWhiteSpace(_.OutputValue)).Select(_ => _.OutputValue).Distinct().ToList().ForEach(m => mappedNames.Add(m, 1));
            }

            foreach (var mapping in structureMappings)
            {
                var inputCode = mapping.InputCode;
                var value = @case.Children().FirstOrDefault(child => ((JProperty) child).Name.Equals(inputCode, StringComparison.InvariantCultureIgnoreCase));

                if (value == null)
                    continue;

                if (rawEdeMappings.Any(_ => _.StructureId != structureId && (_.InputCode == inputCode)))
                {
                    duplicateMapping = inputCode;
                    return false;
                }

                var strValue = (string) value;
                if (inputCode != null && !string.IsNullOrWhiteSpace(strValue))
                {
                    if (structureId == KnownMapStructures.NameType)
                    {
                        var nameDetails = new NameDetails {NameCode = strValue, NameSequence = mappedNames.ContainsKey(mapping.OutputValue) ? mappedNames[mapping.OutputValue]++ : 0};
                        setData(inputCode, nameDetails);
                    }
                    else
                    {
                        setData(inputCode, strValue);
                    }
                }

                value.Remove();

                if (!@case.Children().Any())
                    break;
            }

            return true;
        }
    }
}