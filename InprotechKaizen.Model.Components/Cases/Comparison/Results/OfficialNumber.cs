using System;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Components.Cases.Comparison.Translations;
using Newtonsoft.Json;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Results
{
    public class OfficialNumber : IEventDescriptionTranslatable
    {
        public int? Id { get; set; }

        public string MappedNumberTypeId { get; set; }

        public string NumberType { get; set; }

        public Value<string> Number { get; set; }

        public short? Cycle { get; set; }

        public string Event { get; set; }

        [SuppressMessage("Microsoft.Design", "CA1006:DoNotNestGenericTypesInMemberSignatures")]
        public Value<DateTime?> EventDate { get; set; }

        public int? EventNo { get; set; }

        [JsonIgnore]
        public int? CriteriaId { get; set; }

        public void SetTranslatedDescription(string translated)
        {
            Event = translated;
        }
    }
}